-- ============================================================
-- P8a – Lọc động theo trường: DataSource, FilterDefinition, FilterCondition, FormPlaceholderOccurrence
-- Tham chiếu: GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md
-- Phụ thuộc: 01–05, 20 (Organization, Form, BCDT_FormDynamicRegion)
-- ============================================================

-- ============================================================
-- 1. BCDT_DataSource - Nguồn dữ liệu (Table, View, Catalog, API)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_DataSource')
BEGIN
    CREATE TABLE [dbo].[BCDT_DataSource](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Code] NVARCHAR(50) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [SourceType] NVARCHAR(20) NOT NULL,
        [SourceRef] NVARCHAR(500) NULL,
        [IndicatorCatalogId] INT NULL,
        [DisplayColumn] NVARCHAR(100) NULL,
        [ValueColumn] NVARCHAR(100) NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_DataSource] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_DataSource_Code] UNIQUE NONCLUSTERED ([Code] ASC),
        CONSTRAINT [FK_DataSource_Catalog] FOREIGN KEY ([IndicatorCatalogId]) REFERENCES [dbo].[BCDT_IndicatorCatalog]([Id]),
        CONSTRAINT [CK_DataSource_SourceType] CHECK ([SourceType] IN ('Catalog', 'Table', 'View', 'API'))
    ) ON [PRIMARY];
    PRINT N'BCDT_DataSource created';
END
GO

-- ============================================================
-- 2. BCDT_FilterDefinition - Định nghĩa bộ lọc (AND/OR + conditions)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_FilterDefinition')
BEGIN
    CREATE TABLE [dbo].[BCDT_FilterDefinition](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Code] NVARCHAR(50) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [LogicalOperator] NVARCHAR(3) NOT NULL,
        [DataSourceId] INT NULL,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_FilterDefinition] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_FilterDefinition_Code] UNIQUE NONCLUSTERED ([Code] ASC),
        CONSTRAINT [FK_FilterDefinition_DataSource] FOREIGN KEY ([DataSourceId]) REFERENCES [dbo].[BCDT_DataSource]([Id]),
        CONSTRAINT [CK_FilterDefinition_LogicalOperator] CHECK ([LogicalOperator] IN ('AND', 'OR'))
    ) ON [PRIMARY];
    CREATE INDEX [IX_FilterDefinition_DataSource] ON [dbo].[BCDT_FilterDefinition]([DataSourceId]);
    PRINT N'BCDT_FilterDefinition created';
END
GO

-- ============================================================
-- 3. BCDT_FilterCondition - Điều kiện con (Field, Operator, ValueType, Value)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_FilterCondition')
BEGIN
    CREATE TABLE [dbo].[BCDT_FilterCondition](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [FilterDefinitionId] INT NOT NULL,
        [ConditionOrder] INT NOT NULL,
        [Field] NVARCHAR(100) NOT NULL,
        [Operator] NVARCHAR(20) NOT NULL,
        [ValueType] NVARCHAR(20) NOT NULL,
        [Value] NVARCHAR(500) NULL,
        [Value2] NVARCHAR(500) NULL,
        [DataType] NVARCHAR(20) NULL,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        CONSTRAINT [PK_BCDT_FilterCondition] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_FilterCondition_Definition] FOREIGN KEY ([FilterDefinitionId]) REFERENCES [dbo].[BCDT_FilterDefinition]([Id]) ON DELETE CASCADE,
        CONSTRAINT [CK_FilterCondition_ValueType] CHECK ([ValueType] IN ('Literal', 'Parameter')),
        CONSTRAINT [CK_FilterCondition_DataType] CHECK ([DataType] IS NULL OR [DataType] IN ('Text', 'Number', 'Date', 'Boolean'))
    ) ON [PRIMARY];
    CREATE INDEX [IX_FilterCondition_FilterDefinitionId] ON [dbo].[BCDT_FilterCondition]([FilterDefinitionId]);
    PRINT N'BCDT_FilterCondition created';
END
GO

-- ============================================================
-- 4. BCDT_FormPlaceholderOccurrence - Vị trí placeholder dòng (một dòng = một occurrence)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_FormPlaceholderOccurrence')
BEGIN
    CREATE TABLE [dbo].[BCDT_FormPlaceholderOccurrence](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [FormSheetId] INT NOT NULL,
        [FormDynamicRegionId] INT NOT NULL,
        [ExcelRowStart] INT NOT NULL,
        [FilterDefinitionId] INT NULL,
        [DataSourceId] INT NULL,
        [DisplayOrder] INT NOT NULL,
        [MaxRows] INT NULL,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_FormPlaceholderOccurrence] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_FormPlaceholderOccurrence_Sheet] FOREIGN KEY ([FormSheetId]) REFERENCES [dbo].[BCDT_FormSheet]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_FormPlaceholderOccurrence_Region] FOREIGN KEY ([FormDynamicRegionId]) REFERENCES [dbo].[BCDT_FormDynamicRegion]([Id]),
        CONSTRAINT [FK_FormPlaceholderOccurrence_Filter] FOREIGN KEY ([FilterDefinitionId]) REFERENCES [dbo].[BCDT_FilterDefinition]([Id]),
        CONSTRAINT [FK_FormPlaceholderOccurrence_DataSource] FOREIGN KEY ([DataSourceId]) REFERENCES [dbo].[BCDT_DataSource]([Id])
    ) ON [PRIMARY];
    CREATE INDEX [IX_FormPlaceholderOccurrence_FormSheet_DisplayOrder] ON [dbo].[BCDT_FormPlaceholderOccurrence]([FormSheetId], [DisplayOrder]);
    PRINT N'BCDT_FormPlaceholderOccurrence created';
END
GO

PRINT N'21.p8_filter_placeholder.sql completed.';
GO
