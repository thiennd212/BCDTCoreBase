-- ============================================================
-- BCDT - Cấu trúc biểu mẫu: Chỉ tiêu cố định & Chỉ tiêu động (R1–R11)
-- Tham chiếu: GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md
-- Phụ thuộc: 01–05 (Organization, Auth, Form, Data Storage)
-- ============================================================

-- ============================================================
-- 1. BCDT_IndicatorCatalog - Danh mục chỉ tiêu động (R8, R9)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_IndicatorCatalog')
BEGIN
    CREATE TABLE [dbo].[BCDT_IndicatorCatalog](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Code] NVARCHAR(50) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [Scope] NVARCHAR(20) NOT NULL DEFAULT 'Global',
        [DisplayOrder] INT NOT NULL DEFAULT 0,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_IndicatorCatalog] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_IndicatorCatalog_Code] UNIQUE NONCLUSTERED ([Code] ASC),
        CONSTRAINT [CK_IndicatorCatalog_Scope] CHECK ([Scope] IN ('Global', 'PerOrganization'))
    ) ON [PRIMARY];
    PRINT N'BCDT_IndicatorCatalog created';
END
GO

-- ============================================================
-- 2. BCDT_Indicator - Chỉ tiêu master (cố định + động, R6, R10)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_Indicator')
BEGIN
    CREATE TABLE [dbo].[BCDT_Indicator](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [IndicatorCatalogId] INT NULL,
        [ParentId] INT NULL,
        [Code] NVARCHAR(50) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [DataType] NVARCHAR(20) NOT NULL,
        [Unit] NVARCHAR(50) NULL,
        [FormulaTemplate] NVARCHAR(1000) NULL,
        [ValidationRule] NVARCHAR(500) NULL,
        [DefaultValue] NVARCHAR(500) NULL,
        [DisplayOrder] INT NOT NULL DEFAULT 0,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_Indicator] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_Indicator_Catalog] FOREIGN KEY ([IndicatorCatalogId]) REFERENCES [dbo].[BCDT_IndicatorCatalog]([Id]),
        CONSTRAINT [FK_Indicator_Parent] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[BCDT_Indicator]([Id]),
        CONSTRAINT [CK_Indicator_DataType] CHECK ([DataType] IN ('Text', 'Number', 'Date', 'Formula', 'Reference', 'Boolean'))
    ) ON [PRIMARY];

    -- Mã unique trong từng catalog: (IndicatorCatalogId, Code) khi có catalog
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Indicator_Catalog_Code]
        ON [dbo].[BCDT_Indicator]([IndicatorCatalogId], [Code])
        WHERE [IndicatorCatalogId] IS NOT NULL;

    -- Chỉ tiêu không thuộc catalog (cố định): Code unique toàn cục
    CREATE UNIQUE NONCLUSTERED INDEX [UQ_Indicator_Code_Global]
        ON [dbo].[BCDT_Indicator]([Code])
        WHERE [IndicatorCatalogId] IS NULL;

    CREATE INDEX [IX_Indicator_Catalog] ON [dbo].[BCDT_Indicator]([IndicatorCatalogId]);
    CREATE INDEX [IX_Indicator_Parent] ON [dbo].[BCDT_Indicator]([ParentId], [DisplayOrder]);
    PRINT N'BCDT_Indicator created';
END
GO

-- ============================================================
-- 3. BCDT_FormDynamicRegion - Vùng placeholder chỉ tiêu động (R4, R11)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_FormDynamicRegion')
BEGIN
    CREATE TABLE [dbo].[BCDT_FormDynamicRegion](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [FormSheetId] INT NOT NULL,
        [ExcelRowStart] INT NOT NULL,
        [ExcelRowEnd] INT NULL,
        [ExcelColName] NVARCHAR(10) NOT NULL,
        [ExcelColValue] NVARCHAR(10) NOT NULL,
        [MaxRows] INT NOT NULL DEFAULT 100,
        [IndicatorExpandDepth] INT NOT NULL DEFAULT 1,
        [IndicatorCatalogId] INT NULL,
        [DisplayOrder] INT NOT NULL DEFAULT 0,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        CONSTRAINT [PK_BCDT_FormDynamicRegion] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_FormDynamicRegion_Sheet] FOREIGN KEY ([FormSheetId]) REFERENCES [dbo].[BCDT_FormSheet]([Id]),
        CONSTRAINT [FK_FormDynamicRegion_Catalog] FOREIGN KEY ([IndicatorCatalogId]) REFERENCES [dbo].[BCDT_IndicatorCatalog]([Id])
    ) ON [PRIMARY];
    CREATE INDEX [IX_FormDynamicRegion_Sheet] ON [dbo].[BCDT_FormDynamicRegion]([FormSheetId]);
    PRINT N'BCDT_FormDynamicRegion created';
END
GO

