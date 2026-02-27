-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Form Definition (Định nghĩa biểu mẫu)
-- Version: 2.0
-- Tables: 8
-- ============================================================

-- ============================================================
-- 1. BCDT_FormDefinition - Biểu mẫu
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormDefinition](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(1000) NULL,
    [FormType] NVARCHAR(20) NOT NULL,        -- Input, Aggregate
    [CurrentVersion] INT NOT NULL DEFAULT 1,
    
    -- Reporting Period
    [ReportingFrequencyId] INT NULL,
    [DeadlineOffsetDays] INT NOT NULL DEFAULT 5,  -- Days after period end
    [AllowLateSubmission] BIT NOT NULL DEFAULT 1,
    
    -- Workflow
    [RequireApproval] BIT NOT NULL DEFAULT 1,
    [AutoCreateReport] BIT NOT NULL DEFAULT 0,
    
    -- Template
    [TemplateFile] VARBINARY(MAX) NULL,      -- Excel template file
    [TemplateFileName] NVARCHAR(255) NULL,
    
    -- Status
    [Status] NVARCHAR(20) NOT NULL DEFAULT 'Draft',  -- Draft, Published, Archived
    [PublishedAt] DATETIME2 NULL,
    [PublishedBy] INT NULL,
    
    -- Audit
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    [IsDeleted] BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT [PK_BCDT_FormDefinition] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_FormDefinition_Code] UNIQUE NONCLUSTERED ([Code] ASC),
    CONSTRAINT [CK_FormDefinition_Type] CHECK ([FormType] IN ('Input', 'Aggregate')),
    CONSTRAINT [CK_FormDefinition_Status] CHECK ([Status] IN ('Draft', 'Published', 'Archived'))
) ON [PRIMARY];
GO

-- ============================================================
-- 2. BCDT_FormVersion - Phiên bản biểu mẫu
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormVersion](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FormDefinitionId] INT NOT NULL,
    [VersionNumber] INT NOT NULL,
    [VersionName] NVARCHAR(100) NULL,
    [ChangeDescription] NVARCHAR(1000) NULL,
    [TemplateFile] VARBINARY(MAX) NULL,
    [TemplateFileName] NVARCHAR(255) NULL,
    [StructureJson] NVARCHAR(MAX) NULL,      -- JSON snapshot of form structure
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_FormVersion] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_FormVersion_Form] FOREIGN KEY ([FormDefinitionId]) REFERENCES [dbo].[BCDT_FormDefinition]([Id]),
    CONSTRAINT [UQ_FormVersion] UNIQUE NONCLUSTERED ([FormDefinitionId], [VersionNumber])
) ON [PRIMARY];
GO

-- ============================================================
-- 3. BCDT_FormSheet - Sheets trong workbook
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormSheet](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FormDefinitionId] INT NOT NULL,
    [SheetIndex] TINYINT NOT NULL,           -- 0-based index
    [SheetName] NVARCHAR(100) NOT NULL,
    [DisplayName] NVARCHAR(200) NULL,
    [Description] NVARCHAR(500) NULL,
    [IsDataSheet] BIT NOT NULL DEFAULT 1,    -- Contains data to save
    [IsVisible] BIT NOT NULL DEFAULT 1,
    [DisplayOrder] INT NOT NULL DEFAULT 0,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_FormSheet] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_FormSheet_Form] FOREIGN KEY ([FormDefinitionId]) REFERENCES [dbo].[BCDT_FormDefinition]([Id]),
    CONSTRAINT [UQ_FormSheet] UNIQUE NONCLUSTERED ([FormDefinitionId], [SheetIndex])
) ON [PRIMARY];
GO

-- ============================================================
-- 4. BCDT_FormColumn - Cột / Tiêu chí
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormColumn](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FormSheetId] INT NOT NULL,
    [ColumnCode] NVARCHAR(50) NOT NULL,
    [ColumnName] NVARCHAR(200) NOT NULL,
    [ExcelColumn] NVARCHAR(10) NOT NULL,     -- A, B, C, AA, etc.
    [DataType] NVARCHAR(20) NOT NULL,        -- Text, Number, Date, Formula, Reference
    [IsRequired] BIT NOT NULL DEFAULT 0,
    [IsEditable] BIT NOT NULL DEFAULT 1,     -- Can user edit this column
    [IsHidden] BIT NOT NULL DEFAULT 0,
    [DefaultValue] NVARCHAR(500) NULL,
    [Formula] NVARCHAR(1000) NULL,           -- Excel formula
    [ValidationRule] NVARCHAR(500) NULL,     -- Validation expression
    [ValidationMessage] NVARCHAR(500) NULL,
    [DisplayOrder] INT NOT NULL DEFAULT 0,
    [Width] INT NULL,                        -- Column width
    [Format] NVARCHAR(100) NULL,             -- Number/date format
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_FormColumn] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_FormColumn_Sheet] FOREIGN KEY ([FormSheetId]) REFERENCES [dbo].[BCDT_FormSheet]([Id]),
    CONSTRAINT [CK_FormColumn_DataType] CHECK ([DataType] IN ('Text', 'Number', 'Date', 'Formula', 'Reference', 'Boolean'))
) ON [PRIMARY];
GO

CREATE INDEX [IX_FormColumn_Sheet] ON [dbo].[BCDT_FormColumn]([FormSheetId]);
GO

