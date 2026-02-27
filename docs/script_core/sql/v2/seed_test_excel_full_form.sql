-- ============================================================
-- BCDT - Form test đầy đủ: cột load sẵn, nhập liệu, công thức, khóa, dropdown
-- Chạy sau 14.seed_data.sql và 12.row_level_security.sql.
-- Form: TEST_EXCEL_FULL. 1 sheet, 8 cột (A–H).
-- ============================================================

SET NOCOUNT ON;

IF EXISTS (SELECT 1 FROM [dbo].[BCDT_FormDefinition] WHERE [Code] = N'TEST_EXCEL_FULL')
BEGIN
    PRINT N'Form TEST_EXCEL_FULL đã tồn tại. Bỏ qua.';
    RETURN;
END

IF OBJECT_ID(N'dbo.sp_SetSystemContext', N'P') IS NOT NULL
    EXEC [dbo].[sp_SetSystemContext];
ELSE
    EXEC sp_set_session_context N'IsSystemContext', 1;

DECLARE @FormId INT, @VersionId INT, @SheetId INT, @UserId INT;
DECLARE @ColA INT, @ColB INT, @ColC INT, @ColD INT, @ColE INT, @ColF INT, @ColG INT, @ColH INT;

SET @UserId = (SELECT TOP 1 Id FROM [dbo].[BCDT_User] ORDER BY Id);
IF @UserId IS NULL SET @UserId = -1;

-- FormDefinition
INSERT INTO [dbo].[BCDT_FormDefinition] ([Code], [Name], [FormType], [CurrentVersion], [Status], [IsActive], [CreatedBy])
VALUES (N'TEST_EXCEL_FULL', N'Biểu mẫu test đầy đủ (load sẵn, nhập, công thức, khóa, dropdown)', N'Input', 1, N'Published', 1, @UserId);
SET @FormId = SCOPE_IDENTITY();

INSERT INTO [dbo].[BCDT_FormVersion] ([FormDefinitionId], [VersionNumber], [VersionName], [IsActive], [CreatedBy])
VALUES (@FormId, 1, N'Phiên bản 1', 1, @UserId);
SET @VersionId = SCOPE_IDENTITY();

INSERT INTO [dbo].[BCDT_FormSheet] ([FormDefinitionId], [SheetIndex], [SheetName], [DisplayName], [IsDataSheet], [IsVisible], [DisplayOrder], [CreatedBy])
VALUES (@FormId, 0, N'Sheet1', N'Bảng nhập liệu', 1, 1, 0, @UserId);
SET @SheetId = SCOPE_IDENTITY();

-- 8 cột:
-- A: STT, B: Mã đơn vị, C: Mã hàng (nhóm "Thông tin chung"); D--H (nhóm "Số liệu")
INSERT INTO [dbo].[BCDT_FormColumn] ([FormSheetId], [ColumnCode], [ColumnName], [ColumnGroupName], [ExcelColumn], [DataType], [IsRequired], [IsEditable], [DefaultValue], [Formula], [ValidationRule], [DisplayOrder], [CreatedBy])
VALUES
    (@SheetId, N'STT', N'STT', N'Thông tin chung', N'A', N'Number', 0, 0, NULL, NULL, NULL, 0, @UserId),
    (@SheetId, N'MA_DON_VI', N'Mã đơn vị', N'Thông tin chung', N'B', N'Text', 0, 0, N'ORG01', NULL, NULL, 1, @UserId),
    (@SheetId, N'MA_HANG', N'Mã hàng', N'Thông tin chung', N'C', N'Text', 0, 1, NULL, NULL, NULL, 2, @UserId),
    (@SheetId, N'LOAI', N'Loại', N'Số liệu', N'D', N'Text', 0, 1, NULL, NULL, N'LIST:Loại A,Loại B,Loại C', 3, @UserId),
    (@SheetId, N'SO_LUONG', N'Số lượng', N'Số liệu', N'E', N'Number', 0, 1, NULL, NULL, NULL, 4, @UserId),
    (@SheetId, N'DON_GIA', N'Đơn giá', N'Số liệu', N'F', N'Number', 0, 1, NULL, NULL, NULL, 5, @UserId),
    (@SheetId, N'THANH_TIEN', N'Thành tiền', N'Số liệu', N'G', N'Number', 0, 0, NULL, N'=E*F', NULL, 6, @UserId),
    (@SheetId, N'NGAY', N'Ngày', N'Số liệu', N'H', N'Date', 0, 1, NULL, NULL, NULL, 7, @UserId);

SELECT @ColA = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'A';
SELECT @ColB = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'B';
SELECT @ColC = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'C';
SELECT @ColD = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'D';
SELECT @ColE = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'E';
SELECT @ColF = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'F';
SELECT @ColG = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'G';
SELECT @ColH = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ExcelColumn] = N'H';

