-- ============================================================
-- BCDT - Dữ liệu test cho trang Nhập liệu Excel
-- Chạy sau khi đã có schema + seed_data (14.seed_data.sql).
-- Tạo: 1 Form (1 sheet, 5 cột), 1 Submission, ~80 ReportDataRow
-- Chạy lại: nếu đã có Form Code = TEST_EXCEL_ENTRY thì bỏ qua.
-- ============================================================

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM [dbo].[BCDT_FormDefinition] WHERE [Code] = N'TEST_EXCEL_ENTRY')
BEGIN
    PRINT N'Form TEST_EXCEL_ENTRY đã tồn tại. Bỏ qua seed.';
    RETURN;
END

-- RLS: đặt context để INSERT Submission/DataRow được phép (sp_SetSystemContext hoặc sp_SetUserContext với user admin)
IF OBJECT_ID(N'dbo.sp_SetSystemContext', N'P') IS NOT NULL
    EXEC [dbo].[sp_SetSystemContext];
ELSE
    EXEC sp_set_session_context N'IsSystemContext', 1;

-- Cần có ít nhất 1 Organization, 1 ReportingPeriod, 1 User
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Organization])
BEGIN
    INSERT INTO [dbo].[BCDT_Organization] ([Code], [Name], [OrganizationTypeId], [ParentId], [TreePath], [Level], [IsActive], [DisplayOrder], [CreatedBy])
    VALUES (N'TEST_ORG', N'Đơn vị test nhập liệu', 1, NULL, N'/1/', 1, 1, 0, -1);
END

IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_ReportingPeriod])
BEGIN
    DECLARE @FreqId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_ReportingFrequency] WHERE Code = 'MONTHLY');
    INSERT INTO [dbo].[BCDT_ReportingPeriod] ([ReportingFrequencyId], [PeriodCode], [PeriodName], [Year], [Month], [StartDate], [EndDate], [Deadline], [Status], [IsCurrent], [CreatedBy])
    VALUES (@FreqId, N'2026-01', N'Tháng 01/2026', 2026, 1, '2026-01-01', '2026-01-31', '2026-02-05', N'Open', 1, -1);
END

-- Biểu mẫu test
DECLARE @FormId INT, @VersionId INT, @SheetId INT;
DECLARE @ColA INT, @ColB INT, @ColC INT, @ColD INT, @ColE INT;
DECLARE @OrgId INT, @PeriodId INT, @UserId INT, @SubmissionId BIGINT;

SELECT TOP 1 @OrgId = Id FROM [dbo].[BCDT_Organization] ORDER BY Id;
SELECT TOP 1 @PeriodId = Id FROM [dbo].[BCDT_ReportingPeriod] ORDER BY Id;
SELECT TOP 1 @UserId = Id FROM [dbo].[BCDT_User] ORDER BY Id;
IF @UserId IS NULL SET @UserId = -1;

-- FormDefinition
INSERT INTO [dbo].[BCDT_FormDefinition] ([Code], [Name], [FormType], [CurrentVersion], [Status], [IsActive], [CreatedBy])
VALUES (N'TEST_EXCEL_ENTRY', N'Biểu mẫu test nhập liệu Excel', N'Input', 1, N'Published', 1, @UserId);
SET @FormId = SCOPE_IDENTITY();

-- FormVersion
INSERT INTO [dbo].[BCDT_FormVersion] ([FormDefinitionId], [VersionNumber], [VersionName], [IsActive], [CreatedBy])
VALUES (@FormId, 1, N'Phiên bản 1', 1, @UserId);
SET @VersionId = SCOPE_IDENTITY();

-- FormSheet
INSERT INTO [dbo].[BCDT_FormSheet] ([FormDefinitionId], [SheetIndex], [SheetName], [DisplayName], [IsDataSheet], [IsVisible], [DisplayOrder], [CreatedBy])
VALUES (@FormId, 0, N'Sheet1', N'Bảng số 1', 1, 1, 0, @UserId);
SET @SheetId = SCOPE_IDENTITY();

-- FormColumns: A=STT, B=Mã, C=Tên, D=Số lượng, E=Ngày
INSERT INTO [dbo].[BCDT_FormColumn] ([FormSheetId], [ColumnCode], [ColumnName], [ExcelColumn], [DataType], [IsRequired], [IsEditable], [DisplayOrder], [CreatedBy])
VALUES 
    (@SheetId, N'STT', N'STT', N'A', N'Number', 0, 1, 0, @UserId),
    (@SheetId, N'MA', N'Mã', N'B', N'Text', 0, 1, 1, @UserId),
    (@SheetId, N'TEN', N'Tên', N'C', N'Text', 0, 1, 2, @UserId),
    (@SheetId, N'SO_LUONG', N'Số lượng', N'D', N'Number', 0, 1, 3, @UserId),
    (@SheetId, N'NGAY', N'Ngày', N'E', N'Date', 0, 1, 4, @UserId);
SELECT @ColA = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'A';
SELECT @ColB = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'B';
SELECT @ColC = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'C';
SELECT @ColD = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'D';
SELECT @ColE = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'E';

-- FormColumnMapping (Excel cột -> cột lưu ReportDataRow)
INSERT INTO [dbo].[BCDT_FormColumnMapping] ([FormColumnId], [TargetColumnName], [TargetColumnIndex], [CreatedAt])
VALUES 
    (@ColA, N'NumericValue1', 1, GETDATE()),
    (@ColB, N'TextValue1', 1, GETDATE()),
    (@ColC, N'TextValue2', 2, GETDATE()),
    (@ColD, N'NumericValue2', 2, GETDATE()),
    (@ColE, N'DateValue1', 1, GETDATE());

-- ReportSubmission
INSERT INTO [dbo].[BCDT_ReportSubmission] ([FormDefinitionId], [FormVersionId], [OrganizationId], [ReportingPeriodId], [Status], [Version], [RevisionNumber], [CreatedBy])
VALUES (@FormId, @VersionId, @OrgId, @PeriodId, N'Draft', 1, 0, @UserId);
SET @SubmissionId = SCOPE_IDENTITY();

-- ReportDataRow: 80 dòng (RowIndex 2..81, SheetIndex 0)
DECLARE @i INT = 2;
WHILE @i <= 81
BEGIN
    INSERT INTO [dbo].[BCDT_ReportDataRow] 
        ([SubmissionId], [SheetIndex], [RowIndex], [NumericValue1], [TextValue1], [TextValue2], [NumericValue2], [DateValue1], [CreatedBy])
    VALUES 
        (@SubmissionId, 0, @i, 
         @i - 1, 
         N'MD' + RIGHT('000' + CAST(@i - 1 AS NVARCHAR(10)), 3), 
         N'Hàng mẫu ' + CAST(@i - 1 AS NVARCHAR(10)), 
         (@i - 1) * 10, 
         DATEADD(DAY, (@i - 2) % 28, '2026-01-01'),
         @UserId);
    SET @i = @i + 1;
END

PRINT N'Seed test Excel entry: FormId=' + CAST(@FormId AS NVARCHAR(10)) 
    + N', SubmissionId=' + CAST(@SubmissionId AS NVARCHAR(19))
    + N'. Mở /submissions/' + CAST(@SubmissionId AS NVARCHAR(19)) + N'/entry để test load Excel.';

-- (Tùy chọn) Xóa context sau khi seed
IF OBJECT_ID(N'dbo.sp_ClearUserContext', N'P') IS NOT NULL
    EXEC [dbo].[sp_ClearUserContext];
GO
