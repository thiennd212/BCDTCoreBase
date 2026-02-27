-- ============================================================
-- Seed B12 P4 mở rộng: Danh mục chỉ tiêu + cây Indicator + FormDynamicRegion
-- Dùng cho test GET workbook-data (pre-fill/merge theo IndicatorExpandDepth).
-- Chạy sau: 01-14, 20. Cần đã có ít nhất 1 FormDefinition + FormSheet (vd seed_mcp_1 hoặc test-b12-p2a).
-- ============================================================

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

DECLARE @UserId INT = 1;
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_User] WHERE Id = @UserId) SET @UserId = (SELECT TOP 1 Id FROM [dbo].[BCDT_User] ORDER BY Id);

-- 1. Catalog (idempotent)
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_IndicatorCatalog] WHERE Code = N'DM_P4_TEST')
BEGIN
    INSERT INTO [dbo].[BCDT_IndicatorCatalog] (Code, Name, Description, Scope, DisplayOrder, IsActive, CreatedBy)
    VALUES (N'DM_P4_TEST', N'Danh mục test P4 Workbook', N'Test sinh dòng theo depth', N'Global', 0, 1, @UserId);
END

DECLARE @CatalogId INT = (SELECT Id FROM [dbo].[BCDT_IndicatorCatalog] WHERE Code = N'DM_P4_TEST');

-- 2. Indicators cây: Gốc -> Con1, Con2 -> Cháu (dưới Con1). Idempotent theo Code trong catalog.
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Indicator] WHERE IndicatorCatalogId = @CatalogId AND Code = N'CT_GOC')
    INSERT INTO [dbo].[BCDT_Indicator] (IndicatorCatalogId, ParentId, Code, Name, DataType, DisplayOrder, IsActive, CreatedBy)
    VALUES (@CatalogId, NULL, N'CT_GOC', N'Chỉ tiêu gốc', N'Text', 0, 1, @UserId);

DECLARE @IdGoc INT = (SELECT Id FROM [dbo].[BCDT_Indicator] WHERE IndicatorCatalogId = @CatalogId AND Code = N'CT_GOC');

IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Indicator] WHERE IndicatorCatalogId = @CatalogId AND Code = N'CT_CON1')
    INSERT INTO [dbo].[BCDT_Indicator] (IndicatorCatalogId, ParentId, Code, Name, DataType, DisplayOrder, IsActive, CreatedBy)
    VALUES (@CatalogId, @IdGoc, N'CT_CON1', N'Chỉ tiêu con 1', N'Number', 0, 1, @UserId);
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Indicator] WHERE IndicatorCatalogId = @CatalogId AND Code = N'CT_CON2')
    INSERT INTO [dbo].[BCDT_Indicator] (IndicatorCatalogId, ParentId, Code, Name, DataType, DisplayOrder, IsActive, CreatedBy)
    VALUES (@CatalogId, @IdGoc, N'CT_CON2', N'Chỉ tiêu con 2', N'Number', 1, 1, @UserId);

DECLARE @IdCon1 INT = (SELECT Id FROM [dbo].[BCDT_Indicator] WHERE IndicatorCatalogId = @CatalogId AND Code = N'CT_CON1');

IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Indicator] WHERE IndicatorCatalogId = @CatalogId AND Code = N'CT_CHAU')
    INSERT INTO [dbo].[BCDT_Indicator] (IndicatorCatalogId, ParentId, Code, Name, DataType, DisplayOrder, IsActive, CreatedBy)
    VALUES (@CatalogId, @IdCon1, N'CT_CHAU', N'Chỉ tiêu cháu', N'Number', 0, 1, @UserId);

-- 3. FormDynamicRegion: ưu tiên sheet của form TEST_EXCEL_ENTRY (seed_mcp_1), không thì sheet đầu tiên
DECLARE @SheetId INT, @FormId INT;
SELECT TOP 1 @SheetId = s.Id, @FormId = s.FormDefinitionId
FROM [dbo].[BCDT_FormSheet] s
INNER JOIN [dbo].[BCDT_FormDefinition] f ON f.Id = s.FormDefinitionId
ORDER BY CASE WHEN f.Code = N'TEST_EXCEL_ENTRY' THEN 0 ELSE 1 END, s.FormDefinitionId, s.SheetIndex;

IF @SheetId IS NOT NULL AND NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_FormDynamicRegion] WHERE FormSheetId = @SheetId AND IndicatorCatalogId = @CatalogId)
BEGIN
    INSERT INTO [dbo].[BCDT_FormDynamicRegion] (FormSheetId, ExcelRowStart, ExcelColName, ExcelColValue, MaxRows, IndicatorExpandDepth, IndicatorCatalogId, DisplayOrder, CreatedBy)
    VALUES (@SheetId, 10, N'A', N'B', 100, 3, @CatalogId, 0, @UserId);
END

-- 4. Submission: seed khong tao submission (tranh vi pham UQ_Submission). Can co san submission (vd seed_mcp_1).

SELECT @CatalogId AS CatalogId, @SheetId AS SheetId, @FormId AS FormId,
       (SELECT TOP 1 Id FROM [dbo].[BCDT_ReportSubmission] WHERE FormDefinitionId = @FormId AND IsDeleted = 0 ORDER BY Id DESC) AS SubmissionId;
