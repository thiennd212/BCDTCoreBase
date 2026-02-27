-- Chèn 56 ReportDataRow cho form BAO_CAO_DAU_TU_KKTE (khi submission đã có, datarow chưa có).
-- Chạy với sp_SetSystemContext. Idempotent: chỉ insert khi COUNT = 0.
SET NOCOUNT ON;
IF OBJECT_ID(N'dbo.sp_SetSystemContext', N'P') IS NOT NULL EXEC [dbo].[sp_SetSystemContext];
ELSE EXEC sp_set_session_context N'IsSystemContext', 1;

DECLARE @SubId BIGINT = (SELECT Id FROM [dbo].[BCDT_ReportSubmission] WHERE [FormDefinitionId] = (SELECT Id FROM [dbo].[BCDT_FormDefinition] WHERE [Code] = N'BAO_CAO_DAU_TU_KKTE') AND [OrganizationId] = (SELECT TOP 1 Id FROM [dbo].[BCDT_Organization] ORDER BY Id) AND [ReportingPeriodId] = (SELECT TOP 1 Id FROM [dbo].[BCDT_ReportingPeriod] ORDER BY Id));

IF @SubId IS NOT NULL AND (SELECT COUNT(*) FROM [dbo].[BCDT_ReportDataRow] WHERE [SubmissionId] = @SubId) = 0
BEGIN
INSERT INTO [dbo].[BCDT_ReportDataRow] ([SubmissionId], [SheetIndex], [RowIndex], [TextValue1], [TextValue2], [NumericValue1], [NumericValue2], [CreatedBy])
VALUES
(@SubId, 0, 1, N'Chỉ tiêu', N'Đơn vị tính', NULL, NULL, -1),
(@SubId, 0, 2, N'A. Tình hình cấp, điều chỉnh và thu hồi các dự án đầu tư sản xuất kinh doanh', NULL, NULL, NULL, -1),
(@SubId, 0, 3, N'A.I. Dự án đầu tư nước ngoài', NULL, NULL, NULL, -1),
(@SubId, 0, 4, N'1. Tình hình cấp mới', NULL, NULL, NULL, -1),
(@SubId, 0, 5, N'Số dự án đầu tư cấp mới', N'dự án', 5, 12, -1),
(@SubId, 0, 6, N'Tổng vốn đầu tư đăng ký mới', N'tr.USD', 120.5, 280.3, -1),
(@SubId, 0, 7, N'2. Tình hình tăng vốn', NULL, NULL, NULL, -1),
(@SubId, 0, 8, N'Số dự án đầu tư tăng vốn', N'dự án', 3, 7, -1),
(@SubId, 0, 9, N'Tổng vốn đầu tư tăng', N'tr.USD', 45.2, 92.1, -1),
(@SubId, 0, 10, N'3. Tình hình giảm vốn', NULL, NULL, NULL, -1),
(@SubId, 0, 11, N'Số dự án đầu tư giảm vốn', N'dự án', 0, 1, -1),
(@SubId, 0, 12, N'Tổng vốn đầu tư giảm', N'tr.USD', 0, 5.2, -1),
(@SubId, 0, 13, N'4. Tình hình thu hồi/chấm dứt hoạt động', NULL, NULL, NULL, -1),
(@SubId, 0, 14, N'Số dự án thu hồi/chấm dứt hoạt động', N'dự án', 0, 0, -1),
(@SubId, 0, 15, N'Tổng vốn đầu tư thu hồi/chấm dứt hoạt động', N'tr.USD', NULL, NULL, -1),
(@SubId, 0, 16, N'5. Biến động về quy mô diện tích đất cho thuê (tổng quy mô diện tích cho thuê - tổng quy mô diện tích thu hồi)', N'ha', 12.5, 8.3, -1),
(@SubId, 0, 17, N'6. Lũy kế đến cuối kỳ báo cáo', NULL, NULL, NULL, -1),
(@SubId, 0, 18, N'Số dự án', N'dự án', 28, 56, -1),
(@SubId, 0, 19, N'Tổng vốn đầu tư đăng ký', N'tr.USD', 1250.8, 2100.5, -1),
(@SubId, 0, 20, N'Tổng vốn đầu tư thực hiện', N'tr.USD', 980.2, 1650.3, -1),
(@SubId, 0, 21, N'Tổng quy mô diện tích đất đã cho thuê', N'ha', 450.5, 320.8, -1),
(@SubId, 0, 22, N'Số doanh nghiệp đang hoạt động', N'doanh nghiệp', 25, 48, -1),
(@SubId, 0, 23, N'Số lao động', N'người', 12500, 18200, -1),
(@SubId, 0, 24, N'A.II. Dự án đầu tư trong nước', NULL, NULL, NULL, -1),
(@SubId, 0, 25, N'1. Tình hình cấp mới', NULL, NULL, NULL, -1),
(@SubId, 0, 26, N'Số dự án đầu tư cấp mới', N'dự án', 8, 15, -1),
(@SubId, 0, 27, N'Tổng vốn đầu tư đăng ký mới', N'tỷ VND', 1250.5, 3200.8, -1),
(@SubId, 0, 28, N'6. Lũy kế đến cuối kỳ báo cáo', NULL, NULL, NULL, -1),
(@SubId, 0, 29, N'Số dự án', N'dự án', 42, 88, -1),
(@SubId, 0, 30, N'Tổng vốn đầu tư đăng ký', N'tỷ VND', 8500.2, 15200.5, -1),
(@SubId, 0, 31, N'Số lao động', N'người', 8200, 12500, -1),
(@SubId, 0, 32, N'B. Tình hình cấp, điều chỉnh và thu hồi các dự án đầu tư hạ tầng kỹ thuật, xã hội', NULL, NULL, NULL, -1),
(@SubId, 0, 33, N'B.I. Dự án đầu tư nước ngoài', NULL, NULL, NULL, -1),
(@SubId, 0, 34, N'Số dự án đầu tư cấp mới', N'dự án', 2, 3, -1),
(@SubId, 0, 35, N'B.II. Dự án đầu tư trong nước', NULL, NULL, NULL, -1),
(@SubId, 0, 36, N'Số dự án đầu tư cấp mới', N'dự án', 4, 6, -1),
(@SubId, 0, 37, N'C. Tình hình sản xuất kinh doanh của các dự án đầu tư', NULL, NULL, NULL, -1),
(@SubId, 0, 38, N'1. Dự án đầu tư nước ngoài', NULL, NULL, NULL, -1),
(@SubId, 0, 39, N'Doanh thu', N'tr.USD', 520.5, 880.2, -1),
(@SubId, 0, 40, N'Giá trị nhập khẩu', N'tr.USD', 180.3, 320.5, -1),
(@SubId, 0, 41, N'Giá trị xuất khẩu', N'tr.USD', 350.2, 520.8, -1),
(@SubId, 0, 42, N'Nộp ngân sách', N'tr.USD', 125.5, 210.3, -1),
(@SubId, 0, 43, N'Quy đổi sang VNĐ', NULL, NULL, NULL, -1),
(@SubId, 0, 44, N'Doanh thu', N'tỷ VND', 13200.5, 22400.8, -1),
(@SubId, 0, 45, N'Giá trị nhập khẩu', N'tỷ VND', 4560.2, 8160.5, -1),
(@SubId, 0, 46, N'Giá trị xuất khẩu', N'tỷ VND', 9240.3, 13824.8, -1),
(@SubId, 0, 47, N'Nộp ngân sách', N'tỷ VND', 125.5, 210.3, -1),
(@SubId, 0, 48, N'2. Dự án đầu tư trong nước', NULL, NULL, NULL, -1),
(@SubId, 0, 49, N'Doanh thu', N'tỷ VND', 1850.2, 3200.5, -1),
(@SubId, 0, 50, N'Giá trị nhập khẩu', N'tỷ VND', 420.5, 880.2, -1),
(@SubId, 0, 51, N'Giá trị xuất khẩu', N'tỷ VND', 520.8, 1040.5, -1),
(@SubId, 0, 52, N'Nộp ngân sách', N'tỷ VND', 95.8, 165.2, -1),
(@SubId, 0, 53, N'D. Lao động', NULL, NULL, NULL, -1),
(@SubId, 0, 54, N'Tổng số lao động', N'người', 20700, 30700, -1),
(@SubId, 0, 55, N'Trong nước', N'người', 18500, 27800, -1),
(@SubId, 0, 56, N'Nước ngoài', N'người', 2200, 2900, -1);
END;
