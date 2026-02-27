-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Additional Indexes and Constraints
-- Version: 2.0
-- ============================================================

-- ============================================================
-- COMPOSITE INDEXES FOR COMMON QUERIES
-- ============================================================

-- Submissions by organization and period (common dashboard query)
CREATE INDEX [IX_Submission_Org_Period_Status] 
ON [dbo].[BCDT_ReportSubmission]([OrganizationId], [ReportingPeriodId], [Status])
INCLUDE ([FormDefinitionId], [SubmittedAt]);
GO

-- User roles lookup (authorization)
CREATE INDEX [IX_UserRole_Lookup] 
ON [dbo].[BCDT_UserRole]([UserId], [IsActive], [ValidFrom], [ValidTo])
INCLUDE ([RoleId], [OrganizationId])
WHERE [IsActive] = 1;
GO

-- Form columns by sheet (form rendering)
CREATE INDEX [IX_FormColumn_Sheet_Order] 
ON [dbo].[BCDT_FormColumn]([FormSheetId], [DisplayOrder])
INCLUDE ([ColumnCode], [ColumnName], [ExcelColumn], [DataType], [IsEditable]);
GO

-- Workflow pending approvals (approver dashboard)
CREATE INDEX [IX_WorkflowInstance_Pending] 
ON [dbo].[BCDT_WorkflowInstance]([Status], [CurrentStep])
INCLUDE ([SubmissionId], [WorkflowDefinitionId])
WHERE [Status] = 'Pending';
GO

-- ============================================================
-- FILTERED INDEXES
-- ============================================================

-- Active organizations only
CREATE INDEX [IX_Organization_Active] 
ON [dbo].[BCDT_Organization]([IsActive], [OrganizationTypeId])
INCLUDE ([Code], [Name], [ParentId])
WHERE [IsActive] = 1 AND [IsDeleted] = 0;
GO

-- Active users only
CREATE INDEX [IX_User_Active] 
ON [dbo].[BCDT_User]([IsActive])
INCLUDE ([Username], [Email], [FullName])
WHERE [IsActive] = 1 AND [IsDeleted] = 0;
GO

-- Published forms only
CREATE INDEX [IX_FormDefinition_Published] 
ON [dbo].[BCDT_FormDefinition]([Status], [FormType])
INCLUDE ([Code], [Name], [ReportingFrequencyId])
WHERE [Status] = 'Published' AND [IsActive] = 1;
GO

-- ============================================================
-- COVERING INDEXES FOR REPORTING
-- ============================================================

-- Aggregate report summary by organization
CREATE INDEX [IX_ReportSummary_Org] 
ON [dbo].[BCDT_ReportSubmission]([OrganizationId], [Status])
INCLUDE ([FormDefinitionId], [ReportingPeriodId], [SubmittedAt], [ApprovedAt]);
GO

-- ============================================================
-- FOREIGN KEY INDEXES (if not auto-created)
-- ============================================================

-- These are typically auto-created but ensuring they exist
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_FormDefinition_Frequency')
    CREATE INDEX [IX_FormDefinition_Frequency] 
    ON [dbo].[BCDT_FormDefinition]([ReportingFrequencyId]);
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Submission_Workflow')
    CREATE INDEX [IX_Submission_Workflow] 
    ON [dbo].[BCDT_ReportSubmission]([WorkflowInstanceId])
    WHERE [WorkflowInstanceId] IS NOT NULL;
GO

-- ============================================================
-- STATISTICS FOR QUERY OPTIMIZATION
-- ============================================================

-- Update statistics on key tables
UPDATE STATISTICS [dbo].[BCDT_ReportSubmission];
UPDATE STATISTICS [dbo].[BCDT_ReportDataRow];
UPDATE STATISTICS [dbo].[BCDT_Organization];
UPDATE STATISTICS [dbo].[BCDT_User];
GO

PRINT N'11.indexes.sql - Additional indexes created successfully';
GO
