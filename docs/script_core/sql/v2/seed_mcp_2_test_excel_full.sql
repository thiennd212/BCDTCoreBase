-- MCP batch 2: Seed TEST_EXCEL_FULL (form 8 cot + 1 submission + 20 rows). Chay khi chua co form.
-- Dung voi mcp_mssql_execute_sql (mot batch, khong GO).

IF EXISTS (SELECT 1 FROM [dbo].[BCDT_FormDefinition] WHERE [Code] = N'TEST_EXCEL_FULL')
  SELECT 0 AS Done;
ELSE
BEGIN
  EXEC [dbo].[sp_SetSystemContext];
  DECLARE @FormId INT, @VersionId INT, @SheetId INT, @ColA INT, @ColB INT, @ColC INT, @ColD INT, @ColE INT, @ColF INT, @ColG INT, @ColH INT, @UserId INT, @OrgId INT, @PeriodId INT, @SubmissionId BIGINT;
  SET @UserId = (SELECT TOP 1 Id FROM [dbo].[BCDT_User] ORDER BY Id);
  IF @UserId IS NULL SET @UserId = -1;
  INSERT INTO [dbo].[BCDT_FormDefinition] ([Code], [Name], [FormType], [CurrentVersion], [Status], [IsActive], [CreatedBy])
  VALUES (N'TEST_EXCEL_FULL', N'Bieu mau test day du', N'Input', 1, N'Published', 1, @UserId);
  SET @FormId = SCOPE_IDENTITY();
  INSERT INTO [dbo].[BCDT_FormVersion] ([FormDefinitionId], [VersionNumber], [VersionName], [IsActive], [CreatedBy]) VALUES (@FormId, 1, N'Phien ban 1', 1, @UserId);
  SET @VersionId = SCOPE_IDENTITY();
  INSERT INTO [dbo].[BCDT_FormSheet] ([FormDefinitionId], [SheetIndex], [SheetName], [DisplayName], [IsDataSheet], [IsVisible], [DisplayOrder], [CreatedBy])
  VALUES (@FormId, 0, N'Sheet1', N'Bang nhap lieu', 1, 1, 0, @UserId);
  SET @SheetId = SCOPE_IDENTITY();
  INSERT INTO [dbo].[BCDT_FormColumn] ([FormSheetId], [ColumnCode], [ColumnName], [ColumnGroupName], [ColumnGroupLevel2], [ExcelColumn], [DataType], [IsRequired], [IsEditable], [DefaultValue], [Formula], [ValidationRule], [DisplayOrder], [CreatedBy])
  VALUES (@SheetId, N'STT', N'STT', N'Thong tin chung', N'Dinh danh', N'A', N'Number', 0, 0, NULL, NULL, NULL, 0, @UserId), (@SheetId, N'MA_DON_VI', N'Ma don vi', N'Thong tin chung', N'Dinh danh', N'B', N'Text', 0, 0, N'ORG01', NULL, NULL, 1, @UserId), (@SheetId, N'MA_HANG', N'Ma hang', N'Thong tin chung', N'Dinh danh', N'C', N'Text', 0, 1, NULL, NULL, NULL, 2, @UserId), (@SheetId, N'LOAI', N'Loai', N'So lieu', N'Chi tiet', N'D', N'Text', 0, 1, NULL, NULL, N'LIST:Loai A,Loai B,Loai C', 3, @UserId), (@SheetId, N'SO_LUONG', N'So luong', N'So lieu', N'Chi tiet', N'E', N'Number', 0, 1, NULL, NULL, NULL, 4, @UserId), (@SheetId, N'DON_GIA', N'Don gia', N'So lieu', N'Chi tiet', N'F', N'Number', 0, 1, NULL, NULL, NULL, 5, @UserId), (@SheetId, N'THANH_TIEN', N'Thanh tien', N'So lieu', N'Chi tiet', N'G', N'Number', 0, 0, NULL, N'=E*F', NULL, 6, @UserId), (@SheetId, N'NGAY', N'Ngay', N'So lieu', N'Chi tiet', N'H', N'Date', 0, 1, NULL, NULL, NULL, 7, @UserId);
  SELECT @ColA = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'A';
  SELECT @ColB = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'B';
  SELECT @ColC = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'C';
  SELECT @ColD = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'D';
  SELECT @ColE = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'E';
  SELECT @ColF = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'F';
  SELECT @ColG = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'G';
  SELECT @ColH = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'H';
  INSERT INTO [dbo].[BCDT_FormColumnMapping] ([FormColumnId], [TargetColumnName], [TargetColumnIndex], [CreatedAt])
  VALUES (@ColA, N'NumericValue1', 1, GETDATE()), (@ColB, N'TextValue1', 1, GETDATE()), (@ColC, N'TextValue2', 2, GETDATE()), (@ColD, N'TextValue3', 3, GETDATE()), (@ColE, N'NumericValue2', 2, GETDATE()), (@ColF, N'NumericValue3', 3, GETDATE()), (@ColG, N'NumericValue4', 4, GETDATE()), (@ColH, N'DateValue1', 1, GETDATE());
  SET @OrgId = (SELECT TOP 1 Id FROM [dbo].[BCDT_Organization] ORDER BY Id);
  SET @PeriodId = (SELECT TOP 1 Id FROM [dbo].[BCDT_ReportingPeriod] ORDER BY Id);
  INSERT INTO [dbo].[BCDT_ReportSubmission] ([FormDefinitionId], [FormVersionId], [OrganizationId], [ReportingPeriodId], [Status], [Version], [RevisionNumber], [CreatedBy])
  VALUES (@FormId, @VersionId, @OrgId, @PeriodId, N'Draft', 1, 0, @UserId);
  SET @SubmissionId = SCOPE_IDENTITY();
  INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [NumericValue1], [TextValue1], [TextValue2], [TextValue3], [NumericValue2], [NumericValue3], [NumericValue4], [DateValue1], [CreatedBy])
  VALUES (@SubmissionId, 0, 2, 1, N'ORG01', N'MH001', N'Loai A', 10, 1000, 10000, '2026-01-15', @UserId), (@SubmissionId, 0, 3, 2, N'ORG01', N'MH002', N'Loai B', 5, 2500, 12500, '2026-01-16', @UserId), (@SubmissionId, 0, 4, 3, N'ORG01', N'MH003', N'Loai C', 20, 500, 10000, '2026-01-17', @UserId), (@SubmissionId, 0, 5, 4, N'ORG01', N'MH004', N'Loai A', 8, 3000, 24000, '2026-01-18', @UserId), (@SubmissionId, 0, 6, 5, N'ORG01', N'MH005', N'Loai B', 15, 800, 12000, '2026-01-19', @UserId), (@SubmissionId, 0, 7, 6, N'ORG01', N'MH006', N'Loai C', 3, 5000, 15000, '2026-01-20', @UserId), (@SubmissionId, 0, 8, 7, N'ORG01', N'MH007', N'Loai A', 12, 1200, 14400, '2026-01-21', @UserId), (@SubmissionId, 0, 9, 8, N'ORG01', N'MH008', N'Loai B', 6, 4500, 27000, '2026-01-22', @UserId), (@SubmissionId, 0, 10, 9, N'ORG01', N'MH009', N'Loai C', 25, 400, 10000, '2026-01-23', @UserId), (@SubmissionId, 0, 11, 10, N'ORG01', N'MH010', N'Loai A', 4, 7500, 30000, '2026-01-24', @UserId), (@SubmissionId, 0, 12, 11, N'ORG01', N'MH011', N'Loai B', 9, 2000, 18000, '2026-01-25', @UserId), (@SubmissionId, 0, 13, 12, N'ORG01', N'MH012', N'Loai C', 7, 1500, 10500, '2026-01-26', @UserId), (@SubmissionId, 0, 14, 13, N'ORG01', N'MH013', N'Loai A', 11, 900, 9900, '2026-01-27', @UserId), (@SubmissionId, 0, 15, 14, N'ORG01', N'MH014', N'Loai B', 2, 6000, 12000, '2026-01-28', @UserId), (@SubmissionId, 0, 16, 15, N'ORG01', N'MH015', N'Loai C', 18, 550, 9900, '2026-01-29', @UserId), (@SubmissionId, 0, 17, 16, N'ORG01', N'MH016', N'Loai A', 14, 1800, 25200, '2026-01-30', @UserId), (@SubmissionId, 0, 18, 17, N'ORG01', N'MH017', N'Loai B', 1, 10000, 10000, '2026-01-31', @UserId), (@SubmissionId, 0, 19, 18, N'ORG01', N'MH018', N'Loai C', 22, 350, 7700, '2026-02-01', @UserId), (@SubmissionId, 0, 20, 19, N'ORG01', N'MH019', N'Loai A', 30, 333, 9990, '2026-02-02', @UserId), (@SubmissionId, 0, 21, 20, N'ORG01', N'MH020', N'Loai B', 16, 625, 10000, '2026-02-03', @UserId);
  SELECT 1 AS Done, @SubmissionId AS SubmissionId;
END
