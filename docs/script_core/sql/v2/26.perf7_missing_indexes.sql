-- ============================================================
-- Perf-7 – Bổ sung index theo DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md 2.1.1, W16 2.2
-- Nguồn: sys.dm_db_missing_index_details (chạy trên DB BCDT khi có); ưu tiên bảng query thường.
-- Idempotent: IF NOT EXISTS cho mỗi index.
-- ============================================================

-- BCDT_ReportSubmission: list API lọc theo FormDefinitionId, OrganizationId, ReportingPeriodId, Status
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE object_id = OBJECT_ID('dbo.BCDT_ReportSubmission') AND name = 'IX_ReportSubmission_Form_Org_Period_Status')
BEGIN
    CREATE NONCLUSTERED INDEX [IX_ReportSubmission_Form_Org_Period_Status]
    ON [dbo].[BCDT_ReportSubmission]([FormDefinitionId], [OrganizationId], [ReportingPeriodId], [Status])
    INCLUDE ([FormVersionId], [SubmittedAt], [CreatedAt])
    WHERE [IsDeleted] = 0;
    PRINT N'Created IX_ReportSubmission_Form_Org_Period_Status';
END
GO

-- BCDT_ReportDataRow: truy vấn theo (SubmissionId, SheetIndex, RowIndex) – UQ_DataRow đã có; thêm covering nếu cần
-- (UQ_DataRow đã là nonclustered trên (SubmissionId, SheetIndex, RowIndex) – không tạo trùng)

-- BCDT_FilterCondition: đã có IX_FilterCondition_FilterDefinitionId trong 21.p8_filter_placeholder.sql – không tạo trùng

-- BCDT_FormPlaceholderOccurrence: đã có IX_FormPlaceholderOccurrence_FormSheet_DisplayOrder (FormSheetId, DisplayOrder) – không tạo trùng

-- BCDT_FormPlaceholderColumnOccurrence: đã có IX_FormPlaceholderColumnOccurrence_FormSheet_DisplayOrder (FormSheetId, DisplayOrder) – không tạo trùng

PRINT N'26.perf7_missing_indexes.sql completed. Chạy sys.dm_db_missing_index_details trên DB BCDT để xem gợi ý thêm.';