-- ============================================================
-- 4. BCDT_ReportDynamicIndicator - Chỉ tiêu động theo submission (R4, R8)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_ReportDynamicIndicator')
BEGIN
    CREATE TABLE [dbo].[BCDT_ReportDynamicIndicator](
        [Id] BIGINT IDENTITY(1,1) NOT NULL,
        [SubmissionId] BIGINT NOT NULL,
        [FormDynamicRegionId] INT NOT NULL,
        [RowOrder] INT NOT NULL,
        [IndicatorId] INT NULL,
        [IndicatorName] NVARCHAR(500) NOT NULL,
        [IndicatorValue] NVARCHAR(MAX) NULL,
        [DataType] NVARCHAR(20) NULL,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_ReportDynamicIndicator] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_ReportDynamicIndicator_Submission] FOREIGN KEY ([SubmissionId]) REFERENCES [dbo].[BCDT_ReportSubmission]([Id]),
        CONSTRAINT [FK_ReportDynamicIndicator_Region] FOREIGN KEY ([FormDynamicRegionId]) REFERENCES [dbo].[BCDT_FormDynamicRegion]([Id]),
        CONSTRAINT [FK_ReportDynamicIndicator_Indicator] FOREIGN KEY ([IndicatorId]) REFERENCES [dbo].[BCDT_Indicator]([Id]),
        CONSTRAINT [UQ_ReportDynamicIndicator_Submission_Region_Order] UNIQUE NONCLUSTERED ([SubmissionId], [FormDynamicRegionId], [RowOrder])
    ) ON [PRIMARY];
    CREATE INDEX [IX_ReportDynamicIndicator_Submission_Region] ON [dbo].[BCDT_ReportDynamicIndicator]([SubmissionId], [FormDynamicRegionId]);
    PRINT N'BCDT_ReportDynamicIndicator created';
END
GO

-- ============================================================
-- 5. ALTER BCDT_FormColumn - ParentId (phân cấp cột), IndicatorId (tái sử dụng chỉ tiêu)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.BCDT_FormColumn') AND name = 'ParentId')
BEGIN
    ALTER TABLE [dbo].[BCDT_FormColumn]
        ADD [ParentId] INT NULL;
    ALTER TABLE [dbo].[BCDT_FormColumn]
        ADD CONSTRAINT [FK_FormColumn_Parent] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[BCDT_FormColumn]([Id]);
    CREATE INDEX [IX_FormColumn_Parent] ON [dbo].[BCDT_FormColumn]([ParentId]);
    PRINT N'BCDT_FormColumn.ParentId added';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.BCDT_FormColumn') AND name = 'IndicatorId')
BEGIN
    ALTER TABLE [dbo].[BCDT_FormColumn]
        ADD [IndicatorId] INT NULL;
    ALTER TABLE [dbo].[BCDT_FormColumn]
        ADD CONSTRAINT [FK_FormColumn_Indicator] FOREIGN KEY ([IndicatorId]) REFERENCES [dbo].[BCDT_Indicator]([Id]);
    CREATE INDEX [IX_FormColumn_Indicator] ON [dbo].[BCDT_FormColumn]([IndicatorId]);
    PRINT N'BCDT_FormColumn.IndicatorId added';
END
GO

-- ============================================================
-- 6. ALTER BCDT_FormRow - FormDynamicRegionId (hàng thuộc vùng placeholder)
-- FormRow đã có ParentRowId (phân cấp hàng); không thêm ParentId trùng.
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.BCDT_FormRow') AND name = 'FormDynamicRegionId')
BEGIN
    ALTER TABLE [dbo].[BCDT_FormRow]
        ADD [FormDynamicRegionId] INT NULL;
    ALTER TABLE [dbo].[BCDT_FormRow]
        ADD CONSTRAINT [FK_FormRow_FormDynamicRegion] FOREIGN KEY ([FormDynamicRegionId]) REFERENCES [dbo].[BCDT_FormDynamicRegion]([Id]);
    CREATE INDEX [IX_FormRow_FormDynamicRegion] ON [dbo].[BCDT_FormRow]([FormDynamicRegionId]);
    PRINT N'BCDT_FormRow.FormDynamicRegionId added';
END
GO

-- R11 phân cấp hàng: BCDT_FormRow đã có ParentRowId (self-FK), dùng làm ParentId trong API/ứng dụng.

-- ============================================================
-- 7. Index cho tree list (FormSheetId, Parent*, DisplayOrder) – P2a
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.BCDT_FormColumn') AND name = 'IX_FormColumn_Sheet_Parent_DisplayOrder')
BEGIN
    CREATE INDEX [IX_FormColumn_Sheet_Parent_DisplayOrder]
        ON [dbo].[BCDT_FormColumn]([FormSheetId], [ParentId], [DisplayOrder]);
    PRINT N'IX_FormColumn_Sheet_Parent_DisplayOrder created';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.BCDT_FormRow') AND name = 'IX_FormRow_Sheet_Parent_DisplayOrder')
BEGIN
    CREATE INDEX [IX_FormRow_Sheet_Parent_DisplayOrder]
        ON [dbo].[BCDT_FormRow]([FormSheetId], [ParentRowId], [DisplayOrder]);
    PRINT N'IX_FormRow_Sheet_Parent_DisplayOrder created';
END
GO

PRINT N'20.chi_tieu_co_dinh_dong.sql completed.';
GO
