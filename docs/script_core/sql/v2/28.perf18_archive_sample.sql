-- ============================================================
-- BCDT - Perf-18 Archive policy (SCRIPT MẪU – KHÔNG CHẠY TRỰC TIẾP LÊN PRODUCTION)
-- ============================================================
-- Mục đích: Bảng archive và logic mẫu chuyển submission đã Approved quá hạn (theo ArchivePolicy.RetentionYears).
-- Tham chiếu: DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md 3.2.3, PERF11_PARTITION_REPLICA_ARCHIVE.md mục 3.
-- Chạy CHỈ trong môi trường test sau khi backup; production cần maintenance window và duyệt.
-- ============================================================

SET NOCOUNT ON;

-- ---------------------------------------------------------------------
-- 1. Tạo bảng archive (cùng cấu trúc, không FK tới bảng chính)
-- ---------------------------------------------------------------------

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_ReportSubmission_Archive')
BEGIN
    CREATE TABLE [dbo].[BCDT_ReportSubmission_Archive](
        [Id] BIGINT NOT NULL,
        [FormDefinitionId] INT NOT NULL,
        [FormVersionId] INT NOT NULL,
        [OrganizationId] INT NOT NULL,
        [ReportingPeriodId] INT NOT NULL,
        [Status] NVARCHAR(20) NOT NULL,
        [SubmittedAt] DATETIME2 NULL,
        [SubmittedBy] INT NULL,
        [ApprovedAt] DATETIME2 NULL,
        [ApprovedBy] INT NULL,
        [WorkflowInstanceId] INT NULL,
        [CurrentWorkflowStep] INT NULL,
        [IsLocked] BIT NOT NULL,
        [LockedBy] INT NULL,
        [LockedAt] DATETIME2 NULL,
        [LockExpiresAt] DATETIME2 NULL,
        [Version] INT NOT NULL,
        [RevisionNumber] INT NOT NULL,
        [CreatedAt] DATETIME2 NOT NULL,
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        [IsDeleted] BIT NOT NULL,
        [ArchivedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        CONSTRAINT [PK_BCDT_ReportSubmission_Archive] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    PRINT N'28.perf18: Created BCDT_ReportSubmission_Archive.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_ReportPresentation_Archive')
BEGIN
    CREATE TABLE [dbo].[BCDT_ReportPresentation_Archive](
        [Id] BIGINT NOT NULL,
        [SubmissionId] BIGINT NOT NULL,
        [WorkbookJson] NVARCHAR(MAX) NOT NULL,
        [WorkbookHash] NVARCHAR(64) NOT NULL,
        [FileSize] INT NOT NULL,
        [SheetCount] TINYINT NOT NULL,
        [LastModifiedAt] DATETIME2 NOT NULL,
        [LastModifiedBy] INT NOT NULL,
        CONSTRAINT [PK_BCDT_ReportPresentation_Archive] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    PRINT N'28.perf18: Created BCDT_ReportPresentation_Archive.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_ReportDataRow_Archive')
BEGIN
    CREATE TABLE [dbo].[BCDT_ReportDataRow_Archive](
        [Id] BIGINT NOT NULL,
        [SubmissionId] BIGINT NOT NULL,
        [SheetIndex] TINYINT NOT NULL,
        [RowIndex] INT NOT NULL,
        [ReferenceEntityId] BIGINT NULL,
        [NumericValue1] DECIMAL(18,4) NULL,
        [NumericValue2] DECIMAL(18,4) NULL,
        [NumericValue3] DECIMAL(18,4) NULL,
        [NumericValue4] DECIMAL(18,4) NULL,
        [NumericValue5] DECIMAL(18,4) NULL,
        [NumericValue6] DECIMAL(18,4) NULL,
        [NumericValue7] DECIMAL(18,4) NULL,
        [NumericValue8] DECIMAL(18,4) NULL,
        [NumericValue9] DECIMAL(18,4) NULL,
        [NumericValue10] DECIMAL(18,4) NULL,
        [TextValue1] NVARCHAR(500) NULL,
        [TextValue2] NVARCHAR(500) NULL,
        [TextValue3] NVARCHAR(500) NULL,
        [DateValue1] DATE NULL,
        [DateValue2] DATE NULL,
        [CreatedAt] DATETIME2 NOT NULL,
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        CONSTRAINT [PK_BCDT_ReportDataRow_Archive] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    PRINT N'28.perf18: Created BCDT_ReportDataRow_Archive.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_ReportSummary_Archive')
BEGIN
    CREATE TABLE [dbo].[BCDT_ReportSummary_Archive](
        [Id] BIGINT NOT NULL,
        [SubmissionId] BIGINT NOT NULL,
        [SheetIndex] TINYINT NOT NULL,
        [TotalValue1] DECIMAL(18,4) NULL,
        [TotalValue2] DECIMAL(18,4) NULL,
        [TotalValue3] DECIMAL(18,4) NULL,
        [TotalValue4] DECIMAL(18,4) NULL,
        [TotalValue5] DECIMAL(18,4) NULL,
        [TotalValue6] DECIMAL(18,4) NULL,
        [TotalValue7] DECIMAL(18,4) NULL,
        [TotalValue8] DECIMAL(18,4) NULL,
        [TotalValue9] DECIMAL(18,4) NULL,
        [TotalValue10] DECIMAL(18,4) NULL,
        [RowCount] INT NOT NULL,
        [DataRowCount] INT NOT NULL,
        [CalculatedAt] DATETIME2 NOT NULL,
        CONSTRAINT [PK_BCDT_ReportSummary_Archive] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    PRINT N'28.perf18: Created BCDT_ReportSummary_Archive.';
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'BCDT_ReportDataAudit_Archive')
BEGIN
    CREATE TABLE [dbo].[BCDT_ReportDataAudit_Archive](
        [Id] BIGINT NOT NULL,
        [SubmissionId] BIGINT NOT NULL,
        [DataRowId] BIGINT NULL,
        [SheetIndex] TINYINT NOT NULL,
        [CellAddress] NVARCHAR(20) NOT NULL,
        [ColumnName] NVARCHAR(50) NULL,
        [OldValue] NVARCHAR(MAX) NULL,
        [NewValue] NVARCHAR(MAX) NULL,
        [ChangeType] NVARCHAR(20) NOT NULL,
        [ChangedAt] DATETIME2 NOT NULL,
        [ChangedBy] INT NOT NULL,
        [IpAddress] NVARCHAR(50) NULL,
        [UserAgent] NVARCHAR(500) NULL,
        CONSTRAINT [PK_BCDT_ReportDataAudit_Archive] PRIMARY KEY CLUSTERED ([Id] ASC)
    );
    PRINT N'28.perf18: Created BCDT_ReportDataAudit_Archive.';
END
GO

-- ---------------------------------------------------------------------
-- 2. Stored procedure mẫu – archive một batch submission (Perf-18)
-- ---------------------------------------------------------------------
-- Điều kiện: Status = 'Approved' và ReportingPeriod.EndDate < cutoff (cutoff = GETDATE() - RetentionYears).
-- Tham số: @RetentionYears (vd. 2), @BatchSize (vd. 500).
-- Ghi chú: Gọi từ Hangfire job hoặc chạy thủ công trong maintenance window.
IF OBJECT_ID('dbo.sp_BCDT_ArchiveSubmissions_Batch', 'P') IS NOT NULL
    DROP PROCEDURE dbo.sp_BCDT_ArchiveSubmissions_Batch;
GO
CREATE PROCEDURE dbo.sp_BCDT_ArchiveSubmissions_Batch
    @RetentionYears INT = 2,
    @BatchSize INT = 500
AS
BEGIN
    SET NOCOUNT ON;
    DECLARE @Cutoff DATE = DATEADD(YEAR, -@RetentionYears, GETDATE());

    -- Lấy batch submission Id đủ điều kiện (Approved, kỳ đã kết thúc quá RetentionYears)
    DECLARE @Ids TABLE (Id BIGINT PRIMARY KEY);
    INSERT INTO @Ids (Id)
    SELECT TOP (@BatchSize) s.Id
    FROM dbo.BCDT_ReportSubmission s
    INNER JOIN dbo.BCDT_ReportingPeriod p ON p.Id = s.ReportingPeriodId
    WHERE s.Status = N'Approved'
      AND s.IsDeleted = 0
      AND p.EndDate < @Cutoff
    ORDER BY s.Id;

    IF NOT EXISTS (SELECT 1 FROM @Ids)
    BEGIN
        SELECT 0 AS ArchivedCount;
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Copy sang bảng archive (thứ tự: phụ thuộc trước)
        INSERT INTO dbo.BCDT_ReportDataAudit_Archive (Id, SubmissionId, DataRowId, SheetIndex, CellAddress, ColumnName, OldValue, NewValue, ChangeType, ChangedAt, ChangedBy, IpAddress, UserAgent)
        SELECT a.Id, a.SubmissionId, a.DataRowId, a.SheetIndex, a.CellAddress, a.ColumnName, a.OldValue, a.NewValue, a.ChangeType, a.ChangedAt, a.ChangedBy, a.IpAddress, a.UserAgent
        FROM dbo.BCDT_ReportDataAudit a
        INNER JOIN @Ids i ON a.SubmissionId = i.Id;

        INSERT INTO dbo.BCDT_ReportDataRow_Archive (Id, SubmissionId, SheetIndex, RowIndex, ReferenceEntityId, NumericValue1, NumericValue2, NumericValue3, NumericValue4, NumericValue5, NumericValue6, NumericValue7, NumericValue8, NumericValue9, NumericValue10, TextValue1, TextValue2, TextValue3, DateValue1, DateValue2, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy)
        SELECT r.Id, r.SubmissionId, r.SheetIndex, r.RowIndex, r.ReferenceEntityId, r.NumericValue1, r.NumericValue2, r.NumericValue3, r.NumericValue4, r.NumericValue5, r.NumericValue6, r.NumericValue7, r.NumericValue8, r.NumericValue9, r.NumericValue10, r.TextValue1, r.TextValue2, r.TextValue3, r.DateValue1, r.DateValue2, r.CreatedAt, r.CreatedBy, r.UpdatedAt, r.UpdatedBy
        FROM dbo.BCDT_ReportDataRow r
        INNER JOIN @Ids i ON r.SubmissionId = i.Id;

        INSERT INTO dbo.BCDT_ReportSummary_Archive (Id, SubmissionId, SheetIndex, TotalValue1, TotalValue2, TotalValue3, TotalValue4, TotalValue5, TotalValue6, TotalValue7, TotalValue8, TotalValue9, TotalValue10, RowCount, DataRowCount, CalculatedAt)
        SELECT s.Id, s.SubmissionId, s.SheetIndex, s.TotalValue1, s.TotalValue2, s.TotalValue3, s.TotalValue4, s.TotalValue5, s.TotalValue6, s.TotalValue7, s.TotalValue8, s.TotalValue9, s.TotalValue10, s.RowCount, s.DataRowCount, s.CalculatedAt
        FROM dbo.BCDT_ReportSummary s
        INNER JOIN @Ids i ON s.SubmissionId = i.Id;

        INSERT INTO dbo.BCDT_ReportPresentation_Archive (Id, SubmissionId, WorkbookJson, WorkbookHash, FileSize, SheetCount, LastModifiedAt, LastModifiedBy)
        SELECT p.Id, p.SubmissionId, p.WorkbookJson, p.WorkbookHash, p.FileSize, p.SheetCount, p.LastModifiedAt, p.LastModifiedBy
        FROM dbo.BCDT_ReportPresentation p
        INNER JOIN @Ids i ON p.SubmissionId = i.Id;

        INSERT INTO dbo.BCDT_ReportSubmission_Archive (Id, FormDefinitionId, FormVersionId, OrganizationId, ReportingPeriodId, Status, SubmittedAt, SubmittedBy, ApprovedAt, ApprovedBy, WorkflowInstanceId, CurrentWorkflowStep, IsLocked, LockedBy, LockedAt, LockExpiresAt, Version, RevisionNumber, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, IsDeleted)
        SELECT s.Id, s.FormDefinitionId, s.FormVersionId, s.OrganizationId, s.ReportingPeriodId, s.Status, s.SubmittedAt, s.SubmittedBy, s.ApprovedAt, s.ApprovedBy, s.WorkflowInstanceId, s.CurrentWorkflowStep, s.IsLocked, s.LockedBy, s.LockedAt, s.LockExpiresAt, s.Version, s.RevisionNumber, s.CreatedAt, s.CreatedBy, s.UpdatedAt, s.UpdatedBy, s.IsDeleted
        FROM dbo.BCDT_ReportSubmission s
        INNER JOIN @Ids i ON s.Id = i.Id;

        -- Xóa từ bảng chính (child trước, parent sau)
        DELETE a FROM dbo.BCDT_ReportDataAudit a INNER JOIN @Ids i ON a.SubmissionId = i.Id;
        DELETE r FROM dbo.BCDT_ReportDataRow r INNER JOIN @Ids i ON r.SubmissionId = i.Id;
        DELETE s FROM dbo.BCDT_ReportSummary s INNER JOIN @Ids i ON s.SubmissionId = i.Id;
        DELETE p FROM dbo.BCDT_ReportPresentation p INNER JOIN @Ids i ON p.SubmissionId = i.Id;
        DELETE s FROM dbo.BCDT_ReportSubmission s INNER JOIN @Ids i ON s.Id = i.Id;

        COMMIT TRANSACTION;
        SELECT COUNT(*) AS ArchivedCount FROM @Ids;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

PRINT N'28.perf18_archive_sample.sql – Bảng archive + sp_BCDT_ArchiveSubmissions_Batch (mẫu). Chạy trong test; production cần backup và duyệt.';
GO
