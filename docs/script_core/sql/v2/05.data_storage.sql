-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Data Storage (Lưu trữ dữ liệu - Hybrid 2-Layer)
-- Version: 2.0
-- Tables: 5
-- ============================================================

-- ============================================================
-- 1. BCDT_ReportSubmission - Submission metadata
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReportSubmission](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [FormDefinitionId] INT NOT NULL,
    [FormVersionId] INT NOT NULL,
    [OrganizationId] INT NOT NULL,
    [ReportingPeriodId] INT NOT NULL,
    
    -- Status
    [Status] NVARCHAR(20) NOT NULL DEFAULT 'Draft',  -- Draft, Submitted, Approved, Rejected, Revision
    [SubmittedAt] DATETIME2 NULL,
    [SubmittedBy] INT NULL,
    [ApprovedAt] DATETIME2 NULL,
    [ApprovedBy] INT NULL,
    
    -- Workflow
    [WorkflowInstanceId] INT NULL,
    [CurrentWorkflowStep] INT NULL,
    
    -- Locking
    [IsLocked] BIT NOT NULL DEFAULT 0,
    [LockedBy] INT NULL,
    [LockedAt] DATETIME2 NULL,
    [LockExpiresAt] DATETIME2 NULL,
    
    -- Versioning
    [Version] INT NOT NULL DEFAULT 1,        -- For optimistic locking
    [RevisionNumber] INT NOT NULL DEFAULT 0, -- Number of revisions
    
    -- Audit
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    [IsDeleted] BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT [PK_BCDT_ReportSubmission] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Submission_Form] FOREIGN KEY ([FormDefinitionId]) REFERENCES [dbo].[BCDT_FormDefinition]([Id]),
    CONSTRAINT [FK_Submission_Version] FOREIGN KEY ([FormVersionId]) REFERENCES [dbo].[BCDT_FormVersion]([Id]),
    CONSTRAINT [FK_Submission_Org] FOREIGN KEY ([OrganizationId]) REFERENCES [dbo].[BCDT_Organization]([Id]),
    CONSTRAINT [UQ_Submission] UNIQUE NONCLUSTERED ([FormDefinitionId], [OrganizationId], [ReportingPeriodId])
) ON [PRIMARY];
GO

CREATE INDEX [IX_Submission_Org] ON [dbo].[BCDT_ReportSubmission]([OrganizationId]);
CREATE INDEX [IX_Submission_Period] ON [dbo].[BCDT_ReportSubmission]([ReportingPeriodId]);
CREATE INDEX [IX_Submission_Status] ON [dbo].[BCDT_ReportSubmission]([Status]);
GO

-- ============================================================
-- 2. BCDT_ReportPresentation - Layer 1: Full Excel workbook state (JSON)
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReportPresentation](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [SubmissionId] BIGINT NOT NULL,
    [WorkbookJson] NVARCHAR(MAX) NOT NULL,   -- Full Excel state as JSON
    [WorkbookHash] NVARCHAR(64) NOT NULL,    -- SHA256 hash for integrity
    [FileSize] INT NOT NULL,                 -- JSON size in bytes
    [SheetCount] TINYINT NOT NULL,           -- Number of sheets
    [LastModifiedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [LastModifiedBy] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_ReportPresentation] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Presentation_Submission] FOREIGN KEY ([SubmissionId]) REFERENCES [dbo].[BCDT_ReportSubmission]([Id]),
    CONSTRAINT [UQ_Presentation_Submission] UNIQUE NONCLUSTERED ([SubmissionId])
) ON [PRIMARY];
GO

