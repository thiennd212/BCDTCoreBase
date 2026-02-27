-- ============================================================
-- P8e – Placeholder cột: FormDynamicColumnRegion, FormPlaceholderColumnOccurrence
-- Tham chiếu: GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md mục 4a
-- Phụ thuộc: 01–05, 20, 21 (FormSheet, FilterDefinition)
-- ============================================================

-- ============================================================
-- 1. BCDT_FormDynamicColumnRegion - Định nghĩa placeholder cột (một loại cột động)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_FormDynamicColumnRegion')
BEGIN
    CREATE TABLE [dbo].[BCDT_FormDynamicColumnRegion](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [FormSheetId] INT NOT NULL,
        [Code] NVARCHAR(50) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [ColumnSourceType] NVARCHAR(30) NOT NULL,
        [ColumnSourceRef] NVARCHAR(500) NULL,
        [LabelColumn] NVARCHAR(100) NULL,
        [DisplayOrder] INT NOT NULL,
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_FormDynamicColumnRegion] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_FormDynamicColumnRegion_Sheet] FOREIGN KEY ([FormSheetId]) REFERENCES [dbo].[BCDT_FormSheet]([Id]) ON DELETE CASCADE,
        CONSTRAINT [CK_FormDynamicColumnRegion_SourceType] CHECK ([ColumnSourceType] IN ('ByReportingPeriod', 'ByCatalog', 'ByDataSource', 'Fixed'))
    ) ON [PRIMARY];
    CREATE INDEX [IX_FormDynamicColumnRegion_FormSheet] ON [dbo].[BCDT_FormDynamicColumnRegion]([FormSheetId]);
    PRINT N'BCDT_FormDynamicColumnRegion created';
END
GO

-- ============================================================
-- 2. BCDT_FormPlaceholderColumnOccurrence - Vị trí placeholder cột (một cột = một occurrence)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_FormPlaceholderColumnOccurrence')
BEGIN
    CREATE TABLE [dbo].[BCDT_FormPlaceholderColumnOccurrence](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [FormSheetId] INT NOT NULL,
        [FormDynamicColumnRegionId] INT NOT NULL,
        [ExcelColStart] INT NOT NULL,
        [FilterDefinitionId] INT NULL,
        [DisplayOrder] INT NOT NULL,
        [MaxColumns] INT NULL,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_FormPlaceholderColumnOccurrence] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [FK_FormPlaceholderColumnOccurrence_Sheet] FOREIGN KEY ([FormSheetId]) REFERENCES [dbo].[BCDT_FormSheet]([Id]) ON DELETE CASCADE,
        CONSTRAINT [FK_FormPlaceholderColumnOccurrence_Region] FOREIGN KEY ([FormDynamicColumnRegionId]) REFERENCES [dbo].[BCDT_FormDynamicColumnRegion]([Id]),
        CONSTRAINT [FK_FormPlaceholderColumnOccurrence_Filter] FOREIGN KEY ([FilterDefinitionId]) REFERENCES [dbo].[BCDT_FilterDefinition]([Id])
    ) ON [PRIMARY];
    CREATE INDEX [IX_FormPlaceholderColumnOccurrence_FormSheet_DisplayOrder] ON [dbo].[BCDT_FormPlaceholderColumnOccurrence]([FormSheetId], [DisplayOrder]);
    PRINT N'BCDT_FormPlaceholderColumnOccurrence created';
END
GO

PRINT N'22.p8_column_placeholder.sql completed.';
GO
