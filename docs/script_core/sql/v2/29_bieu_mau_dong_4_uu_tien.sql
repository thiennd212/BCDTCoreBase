-- =====================================================================
-- v29: Hoàn thiện biểu mẫu động – 4 ưu tiên
-- Ngày: 2026-02-26
-- =====================================================================

-- =====================================================================
-- Mục 1: LayoutOrder cho FormColumn và FormPlaceholderColumnOccurrence
-- =====================================================================

-- ExcelColumn → nullable (backward compat: data cũ vẫn giữ giá trị, null = tính runtime)
ALTER TABLE BCDT_FormColumn ALTER COLUMN ExcelColumn NVARCHAR(10) NULL;

-- LayoutOrder: thứ tự trong layout tổng của sheet (dùng chung namespace với PlaceholderOccurrence)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='BCDT_FormColumn' AND COLUMN_NAME='LayoutOrder')
BEGIN
    ALTER TABLE BCDT_FormColumn ADD LayoutOrder INT NOT NULL DEFAULT 0;
    EXEC('UPDATE BCDT_FormColumn SET LayoutOrder = DisplayOrder');
END

-- LayoutOrder cho placeholder cột (interleave với FormColumn theo LayoutOrder)
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='BCDT_FormPlaceholderColumnOccurrence' AND COLUMN_NAME='LayoutOrder')
BEGIN
    ALTER TABLE BCDT_FormPlaceholderColumnOccurrence ADD LayoutOrder INT NOT NULL DEFAULT 0;
    EXEC('UPDATE BCDT_FormPlaceholderColumnOccurrence SET LayoutOrder = DisplayOrder');
END

-- =====================================================================
-- Mục 2: FormRow – IsEditable, IsRequired, Formula
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='BCDT_FormRow' AND COLUMN_NAME='IsEditable')
    ALTER TABLE BCDT_FormRow ADD IsEditable BIT NOT NULL DEFAULT 1;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='BCDT_FormRow' AND COLUMN_NAME='IsRequired')
    ALTER TABLE BCDT_FormRow ADD IsRequired BIT NOT NULL DEFAULT 0;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='BCDT_FormRow' AND COLUMN_NAME='Formula')
    ALTER TABLE BCDT_FormRow ADD Formula NVARCHAR(1000) NULL;

-- =====================================================================
-- Mục 3: FormRowFormulaScope – chọn cột áp dụng cho row formula
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='BCDT_FormRowFormulaScope')
CREATE TABLE BCDT_FormRowFormulaScope (
    Id INT IDENTITY(1,1) NOT NULL,
    FormRowId INT NOT NULL,
    FormColumnId INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy INT NOT NULL,
    CONSTRAINT PK_FormRowFormulaScope PRIMARY KEY (Id),
    CONSTRAINT FK_FormRowFormulaScope_Row FOREIGN KEY (FormRowId)
        REFERENCES BCDT_FormRow(Id) ON DELETE CASCADE,
    CONSTRAINT FK_FormRowFormulaScope_Col FOREIGN KEY (FormColumnId)
        REFERENCES BCDT_FormColumn(Id) ON DELETE CASCADE,
    CONSTRAINT UQ_FormRowFormulaScope UNIQUE (FormRowId, FormColumnId)
);

-- =====================================================================
-- Mục 4: FormCellFormula – override formula/IsEditable cấp CELL
-- =====================================================================

IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.TABLES WHERE TABLE_NAME='BCDT_FormCellFormula')
CREATE TABLE BCDT_FormCellFormula (
    Id INT IDENTITY(1,1) NOT NULL,
    FormSheetId INT NOT NULL,
    FormColumnId INT NOT NULL,
    FormRowId INT NOT NULL,
    Formula NVARCHAR(1000) NULL,
    IsEditable BIT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy INT NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT PK_FormCellFormula PRIMARY KEY (Id),
    CONSTRAINT FK_FormCellFormula_Sheet FOREIGN KEY (FormSheetId)
        REFERENCES BCDT_FormSheet(Id) ON DELETE CASCADE,
    CONSTRAINT FK_FormCellFormula_Col FOREIGN KEY (FormColumnId)
        REFERENCES BCDT_FormColumn(Id),
    CONSTRAINT FK_FormCellFormula_Row FOREIGN KEY (FormRowId)
        REFERENCES BCDT_FormRow(Id),
    CONSTRAINT UQ_FormCellFormula UNIQUE (FormColumnId, FormRowId)
);

-- Indexes
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_FormRowFormulaScope_RowId')
    CREATE INDEX IX_FormRowFormulaScope_RowId ON BCDT_FormRowFormulaScope(FormRowId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_FormCellFormula_SheetId')
    CREATE INDEX IX_FormCellFormula_SheetId ON BCDT_FormCellFormula(FormSheetId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_FormCellFormula_ColumnId')
    CREATE INDEX IX_FormCellFormula_ColumnId ON BCDT_FormCellFormula(FormColumnId);
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name='IX_FormCellFormula_RowId')
    CREATE INDEX IX_FormCellFormula_RowId ON BCDT_FormCellFormula(FormRowId);
