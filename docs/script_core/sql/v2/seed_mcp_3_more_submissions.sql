-- MCP batch 3: Them submission + 30 ReportDataRow cho TEST_EXCEL_ENTRY (idempotent).
-- Dung voi mcp_mssql_execute_sql (mot batch, khong GO).

EXEC [dbo].[sp_SetSystemContext];
DECLARE @FormId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_FormDefinition] WHERE [Code] = N'TEST_EXCEL_ENTRY');
IF @FormId IS NULL
  SELECT 0 AS Done;
ELSE
BEGIN
  DECLARE @VersionId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_FormVersion] WHERE [FormDefinitionId] = @FormId), @UserId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_User] ORDER BY Id);
  IF @UserId IS NULL SET @UserId = -1;
  DECLARE @ToInsert TABLE (OrganizationId INT, ReportingPeriodId INT PRIMARY KEY (OrganizationId, ReportingPeriodId));
  INSERT INTO @ToInsert (OrganizationId, ReportingPeriodId)
  SELECT o.Id, p.Id FROM [dbo].[BCDT_Organization] o CROSS JOIN [dbo].[BCDT_ReportingPeriod] p
  WHERE NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_ReportSubmission] s WHERE s.FormDefinitionId = @FormId AND s.OrganizationId = o.Id AND s.ReportingPeriodId = p.Id);
  INSERT INTO [dbo].[BCDT_ReportSubmission] ([FormDefinitionId], [FormVersionId], [OrganizationId], [ReportingPeriodId], [Status], [Version], [RevisionNumber], [CreatedBy])
  SELECT @FormId, @VersionId, OrganizationId, ReportingPeriodId, N'Draft', 1, 0, @UserId FROM @ToInsert;
  ;WITH SubWithoutRows AS (SELECT s.Id AS SubmissionId FROM [dbo].[BCDT_ReportSubmission] s WHERE s.FormDefinitionId = @FormId AND NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_ReportDataRow] r WHERE r.SubmissionId = s.Id)),
  Nums AS (SELECT n FROM (VALUES (2),(3),(4),(5),(6),(7),(8),(9),(10),(11),(12),(13),(14),(15),(16),(17),(18),(19),(20),(21),(22),(23),(24),(25),(26),(27),(28),(29),(30),(31)) t(n))
  INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [NumericValue1], [TextValue1], [TextValue2], [NumericValue2], [DateValue1], [CreatedBy])
  SELECT sw.SubmissionId, 0, n.n, n.n-1, N'MD'+RIGHT(N'000'+CAST(n.n-1 AS NVARCHAR(10)),3), N'Hang mau '+CAST(n.n-1 AS NVARCHAR(10)), (n.n-1)*10, DATEADD(DAY, (n.n-2)%28, '2026-01-01'), @UserId FROM SubWithoutRows sw CROSS JOIN Nums n;
  SELECT 1 AS Done, @@ROWCOUNT AS DataRowsAdded;
END
