-- ============================================================
-- BCDT - Seed biểu mẫu "Báo cáo tình hình đầu tư (KKT-E)" 
-- Cấu trúc: 4 cột (Chỉ tiêu, Đơn vị tính, KCN trong KKT, Khu vực khác)
-- Chạy sau schema 01-14, 12 (RLS). Idempotent: xóa form cũ rồi insert lại.
--
-- QUAN TRỌNG – Tiếng Việt: File UTF-8, chạy sqlcmd với -f 65001 để tránh lỗi mojibake:
--   sqlcmd -S localhost,1433 -d BCDT -U sa -P "..." -f 65001 -i seed_bao_cao_dau_tu_kkte.sql -C
-- ============================================================

SET NOCOUNT ON;
SET QUOTED_IDENTIFIER ON;

-- RLS: cần context trước khi DELETE/INSERT
IF OBJECT_ID(N'dbo.sp_SetSystemContext', N'P') IS NOT NULL
    EXEC [dbo].[sp_SetSystemContext];
ELSE
    EXEC sp_set_session_context N'IsSystemContext', 1;

-- Xóa form cũ (nếu có): DataRow -> Submission -> ColumnMapping -> Column -> Sheet -> Version -> Definition
DECLARE @FId INT = (SELECT Id FROM [dbo].[BCDT_FormDefinition] WHERE [Code] = N'BAO_CAO_DAU_TU_KKTE');
IF @FId IS NOT NULL
BEGIN
    DELETE FROM [dbo].[BCDT_ReportDataRow] WHERE SubmissionId IN (SELECT s.Id FROM [dbo].[BCDT_ReportSubmission] s WHERE s.FormVersionId IN (SELECT Id FROM [dbo].[BCDT_FormVersion] WHERE FormDefinitionId = @FId));
    DELETE FROM [dbo].[BCDT_ReportSubmission] WHERE FormVersionId IN (SELECT Id FROM [dbo].[BCDT_FormVersion] WHERE FormDefinitionId = @FId);
    DELETE FROM [dbo].[BCDT_FormColumnMapping] WHERE FormColumnId IN (SELECT Id FROM [dbo].[BCDT_FormColumn] WHERE FormSheetId IN (SELECT Id FROM [dbo].[BCDT_FormSheet] WHERE FormDefinitionId = @FId));
    DELETE FROM [dbo].[BCDT_FormColumn] WHERE FormSheetId IN (SELECT Id FROM [dbo].[BCDT_FormSheet] WHERE FormDefinitionId = @FId);
    DELETE FROM [dbo].[BCDT_FormSheet] WHERE FormDefinitionId = @FId;
    DELETE FROM [dbo].[BCDT_FormVersion] WHERE FormDefinitionId = @FId;
    DELETE FROM [dbo].[BCDT_FormDefinition] WHERE Id = @FId;
END

IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Organization])
    INSERT INTO [dbo].[BCDT_Organization] ([Code], [Name], [OrganizationTypeId], [ParentId], [TreePath], [Level], [IsActive], [DisplayOrder], [CreatedBy])
    VALUES (N'TEST_ORG', N'Đơn vị test', 1, NULL, N'/1/', 1, 1, 0, -1);

IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_ReportingPeriod])
BEGIN
    DECLARE @FreqId INT = (SELECT TOP 1 Id FROM [dbo].[BCDT_ReportingFrequency] WHERE Code = 'MONTHLY');
    IF @FreqId IS NOT NULL
        INSERT INTO [dbo].[BCDT_ReportingPeriod] ([ReportingFrequencyId], [PeriodCode], [PeriodName], [Year], [Month], [StartDate], [EndDate], [Deadline], [Status], [IsCurrent], [CreatedBy])
        VALUES (@FreqId, N'2026-01', N'Tháng 01/2026', 2026, 1, '2026-01-01', '2026-01-31', '2026-02-10', N'Open', 1, -1);
END

DECLARE @FormId INT, @VersionId INT, @SheetId INT;
DECLARE @ColChiTieu INT, @ColDonVi INT, @ColKCN INT, @ColKhac INT;
DECLARE @OrgId INT, @PeriodId INT, @UserId INT, @SubmissionId BIGINT;

SELECT TOP 1 @OrgId = Id FROM [dbo].[BCDT_Organization] ORDER BY Id;
SELECT TOP 1 @PeriodId = Id FROM [dbo].[BCDT_ReportingPeriod] ORDER BY Id;
SELECT TOP 1 @UserId = Id FROM [dbo].[BCDT_User] ORDER BY Id;
IF @UserId IS NULL SET @UserId = -1;

