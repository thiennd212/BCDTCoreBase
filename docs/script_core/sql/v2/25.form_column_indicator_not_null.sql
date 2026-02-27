-- ============================================================
-- BCDT - Phase 2b: FormColumn.IndicatorId NOT NULL
-- Tham chiếu: KE_HOACH_COT_HANG_TU_DANH_MUC_CHI_TIEU.md, DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md
-- Phụ thuộc: 20.chi_tieu_co_dinh_dong.sql (BCDT_Indicator, BCDT_FormColumn.IndicatorId NULL)
-- ============================================================

-- 1. Chỉ tiêu đặc biệt cho cột chưa gắn danh mục (Header/Formula/Stub hoặc "Tạo cột mới")
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Indicator] WHERE [Code] = N'_SPECIAL_GENERIC')
BEGIN
    INSERT INTO [dbo].[BCDT_Indicator] (
        [IndicatorCatalogId], [ParentId], [Code], [Name], [Description], [DataType],
        [Unit], [FormulaTemplate], [ValidationRule], [DefaultValue], [DisplayOrder], [IsActive],
        [CreatedAt], [CreatedBy], [UpdatedAt], [UpdatedBy]
    )
    VALUES (
        NULL, NULL, N'_SPECIAL_GENERIC', N'Chỉ tiêu đặc biệt (cột chưa gắn danh mục)', NULL, N'Text',
        NULL, NULL, NULL, NULL, 0, 1,
        GETUTCDATE(), 1, NULL, NULL
    );
    PRINT N'BCDT_Indicator _SPECIAL_GENERIC inserted.';
END
GO

-- 2. Gán IndicatorId cho mọi FormColumn đang NULL
DECLARE @SpecialIndicatorId INT = (SELECT [Id] FROM [dbo].[BCDT_Indicator] WHERE [Code] = N'_SPECIAL_GENERIC');
IF @SpecialIndicatorId IS NOT NULL
BEGIN
    UPDATE [dbo].[BCDT_FormColumn]
    SET [IndicatorId] = @SpecialIndicatorId
    WHERE [IndicatorId] IS NULL;
    PRINT N'BCDT_FormColumn: assigned IndicatorId for previously NULL rows.';
END
GO

-- 3. NOT NULL (drop index trước khi ALTER COLUMN, tạo lại sau)
IF EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('dbo.BCDT_FormColumn') AND name = 'IndicatorId')
   AND NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_FormColumn] WHERE [IndicatorId] IS NULL)
BEGIN
    IF EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.BCDT_FormColumn') AND name = 'IX_FormColumn_Indicator')
        DROP INDEX [IX_FormColumn_Indicator] ON [dbo].[BCDT_FormColumn];
    ALTER TABLE [dbo].[BCDT_FormColumn]
    ALTER COLUMN [IndicatorId] INT NOT NULL;
    IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.BCDT_FormColumn') AND name = 'IX_FormColumn_Indicator')
        CREATE INDEX [IX_FormColumn_Indicator] ON [dbo].[BCDT_FormColumn]([IndicatorId]);
    PRINT N'BCDT_FormColumn.IndicatorId set to NOT NULL.';
END
ELSE IF EXISTS (SELECT 1 FROM [dbo].[BCDT_FormColumn] WHERE [IndicatorId] IS NULL)
    PRINT N'WARNING: BCDT_FormColumn still has NULL IndicatorId. Run step 2 again or fix data.';
GO
