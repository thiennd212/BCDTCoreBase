-- MCP batch 1: Seed TEST_EXCEL_ENTRY (form + 1 submission + 80 rows). Chay khi chua co form.
-- Dung voi mcp_mssql_execute_sql (mot batch, khong GO).

IF EXISTS (SELECT 1 FROM [dbo].[BCDT_FormDefinition] WHERE [Code] = N'TEST_EXCEL_ENTRY')
  SELECT 0 AS Done;
ELSE
BEGIN
  EXEC [dbo].[sp_SetSystemContext];
  IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Organization])
    INSERT INTO [dbo].[BCDT_Organization] ([Code], [Name], [OrganizationTypeId], [ParentId], [TreePath], [Level], [IsActive], [DisplayOrder], [CreatedBy])
    VALUES (N'TEST_ORG', N'Don vi test', 1, NULL, N'/1/', 1, 1, 0, -1);
  IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_ReportingPeriod])
    INSERT INTO [dbo].[BCDT_ReportingPeriod] ([ReportingFrequencyId], [PeriodCode], [PeriodName], [Year], [Month], [StartDate], [EndDate], [Deadline], [Status], [IsCurrent], [CreatedBy])
    SELECT Id, N'2026-01', N'Thang 01/2026', 2026, 1, '2026-01-01', '2026-01-31', '2026-02-05', N'Open', 1, -1 FROM [dbo].[BCDT_ReportingFrequency] WHERE Code = 'MONTHLY';

  DECLARE @FormId INT, @VersionId INT, @SheetId INT, @ColA INT, @ColB INT, @ColC INT, @ColD INT, @ColE INT, @OrgId INT, @PeriodId INT, @UserId INT, @SubmissionId BIGINT, @i INT;
  SELECT TOP 1 @OrgId = Id FROM [dbo].[BCDT_Organization] ORDER BY Id;
  SELECT TOP 1 @PeriodId = Id FROM [dbo].[BCDT_ReportingPeriod] ORDER BY Id;
  SELECT TOP 1 @UserId = Id FROM [dbo].[BCDT_User] ORDER BY Id;
  IF @UserId IS NULL SET @UserId = -1;

  INSERT INTO [dbo].[BCDT_FormDefinition] ([Code], [Name], [FormType], [CurrentVersion], [Status], [IsActive], [CreatedBy])
  VALUES (N'TEST_EXCEL_ENTRY', N'Bieu mau test nhap lieu Excel', N'Input', 1, N'Published', 1, @UserId);
  SET @FormId = SCOPE_IDENTITY();
  INSERT INTO [dbo].[BCDT_FormVersion] ([FormDefinitionId], [VersionNumber], [VersionName], [IsActive], [CreatedBy]) VALUES (@FormId, 1, N'Phien ban 1', 1, @UserId);
  SET @VersionId = SCOPE_IDENTITY();
  INSERT INTO [dbo].[BCDT_FormSheet] ([FormDefinitionId], [SheetIndex], [SheetName], [DisplayName], [IsDataSheet], [IsVisible], [DisplayOrder], [CreatedBy])
  VALUES (@FormId, 0, N'Sheet1', N'Bang so 1', 1, 1, 0, @UserId);
  SET @SheetId = SCOPE_IDENTITY();
  INSERT INTO [dbo].[BCDT_FormColumn] ([FormSheetId], [ColumnCode], [ColumnName], [ExcelColumn], [DataType], [IsRequired], [IsEditable], [DisplayOrder], [CreatedBy])
  VALUES (@SheetId, N'STT', N'STT', N'A', N'Number', 0, 1, 0, @UserId), (@SheetId, N'MA', N'Ma', N'B', N'Text', 0, 1, 1, @UserId), (@SheetId, N'TEN', N'Ten', N'C', N'Text', 0, 1, 2, @UserId), (@SheetId, N'SO_LUONG', N'So luong', N'D', N'Number', 0, 1, 3, @UserId), (@SheetId, N'NGAY', N'Ngay', N'E', N'Date', 0, 1, 4, @UserId);
  SELECT @ColA = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'A';
  SELECT @ColB = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'B';
  SELECT @ColC = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'C';
  SELECT @ColD = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'D';
  SELECT @ColE = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'E';
  INSERT INTO [dbo].[BCDT_FormColumnMapping] ([FormColumnId], [TargetColumnName], [TargetColumnIndex], [CreatedAt])
  VALUES (@ColA, N'NumericValue1', 1, GETDATE()), (@ColB, N'TextValue1', 1, GETDATE()), (@ColC, N'TextValue2', 2, GETDATE()), (@ColD, N'NumericValue2', 2, GETDATE()), (@ColE, N'DateValue1', 1, GETDATE());
  INSERT INTO [dbo].[BCDT_ReportSubmission] ([FormDefinitionId], [FormVersionId], [OrganizationId], [ReportingPeriodId], [Status], [Version], [RevisionNumber], [CreatedBy])
  VALUES (@FormId, @VersionId, @OrgId, @PeriodId, N'Draft', 1, 0, @UserId);
  SET @SubmissionId = SCOPE_IDENTITY();
  SET @i = 2;
  WHILE @i <= 81
  BEGIN
    INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [NumericValue1], [TextValue1], [TextValue2], [NumericValue2], [DateValue1], [CreatedBy])
    VALUES (@SubmissionId, 0, @i, @i-1, N'MD'+RIGHT('000'+CAST(@i-1 AS NVARCHAR(10)),3), N'Hang mau '+CAST(@i-1 AS NVARCHAR(10)), (@i-1)*10, DATEADD(DAY, (@i-2)%28, '2026-01-01'), @UserId);
    SET @i = @i + 1;
  END
  SELECT 1 AS Done, @SubmissionId AS SubmissionId;
END