-- FormDefinition
INSERT INTO [dbo].[BCDT_FormDefinition] ([Code], [Name], [FormType], [CurrentVersion], [Status], [IsActive], [CreatedBy])
VALUES (N'BAO_CAO_DAU_TU_KKTE', N'Báo cáo tình hình đầu tư (KKT-E)', N'Input', 1, N'Published', 1, @UserId);
SET @FormId = SCOPE_IDENTITY();

INSERT INTO [dbo].[BCDT_FormVersion] ([FormDefinitionId], [VersionNumber], [VersionName], [IsActive], [CreatedBy])
VALUES (@FormId, 1, N'Phiên bản 1', 1, @UserId);
SET @VersionId = SCOPE_IDENTITY();

INSERT INTO [dbo].[BCDT_FormSheet] ([FormDefinitionId], [SheetIndex], [SheetName], [DisplayName], [IsDataSheet], [IsVisible], [DisplayOrder], [CreatedBy])
VALUES (@FormId, 0, N'Sheet1', N'Báo cáo đầu tư', 1, 1, 0, @UserId);
SET @SheetId = SCOPE_IDENTITY();

-- FormColumn: Chỉ tiêu (A), Đơn vị tính (B), Đối với các KCN trong KKT (C), Đối với các khu vực khác (D)
INSERT INTO [dbo].[BCDT_FormColumn] ([FormSheetId], [ColumnCode], [ColumnName], [ExcelColumn], [DataType], [IsRequired], [IsEditable], [DisplayOrder], [CreatedBy])
VALUES 
    (@SheetId, N'CHI_TIEU', N'Chỉ tiêu', N'A', N'Text', 0, 0, 0, @UserId),
    (@SheetId, N'DON_VI_TINH', N'Đơn vị tính', N'B', N'Text', 0, 0, 1, @UserId),
    (@SheetId, N'KCN_TRONG_KKT', N'Đối với các KCN trong KKT', N'C', N'Number', 0, 1, 2, @UserId),
    (@SheetId, N'KHAC_NGOAI_KCN', N'Đối với các khu vực khác ngoài KCN trong KKT', N'D', N'Number', 0, 1, 3, @UserId);

SELECT @ColChiTieu = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ColumnCode] = N'CHI_TIEU';
SELECT @ColDonVi   = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ColumnCode] = N'DON_VI_TINH';
SELECT @ColKCN     = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ColumnCode] = N'KCN_TRONG_KKT';
SELECT @ColKhac    = Id FROM [dbo].[BCDT_FormColumn] WHERE [FormSheetId] = @SheetId AND [ColumnCode] = N'KHAC_NGOAI_KCN';

INSERT INTO [dbo].[BCDT_FormColumnMapping] ([FormColumnId], [TargetColumnName], [TargetColumnIndex], [CreatedAt])
VALUES 
    (@ColChiTieu, N'TextValue1', 1, GETDATE()),
    (@ColDonVi,   N'TextValue2', 2, GETDATE()),
    (@ColKCN,     N'NumericValue1', 1, GETDATE()),
    (@ColKhac,    N'NumericValue2', 2, GETDATE());

-- ReportSubmission (Draft) - cần unique (FormDefinitionId, OrganizationId, ReportingPeriodId). Nếu đã có submission cho form này thì dùng hoặc tạo org/period khác.
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_ReportSubmission] WHERE [FormDefinitionId] = @FormId AND [OrganizationId] = @OrgId AND [ReportingPeriodId] = @PeriodId)
BEGIN
    INSERT INTO [dbo].[BCDT_ReportSubmission] ([FormDefinitionId], [FormVersionId], [OrganizationId], [ReportingPeriodId], [Status], [Version], [RevisionNumber], [CreatedBy])
    VALUES (@FormId, @VersionId, @OrgId, @PeriodId, N'Draft', 1, 0, @UserId);
    SET @SubmissionId = SCOPE_IDENTITY();
END
ELSE
    SELECT @SubmissionId = Id FROM [dbo].[BCDT_ReportSubmission] WHERE [FormDefinitionId] = @FormId AND [OrganizationId] = @OrgId AND [ReportingPeriodId] = @PeriodId;

-- ReportDataRow: hàng 1 = header, từ hàng 2 = nội dung (A, A.I, A.II, B, C, D)
-- TextValue1=Chỉ tiêu, TextValue2=Đơn vị, NumericValue1=KCN, NumericValue2=Khác
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES (@SubmissionId, 0, 1, N'Chỉ tiêu', N'Đơn vị tính', NULL, NULL, @UserId);

