-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Workflow (Quy trình phê duyệt)
-- Version: 2.0
-- Tables: 5
-- ============================================================

-- ============================================================
-- 1. BCDT_WorkflowDefinition - Workflow templates
-- ============================================================
CREATE TABLE [dbo].[BCDT_WorkflowDefinition](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(1000) NULL,
    [TotalSteps] TINYINT NOT NULL,           -- 1-5 steps
    [IsDefault] BIT NOT NULL DEFAULT 0,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    
    CONSTRAINT [PK_BCDT_WorkflowDefinition] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_WorkflowDefinition_Code] UNIQUE NONCLUSTERED ([Code] ASC),
    CONSTRAINT [CK_Workflow_Steps] CHECK ([TotalSteps] >= 1 AND [TotalSteps] <= 5)
) ON [PRIMARY];
GO

-- ============================================================
-- 2. BCDT_WorkflowStep - Workflow steps (1-5 levels)
-- ============================================================
CREATE TABLE [dbo].[BCDT_WorkflowStep](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [WorkflowDefinitionId] INT NOT NULL,
    [StepOrder] TINYINT NOT NULL,            -- 1, 2, 3, 4, 5
    [StepName] NVARCHAR(100) NOT NULL,
    [StepDescription] NVARCHAR(500) NULL,
    [ApproverRoleId] INT NULL,               -- Role required to approve
    [ApproverUserId] INT NULL,               -- Specific user (optional)
    [CanReject] BIT NOT NULL DEFAULT 1,
    [CanRequestRevision] BIT NOT NULL DEFAULT 1,
    [AutoApproveAfterDays] INT NULL,         -- Auto-approve if no action
    [NotifyOnPending] BIT NOT NULL DEFAULT 1,
    [NotifyOnApprove] BIT NOT NULL DEFAULT 1,
    [NotifyOnReject] BIT NOT NULL DEFAULT 1,
    [IsActive] BIT NOT NULL DEFAULT 1,
    
    CONSTRAINT [PK_BCDT_WorkflowStep] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WorkflowStep_Definition] FOREIGN KEY ([WorkflowDefinitionId]) REFERENCES [dbo].[BCDT_WorkflowDefinition]([Id]),
    CONSTRAINT [FK_WorkflowStep_Role] FOREIGN KEY ([ApproverRoleId]) REFERENCES [dbo].[BCDT_Role]([Id]),
    CONSTRAINT [FK_WorkflowStep_User] FOREIGN KEY ([ApproverUserId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [UQ_WorkflowStep] UNIQUE NONCLUSTERED ([WorkflowDefinitionId], [StepOrder])
) ON [PRIMARY];
GO

-- ============================================================
-- 3. BCDT_FormWorkflowConfig - Form ↔ Workflow mapping
-- ============================================================
CREATE TABLE [dbo].[BCDT_FormWorkflowConfig](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FormDefinitionId] INT NOT NULL,
    [WorkflowDefinitionId] INT NOT NULL,
    [OrganizationTypeId] INT NULL,           -- Different workflow per org level
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_FormWorkflowConfig] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_FormWorkflow_Form] FOREIGN KEY ([FormDefinitionId]) REFERENCES [dbo].[BCDT_FormDefinition]([Id]),
    CONSTRAINT [FK_FormWorkflow_Workflow] FOREIGN KEY ([WorkflowDefinitionId]) REFERENCES [dbo].[BCDT_WorkflowDefinition]([Id]),
    CONSTRAINT [FK_FormWorkflow_OrgType] FOREIGN KEY ([OrganizationTypeId]) REFERENCES [dbo].[BCDT_OrganizationType]([Id])
) ON [PRIMARY];
GO

-- ============================================================
-- 4. BCDT_WorkflowInstance - Running workflow instances
-- ============================================================
CREATE TABLE [dbo].[BCDT_WorkflowInstance](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [SubmissionId] BIGINT NOT NULL,
    [WorkflowDefinitionId] INT NOT NULL,
    [CurrentStep] TINYINT NOT NULL DEFAULT 1,
    [Status] NVARCHAR(20) NOT NULL DEFAULT 'Pending',  -- Pending, Approved, Rejected, Cancelled
    [StartedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CompletedAt] DATETIME2 NULL,
    [CreatedBy] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_WorkflowInstance] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WorkflowInstance_Submission] FOREIGN KEY ([SubmissionId]) REFERENCES [dbo].[BCDT_ReportSubmission]([Id]),
    CONSTRAINT [FK_WorkflowInstance_Definition] FOREIGN KEY ([WorkflowDefinitionId]) REFERENCES [dbo].[BCDT_WorkflowDefinition]([Id]),
    CONSTRAINT [CK_WorkflowInstance_Status] CHECK ([Status] IN ('Pending', 'Approved', 'Rejected', 'Cancelled'))
) ON [PRIMARY];
GO

CREATE INDEX [IX_WorkflowInstance_Submission] ON [dbo].[BCDT_WorkflowInstance]([SubmissionId]);
CREATE INDEX [IX_WorkflowInstance_Status] ON [dbo].[BCDT_WorkflowInstance]([Status]) WHERE [Status] = 'Pending';
GO

-- ============================================================
-- 5. BCDT_WorkflowApproval - Approval history
-- ============================================================
CREATE TABLE [dbo].[BCDT_WorkflowApproval](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [WorkflowInstanceId] INT NOT NULL,
    [StepOrder] TINYINT NOT NULL,
    [Action] NVARCHAR(20) NOT NULL,          -- Approve, Reject, RequestRevision, Skip
    [Comments] NVARCHAR(2000) NULL,
    [ApproverId] INT NOT NULL,
    [ApprovedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [IpAddress] NVARCHAR(50) NULL,
    [SignatureId] NVARCHAR(32) NULL,         -- Link to document signature
    
    CONSTRAINT [PK_BCDT_WorkflowApproval] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_WorkflowApproval_Instance] FOREIGN KEY ([WorkflowInstanceId]) REFERENCES [dbo].[BCDT_WorkflowInstance]([Id]),
    CONSTRAINT [FK_WorkflowApproval_User] FOREIGN KEY ([ApproverId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [CK_WorkflowApproval_Action] CHECK ([Action] IN ('Approve', 'Reject', 'RequestRevision', 'Skip'))
) ON [PRIMARY];
GO

CREATE INDEX [IX_WorkflowApproval_Instance] ON [dbo].[BCDT_WorkflowApproval]([WorkflowInstanceId]);
CREATE INDEX [IX_WorkflowApproval_Approver] ON [dbo].[BCDT_WorkflowApproval]([ApproverId]);
GO

PRINT N'06.workflow.sql - 5 tables created successfully';
GO
