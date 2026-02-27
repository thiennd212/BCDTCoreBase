-- ============================================================
-- BCDT - Perf-11 Partition-ready (SCRIPT MẪU – KHÔNG CHẠY TRỰC TIẾP LÊN PRODUCTION)
-- ============================================================
-- Mục đích: Tài liệu hóa và script mẫu partition theo ReportingPeriodId hoặc năm.
-- Bảng mục tiêu (khi dữ liệu lớn): BCDT_ReportSubmission, (sau đó) BCDT_ReportDataRow, BCDT_ReportPresentation.
-- Chạy script này CHỈ trong môi trường test sau khi đã backup; production cần maintenance window.
-- Tham chiếu: DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md 0.3, PERF11_PARTITION_REPLICA_ARCHIVE.md.
-- ============================================================

SET NOCOUNT ON;

-- ---------------------------------------------------------------------
-- LỰA CHỌN 1: Partition theo NĂM (dựa trên ReportingPeriod.Year hoặc EndDate)
-- Phù hợp khi truy vấn thường lọc theo năm; partition key có thể là computed từ ReportingPeriodId.
-- ---------------------------------------------------------------------

-- Partition function: RANGE RIGHT – mỗi partition một năm (2023, 2024, 2025, 2026, 2027)
-- Lưu ý: BCDT_ReportSubmission có ReportingPeriodId (INT), không có cột Year. Để partition theo năm
-- cần thêm cột Persisted Computed (Year) hoặc dùng ReportingPeriodId làm key (xem lựa chọn 2).
IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = 'PF_BCDT_Year')
BEGIN
    CREATE PARTITION FUNCTION [PF_BCDT_Year](INT) AS RANGE RIGHT FOR VALUES (2023, 2024, 2025, 2026, 2027);
    PRINT N'27.perf11: Created partition function PF_BCDT_Year (sample).';
END
GO

-- Partition scheme: tất cả partition trên PRIMARY (mẫu); thực tế có thể tách filegroup.
IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = 'PS_BCDT_Year')
BEGIN
    CREATE PARTITION SCHEME [PS_BCDT_Year] AS PARTITION [PF_BCDT_Year] ALL TO ([PRIMARY]);
    PRINT N'27.perf11: Created partition scheme PS_BCDT_Year (sample).';
END
GO

-- ---------------------------------------------------------------------
-- LỰA CHỌN 2: Partition theo ReportingPeriodId (INT)
-- Phù hợp khi list submission theo kỳ; partition key = ReportingPeriodId.
-- ---------------------------------------------------------------------

-- Ví dụ: partition theo khoảng ReportingPeriodId (1-100, 101-200, ...).
-- Thay VALUES bằng danh sách boundary thực tế sau khi phân tích dữ liệu.
IF NOT EXISTS (SELECT 1 FROM sys.partition_functions WHERE name = 'PF_BCDT_ReportingPeriodId')
BEGIN
    CREATE PARTITION FUNCTION [PF_BCDT_ReportingPeriodId](INT) AS RANGE RIGHT FOR VALUES (100, 200, 300, 500, 1000);
    PRINT N'27.perf11: Created partition function PF_BCDT_ReportingPeriodId (sample boundaries).';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.partition_schemes WHERE name = 'PS_BCDT_ReportingPeriodId')
BEGIN
    CREATE PARTITION SCHEME [PS_BCDT_ReportingPeriodId] AS PARTITION [PF_BCDT_ReportingPeriodId] ALL TO ([PRIMARY]);
    PRINT N'27.perf11: Created partition scheme PS_BCDT_ReportingPeriodId (sample).';
END
GO

-- ---------------------------------------------------------------------
-- GHI CHÚ TRIỂN KHAI THỰC TẾ
-- ---------------------------------------------------------------------
-- 1. BCDT_ReportSubmission đã có cột ReportingPeriodId → có thể chuyển bảng sang PS_BCDT_ReportingPeriodId
--    bằng cách: tạo bảng mới trên scheme (CREATE TABLE ... ON PS_BCDT_ReportingPeriodId(ReportingPeriodId)),
--    copy dữ liệu, đổi tên, recreate FK/index. Cần maintenance window.
-- 2. BCDT_ReportDataRow / BCDT_ReportPresentation không có ReportingPeriodId. Nếu partition theo kỳ:
--    - Thêm cột ReportingPeriodId (nullable → backfill từ Submission → NOT NULL), sau đó dùng partition scheme tương tự.
-- 3. Query luôn có điều kiện ReportingPeriodId = @p (hoặc IN list) để partition elimination.
-- 4. Index: đảm bảo index hiện có (vd. IX_Submission_Period, IX_Submission_Org_Period_Status) tương thích partition.
-- ---------------------------------------------------------------------

PRINT N'27.perf11_partition_sample.sql - Sample partition objects created. Do NOT run on production without backup and test.';
GO