-- ============================================================
-- 5. BCDT_FormRow - Hàng động
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormRow](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FormSheetId] INT NOT NULL,
    [RowCode] NVARCHAR(50) NULL,
    [RowName] NVARCHAR(200) NULL,
    [ExcelRowStart] INT NOT NULL,            -- Starting row number
    [ExcelRowEnd] INT NULL,                  -- Ending row (NULL = single row)
    [RowType] NVARCHAR(20) NOT NULL,         -- Header, Data, Total, Static
    [IsRepeating] BIT NOT NULL DEFAULT 0,    -- Can add multiple instances
    [ReferenceEntityTypeId] INT NULL,        -- For repeating rows bound to entity
    [ParentRowId] INT NULL,                  -- For hierarchical rows
    [DisplayOrder] INT NOT NULL DEFAULT 0,
    [Height] INT NULL,                       -- Row height
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_FormRow] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_FormRow_Sheet] FOREIGN KEY ([FormSheetId]) REFERENCES [dbo].[BCDT_FormSheet]([Id]),
    CONSTRAINT [FK_FormRow_Parent] FOREIGN KEY ([ParentRowId]) REFERENCES [dbo].[BCDT_FormRow]([Id]),
    CONSTRAINT [CK_FormRow_Type] CHECK ([RowType] IN ('Header', 'Data', 'Total', 'Static'))
) ON [PRIMARY];
GO

-- ============================================================
-- 6. BCDT_FormCell - Cell configuration
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormCell](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FormSheetId] INT NOT NULL,
    [CellAddress] NVARCHAR(20) NOT NULL,     -- A1, B5, etc.
    [FormColumnId] INT NULL,
    [FormRowId] INT NULL,
    [IsLocked] BIT NOT NULL DEFAULT 1,       -- Cell protection
    [IsEditable] BIT NOT NULL DEFAULT 0,
    [IsMerged] BIT NOT NULL DEFAULT 0,
    [MergeRange] NVARCHAR(20) NULL,          -- A1:C3
    [BackgroundColor] NVARCHAR(20) NULL,
    [FontColor] NVARCHAR(20) NULL,
    [FontBold] BIT NOT NULL DEFAULT 0,
    [BorderStyle] NVARCHAR(50) NULL,
    [HorizontalAlign] NVARCHAR(20) NULL,     -- Left, Center, Right
    [VerticalAlign] NVARCHAR(20) NULL,       -- Top, Middle, Bottom
    [Comment] NVARCHAR(500) NULL,            -- Cell comment/note
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_BCDT_FormCell] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_FormCell_Sheet] FOREIGN KEY ([FormSheetId]) REFERENCES [dbo].[BCDT_FormSheet]([Id]),
    CONSTRAINT [FK_FormCell_Column] FOREIGN KEY ([FormColumnId]) REFERENCES [dbo].[BCDT_FormColumn]([Id]),
    CONSTRAINT [FK_FormCell_Row] FOREIGN KEY ([FormRowId]) REFERENCES [dbo].[BCDT_FormRow]([Id]),
    CONSTRAINT [UQ_FormCell] UNIQUE NONCLUSTERED ([FormSheetId], [CellAddress])
) ON [PRIMARY];
GO

-- ============================================================
-- 7. BCDT_FormDataBinding - Data binding configuration
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormDataBinding](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FormColumnId] INT NOT NULL,
    [BindingType] NVARCHAR(30) NOT NULL,     -- Static, Database, API, Formula, Reference, Organization, System
    [SourceTable] NVARCHAR(100) NULL,
    [SourceColumn] NVARCHAR(100) NULL,
    [SourceCondition] NVARCHAR(500) NULL,    -- WHERE clause
    [ApiEndpoint] NVARCHAR(500) NULL,
    [ApiMethod] NVARCHAR(10) NULL,
    [ApiResponsePath] NVARCHAR(200) NULL,    -- JSON path
    [Formula] NVARCHAR(1000) NULL,
    [ReferenceEntityTypeId] INT NULL,
    [ReferenceDisplayColumn] NVARCHAR(100) NULL,
    [DefaultValue] NVARCHAR(500) NULL,
    [TransformExpression] NVARCHAR(500) NULL,  -- Transform data after loading
    [CacheMinutes] INT NOT NULL DEFAULT 0,     -- 0 = no cache
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_FormDataBinding] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_DataBinding_Column] FOREIGN KEY ([FormColumnId]) REFERENCES [dbo].[BCDT_FormColumn]([Id]),
    CONSTRAINT [CK_DataBinding_Type] CHECK ([BindingType] IN ('Static', 'Database', 'API', 'Formula', 'Reference', 'Organization', 'System'))
) ON [PRIMARY];
GO

-- ============================================================
-- 8. BCDT_FormColumnMapping - Mapping Excel columns to DB columns
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormColumnMapping](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FormColumnId] INT NOT NULL,
    [TargetColumnName] NVARCHAR(50) NOT NULL,   -- NumericValue1, TextValue1, etc.
    [TargetColumnIndex] TINYINT NOT NULL,       -- Index in target table
    [AggregateFunction] NVARCHAR(20) NULL,      -- SUM, AVG, COUNT, MIN, MAX (for summary)
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_BCDT_FormColumnMapping] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ColumnMapping_Column] FOREIGN KEY ([FormColumnId]) REFERENCES [dbo].[BCDT_FormColumn]([Id]),
    CONSTRAINT [UQ_ColumnMapping] UNIQUE NONCLUSTERED ([FormColumnId])
) ON [PRIMARY];
GO

PRINT N'04.form_definition.sql - 8 tables created successfully';
GO