DECLARE @r INT = 2;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'A. Tình hình cấp, điều chỉnh và thu hồi các dự án đầu tư sản xuất kinh doanh', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'A.I. Dự án đầu tư nước ngoài', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'1. Tình hình cấp mới', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án đầu tư cấp mới', N'dự án', 5, 12, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng vốn đầu tư đăng ký mới', N'tr.USD', 120.5, 280.3, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'2. Tình hình tăng vốn', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án đầu tư tăng vốn', N'dự án', 3, 7, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng vốn đầu tư tăng', N'tr.USD', 45.2, 92.1, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'3. Tình hình giảm vốn', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án đầu tư giảm vốn', N'dự án', 0, 1, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng vốn đầu tư giảm', N'tr.USD', 0, 5.2, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'4. Tình hình thu hồi/chấm dứt hoạt động', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án thu hồi/chấm dứt hoạt động', N'dự án', 0, 0, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng vốn đầu tư thu hồi/chấm dứt hoạt động', N'tr.USD', NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'5. Biến động về quy mô diện tích đất cho thuê (tổng quy mô diện tích cho thuê - tổng quy mô diện tích thu hồi)', N'ha', 12.5, 8.3, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'6. Lũy kế đến cuối kỳ báo cáo', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án', N'dự án', 28, 56, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng vốn đầu tư đăng ký', N'tr.USD', 1250.8, 2100.5, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng vốn đầu tư thực hiện', N'tr.USD', 980.2, 1650.3, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng quy mô diện tích đất đã cho thuê', N'ha', 450.5, 320.8, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số doanh nghiệp đang hoạt động', N'doanh nghiệp', 25, 48, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số lao động', N'người', 12500, 18200, @UserId); SET @r = @r + 1;

INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'A.II. Dự án đầu tư trong nước', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'1. Tình hình cấp mới', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án đầu tư cấp mới', N'dự án', 8, 15, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng vốn đầu tư đăng ký mới', N'tỷ VND', 1250.5, 3200.8, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'6. Lũy kế đến cuối kỳ báo cáo', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án', N'dự án', 42, 88, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng vốn đầu tư đăng ký', N'tỷ VND', 8500.2, 15200.5, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số lao động', N'người', 8200, 12500, @UserId); SET @r = @r + 1;

INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'B. Tình hình cấp, điều chỉnh và thu hồi các dự án đầu tư hạ tầng kỹ thuật, xã hội', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'B.I. Dự án đầu tư nước ngoài', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án đầu tư cấp mới', N'dự án', 2, 3, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'B.II. Dự án đầu tư trong nước', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Số dự án đầu tư cấp mới', N'dự án', 4, 6, @UserId); SET @r = @r + 1;

INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'C. Tình hình sản xuất kinh doanh của các dự án đầu tư', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'1. Dự án đầu tư nước ngoài', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Doanh thu', N'tr.USD', 520.5, 880.2, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Giá trị nhập khẩu', N'tr.USD', 180.3, 320.5, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Giá trị xuất khẩu', N'tr.USD', 350.2, 520.8, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Nộp ngân sách', N'tr.USD', 125.5, 210.3, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Quy đổi sang VNĐ', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Doanh thu', N'tỷ VND', 13200.5, 22400.8, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Giá trị nhập khẩu', N'tỷ VND', 4560.2, 8160.5, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Giá trị xuất khẩu', N'tỷ VND', 9240.3, 13824.8, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Nộp ngân sách', N'tỷ VND', 125.5, 210.3, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'2. Dự án đầu tư trong nước', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Doanh thu', N'tỷ VND', 1850.2, 3200.5, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Giá trị nhập khẩu', N'tỷ VND', 420.5, 880.2, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Giá trị xuất khẩu', N'tỷ VND', 520.8, 1040.5, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Nộp ngân sách', N'tỷ VND', 95.8, 165.2, @UserId); SET @r = @r + 1;

INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'D. Lao động', NULL, NULL, NULL, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Tổng số lao động', N'người', 20700, 30700, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Trong nước', N'người', 18500, 27800, @UserId); SET @r = @r + 1;
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
    (@SubmissionId, 0, @r, N'Nước ngoài', N'người', 2200, 2900, @UserId);

IF OBJECT_ID(N'dbo.sp_ClearUserContext', N'P') IS NOT NULL
    EXEC [dbo].[sp_ClearUserContext];

PRINT N'Seed BAO_CAO_DAU_TU_KKTE: FormId=' + CAST(@FormId AS NVARCHAR(10)) + N', SubmissionId=' + CAST(@SubmissionId AS NVARCHAR(19));