INSERT INTO [dbo].[BCDT_FormColumnMapping] ([FormColumnId], [TargetColumnName], [TargetColumnIndex], [CreatedAt])
VALUES
    (@ColA, N'NumericValue1', 1, GETDATE()),
    (@ColB, N'TextValue1', 1, GETDATE()),
    (@ColC, N'TextValue2', 2, GETDATE()),
    (@ColD, N'TextValue3', 3, GETDATE()),
    (@ColE, N'NumericValue2', 2, GETDATE()),
    (@ColF, N'NumericValue3', 3, GETDATE()),
    (@ColG, N'NumericValue4', 4, GETDATE()),
    (@ColH, N'DateValue1', 1, GETDATE());

-- 1 submission mẫu + 20 ReportDataRow (Thành tiền = Số lượng * Đơn giá)
DECLARE @OrgId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_Organization] ORDER BY Id);
DECLARE @PeriodId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_ReportingPeriod] ORDER BY Id);
DECLARE @SubmissionId BIGINT;

INSERT INTO [dbo].[BCDT_ReportSubmission] ([FormDefinitionId], [FormVersionId], [OrganizationId], [ReportingPeriodId], [Status], [Version], [RevisionNumber], [CreatedBy])
VALUES (@FormId, @VersionId, @OrgId, @PeriodId, N'Draft', 1, 0, @UserId);
SET @SubmissionId = SCOPE_IDENTITY();

INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [NumericValue1], [TextValue1], [TextValue2], [TextValue3], [NumericValue2], [NumericValue3], [NumericValue4], [DateValue1], [CreatedBy])
VALUES
    (@SubmissionId, 0, 2, 1, N'ORG01', N'MH001', N'Loại A', 10, 1000, 10000, '2026-01-15', @UserId),
    (@SubmissionId, 0, 3, 2, N'ORG01', N'MH002', N'Loại B', 5, 2500, 12500, '2026-01-16', @UserId),
    (@SubmissionId, 0, 4, 3, N'ORG01', N'MH003', N'Loại C', 20, 500, 10000, '2026-01-17', @UserId),
    (@SubmissionId, 0, 5, 4, N'ORG01', N'MH004', N'Loại A', 8, 3000, 24000, '2026-01-18', @UserId),
    (@SubmissionId, 0, 6, 5, N'ORG01', N'MH005', N'Loại B', 15, 800, 12000, '2026-01-19', @UserId),
    (@SubmissionId, 0, 7, 6, N'ORG01', N'MH006', N'Loại C', 3, 5000, 15000, '2026-01-20', @UserId),
    (@SubmissionId, 0, 8, 7, N'ORG01', N'MH007', N'Loại A', 12, 1200, 14400, '2026-01-21', @UserId),
    (@SubmissionId, 0, 9, 8, N'ORG01', N'MH008', N'Loại B', 6, 4500, 27000, '2026-01-22', @UserId),
    (@SubmissionId, 0, 10, 9, N'ORG01', N'MH009', N'Loại C', 25, 400, 10000, '2026-01-23', @UserId),
    (@SubmissionId, 0, 11, 10, N'ORG01', N'MH010', N'Loại A', 4, 7500, 30000, '2026-01-24', @UserId),
    (@SubmissionId, 0, 12, 11, N'ORG01', N'MH011', N'Loại B', 9, 2000, 18000, '2026-01-25', @UserId),
    (@SubmissionId, 0, 13, 12, N'ORG01', N'MH012', N'Loại C', 7, 1500, 10500, '2026-01-26', @UserId),
    (@SubmissionId, 0, 14, 13, N'ORG01', N'MH013', N'Loại A', 11, 900, 9900, '2026-01-27', @UserId),
    (@SubmissionId, 0, 15, 14, N'ORG01', N'MH014', N'Loại B', 2, 6000, 12000, '2026-01-28', @UserId),
    (@SubmissionId, 0, 16, 15, N'ORG01', N'MH015', N'Loại C', 18, 550, 9900, '2026-01-29', @UserId),
    (@SubmissionId, 0, 17, 16, N'ORG01', N'MH016', N'Loại A', 14, 1800, 25200, '2026-01-30', @UserId),
    (@SubmissionId, 0, 18, 17, N'ORG01', N'MH017', N'Loại B', 1, 10000, 10000, '2026-01-31', @UserId),
    (@SubmissionId, 0, 19, 18, N'ORG01', N'MH018', N'Loại C', 22, 350, 7700, '2026-02-01', @UserId),
    (@SubmissionId, 0, 20, 19, N'ORG01', N'MH019', N'Loại A', 30, 333, 9990, '2026-02-02', @UserId),
    (@SubmissionId, 0, 21, 20, N'ORG01', N'MH020', N'Loại B', 16, 625, 10000, '2026-02-03', @UserId);

PRINT N'Form TEST_EXCEL_FULL: FormId=' + CAST(@FormId AS NVARCHAR(10)) + N', SubmissionId=' + CAST(@SubmissionId AS NVARCHAR(19));
PRINT N'Mở /submissions/' + CAST(@SubmissionId AS NVARCHAR(19)) + N'/entry để test.';

IF OBJECT_ID(N'dbo.sp_ClearUserContext', N'P') IS NOT NULL
    EXEC [dbo].[sp_ClearUserContext];
GO