-- ============================================================
-- 3. BCDT_ReportDataRow - Layer 2: Relational data (indexed for queries)
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReportDataRow](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [SubmissionId] BIGINT NOT NULL,
    [SheetIndex] TINYINT NOT NULL DEFAULT 0,
    [RowIndex] INT NOT NULL,                 -- Excel row number
    [ReferenceEntityId] BIGINT NULL,         -- Link to reference entity
    
    -- Generic numeric columns (mapped via FormColumnMapping)
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
    
    -- Generic text columns
    [TextValue1] NVARCHAR(500) NULL,
    [TextValue2] NVARCHAR(500) NULL,
    [TextValue3] NVARCHAR(500) NULL,
    
    -- Generic date columns
    [DateValue1] DATE NULL,
    [DateValue2] DATE NULL,
    
    -- Audit
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    
    CONSTRAINT [PK_BCDT_ReportDataRow] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_DataRow_Submission] FOREIGN KEY ([SubmissionId]) REFERENCES [dbo].[BCDT_ReportSubmission]([Id]),
    CONSTRAINT [UQ_DataRow] UNIQUE NONCLUSTERED ([SubmissionId], [SheetIndex], [RowIndex])
) ON [PRIMARY];
GO

-- Indexes for common queries
CREATE INDEX [IX_DataRow_Submission] ON [dbo].[BCDT_ReportDataRow]([SubmissionId]);
CREATE INDEX [IX_DataRow_Reference] ON [dbo].[BCDT_ReportDataRow]([ReferenceEntityId]) WHERE [ReferenceEntityId] IS NOT NULL;
-- Columnstore for analytics
CREATE NONCLUSTERED COLUMNSTORE INDEX [NCCI_DataRow_Analytics] 
ON [dbo].[BCDT_ReportDataRow]([SubmissionId], [NumericValue1], [NumericValue2], [NumericValue3], [NumericValue4], [NumericValue5]);
GO

-- ============================================================
-- 4. BCDT_ReportSummary - Layer 2.5: Pre-calculated aggregates
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReportSummary](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [SubmissionId] BIGINT NOT NULL,
    [SheetIndex] TINYINT NOT NULL DEFAULT 0,
    
    -- Pre-calculated totals (mapped via FormColumnMapping.AggregateFunction)
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
    
    -- Counts
    [RowCount] INT NOT NULL DEFAULT 0,
    [DataRowCount] INT NOT NULL DEFAULT 0,   -- Rows with actual data
    
    -- Calculated at
    [CalculatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_BCDT_ReportSummary] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Summary_Submission] FOREIGN KEY ([SubmissionId]) REFERENCES [dbo].[BCDT_ReportSubmission]([Id]),
    CONSTRAINT [UQ_Summary] UNIQUE NONCLUSTERED ([SubmissionId], [SheetIndex])
) ON [PRIMARY];
GO

-- ============================================================
-- 5. BCDT_ReportDataAudit - Cell-level audit trail
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReportDataAudit](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [SubmissionId] BIGINT NOT NULL,
    [DataRowId] BIGINT NULL,                 -- NULL for presentation-only changes
    [SheetIndex] TINYINT NOT NULL,
    [CellAddress] NVARCHAR(20) NOT NULL,     -- A1, B5, etc.
    [ColumnName] NVARCHAR(50) NULL,          -- Mapped column name
    [OldValue] NVARCHAR(MAX) NULL,
    [NewValue] NVARCHAR(MAX) NULL,
    [ChangeType] NVARCHAR(20) NOT NULL,      -- Insert, Update, Delete
    [ChangedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [ChangedBy] INT NOT NULL,
    [IpAddress] NVARCHAR(50) NULL,
    [UserAgent] NVARCHAR(500) NULL,
    
    CONSTRAINT [PK_BCDT_ReportDataAudit] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_DataAudit_Submission] FOREIGN KEY ([SubmissionId]) REFERENCES [dbo].[BCDT_ReportSubmission]([Id])
) ON [PRIMARY];
GO

CREATE INDEX [IX_DataAudit_Submission] ON [dbo].[BCDT_ReportDataAudit]([SubmissionId], [ChangedAt] DESC);
CREATE INDEX [IX_DataAudit_Date] ON [dbo].[BCDT_ReportDataAudit]([ChangedAt] DESC);
GO

PRINT N'05.data_storage.sql - 5 tables created successfully';
GO
