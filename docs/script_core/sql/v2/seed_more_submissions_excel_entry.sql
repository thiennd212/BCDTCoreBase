-- ============================================================
-- BCDT - Thêm bản ghi báo cáo để test màn nhập liệu Excel
-- Chạy sau seed_test_excel_entry.sql (đã có Form TEST_EXCEL_ENTRY).
-- Chèn thêm ReportSubmission (các cặp Org+Period chưa có) và ~30 ReportDataRow/submission.
-- ============================================================

SET NOCOUNT ON;

IF OBJECT_ID(N'dbo.sp_SetSystemContext', N'P') IS NOT NULL
    EXEC [dbo].[sp_SetSystemContext];
ELSE
    EXEC sp_set_session_context N'IsSystemContext', 1;

DECLARE @FormId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_FormDefinition] WHERE [Code] = N'TEST_EXCEL_ENTRY');
IF @FormId IS NULL
BEGIN
    PRINT N'Chưa có Form TEST_EXCEL_ENTRY. Chạy seed_test_excel_entry.sql trước.';
    RETURN;
END

DECLARE @VersionId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_FormVersion] WHERE [FormDefinitionId] = @FormId);
DECLARE @UserId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_User] ORDER BY Id);
IF @UserId IS NULL SET @UserId = -1;

-- Bảng tạm: các cặp (OrganizationId, ReportingPeriodId) cần tạo submission
DECLARE @ToInsert TABLE (OrganizationId INT, ReportingPeriodId INT PRIMARY KEY (OrganizationId, ReportingPeriodId));

INSERT INTO @ToInsert (OrganizationId, ReportingPeriodId)
SELECT o.Id, p.Id
FROM [dbo].[BCDT_Organization] o
CROSS JOIN [dbo].[BCDT_ReportingPeriod] p
WHERE NOT EXISTS (
    SELECT 1 FROM [dbo].[BCDT_ReportSubmission] s
    WHERE s.FormDefinitionId = @FormId AND s.OrganizationId = o.Id AND s.ReportingPeriodId = p.Id
);

-- Chèn submission mới
INSERT INTO [dbo].[BCDT_ReportSubmission] ([FormDefinitionId], [FormVersionId], [OrganizationId], [ReportingPeriodId], [Status], [Version], [RevisionNumber], [CreatedBy])
SELECT @FormId, @VersionId, OrganizationId, ReportingPeriodId, N'Draft', 1, 0, @UserId
FROM @ToInsert;

DECLARE @InsertedCount INT = @@ROWCOUNT;
PRINT N'Đã thêm ' + CAST(@InsertedCount AS NVARCHAR(10)) + N' bản ghi báo cáo (ReportSubmission).';

-- Chèn ~30 ReportDataRow cho mỗi submission (cả mới và cũ) chưa có dòng nào
;WITH SubWithoutRows AS (
    SELECT s.Id AS SubmissionId
    FROM [dbo].[BCDT_ReportSubmission] s
    WHERE s.FormDefinitionId = @FormId
      AND NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_ReportDataRow] r WHERE r.SubmissionId = s.Id)
),
Nums AS (
    SELECT n FROM (VALUES (2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24),(25),(26),(27),(28),(29),(30),(31)) t(n)
)
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [NumericValue1], [TextValue1], [TextValue2], [NumericValue2], [DateValue1], [CreatedBy])
SELECT sw.SubmissionId, 0, n.n, n.n - 1,
    N'MD' + RIGHT(N'000' + CAST(n.n - 1 AS NVARCHAR(10)), 3),
    N'Hàng mẫu ' + CAST(n.n - 1 AS NVARCHAR(10)),
    (n.n - 1) * 10,
    DATEADD(DAY, (n.n - 2) % 28, '2026-01-01'),
    @UserId
FROM SubWithoutRows sw
CROSS JOIN Nums n;

PRINT N'Đã thêm ' + CAST(@@ROWCOUNT AS NVARCHAR(10)) + N' dòng dữ liệu (ReportDataRow) cho các submission chưa có dữ liệu.';

-- In danh sách submission để test
PRINT N'';
PRINT N'Danh sách submission test (Form TEST_EXCEL_ENTRY):';
EXEC [dbo].[sp_SetSystemContext];
SELECT s.Id AS SubmissionId, o.Code AS OrgCode, p.PeriodCode,
    (SELECT COUNT(*) FROM [dbo].[BCDT_ReportDataRow] r WHERE r.SubmissionId = s.Id) AS DataRowCount
FROM [dbo].[BCDT_ReportSubmission] s
JOIN [dbo].[BCDT_Organization] o ON o.Id = s.OrganizationId
JOIN [dbo].[BCDT_ReportingPeriod] p ON p.Id = s.ReportingPeriodId
WHERE s.FormDefinitionId = @FormId
ORDER BY s.Id;

IF OBJECT_ID(N'dbo.sp_ClearUserContext', N'P') IS NOT NULL
    EXEC [dbo].[sp_ClearUserContext];
GO
