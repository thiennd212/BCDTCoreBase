-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Notification (Thông báo)
-- Version: 2.0
-- Tables: 1
-- ============================================================

-- ============================================================
-- 1. BCDT_Notification - User notifications
-- ============================================================
CREATE TABLE [dbo].[BCDT_Notification](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [UserId] INT NOT NULL,
    [Type] NVARCHAR(50) NOT NULL,            -- Deadline, Approval, Rejection, Reminder, System
    [Title] NVARCHAR(200) NOT NULL,
    [Message] NVARCHAR(2000) NOT NULL,
    [Priority] NVARCHAR(20) NOT NULL DEFAULT 'Normal',  -- Low, Normal, High, Urgent
    
    -- Reference
    [EntityType] NVARCHAR(50) NULL,          -- Submission, Form, Workflow
    [EntityId] NVARCHAR(50) NULL,            -- Reference ID
    [ActionUrl] NVARCHAR(500) NULL,          -- URL to navigate
    
    -- Delivery
    [Channels] NVARCHAR(100) NOT NULL DEFAULT 'InApp',  -- InApp, Email, SMS (comma-separated)
    [EmailSentAt] DATETIME2 NULL,
    [SmsSentAt] DATETIME2 NULL,
    
    -- Status
    [IsRead] BIT NOT NULL DEFAULT 0,
    [ReadAt] DATETIME2 NULL,
    [IsDismissed] BIT NOT NULL DEFAULT 0,
    [DismissedAt] DATETIME2 NULL,
    
    -- Audit
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [ExpiresAt] DATETIME2 NULL,              -- Auto-dismiss after
    
    CONSTRAINT [PK_BCDT_Notification] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Notification_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [CK_Notification_Type] CHECK ([Type] IN ('Deadline', 'Approval', 'Rejection', 'Reminder', 'Revision', 'System')),
    CONSTRAINT [CK_Notification_Priority] CHECK ([Priority] IN ('Low', 'Normal', 'High', 'Urgent'))
) ON [PRIMARY];
GO

-- Indexes for common queries
CREATE INDEX [IX_Notification_User_Unread] ON [dbo].[BCDT_Notification]([UserId], [CreatedAt] DESC) 
    WHERE [IsRead] = 0 AND [IsDismissed] = 0;
CREATE INDEX [IX_Notification_User_All] ON [dbo].[BCDT_Notification]([UserId], [CreatedAt] DESC);
CREATE INDEX [IX_Notification_Entity] ON [dbo].[BCDT_Notification]([EntityType], [EntityId]) 
    WHERE [EntityType] IS NOT NULL;
GO

-- ============================================================
-- System Configuration table
-- ============================================================
CREATE TABLE [dbo].[BCDT_SystemConfig](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ConfigKey] NVARCHAR(100) NOT NULL,
    [ConfigValue] NVARCHAR(MAX) NOT NULL,
    [DataType] NVARCHAR(20) NOT NULL DEFAULT 'String',  -- String, Number, Boolean, Json
    [Description] NVARCHAR(500) NULL,
    [IsEncrypted] BIT NOT NULL DEFAULT 0,
    [UpdatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [UpdatedBy] INT NULL,
    
    CONSTRAINT [PK_BCDT_SystemConfig] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_SystemConfig_Key] UNIQUE NONCLUSTERED ([ConfigKey] ASC)
) ON [PRIMARY];
GO

-- ============================================================
-- Audit Log table
-- ============================================================
CREATE TABLE [dbo].[BCDT_AuditLog](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [UserId] INT NULL,
    [Action] NVARCHAR(50) NOT NULL,          -- Login, Logout, Create, Update, Delete, View, Export, etc.
    [EntityType] NVARCHAR(50) NOT NULL,
    [EntityId] NVARCHAR(50) NULL,
    [OldValues] NVARCHAR(MAX) NULL,          -- JSON
    [NewValues] NVARCHAR(MAX) NULL,          -- JSON
    [IpAddress] NVARCHAR(50) NULL,
    [UserAgent] NVARCHAR(500) NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_BCDT_AuditLog] PRIMARY KEY CLUSTERED ([Id] ASC)
) ON [PRIMARY];
GO

CREATE INDEX [IX_AuditLog_User] ON [dbo].[BCDT_AuditLog]([UserId], [CreatedAt] DESC);
CREATE INDEX [IX_AuditLog_Entity] ON [dbo].[BCDT_AuditLog]([EntityType], [EntityId]);
CREATE INDEX [IX_AuditLog_Date] ON [dbo].[BCDT_AuditLog]([CreatedAt] DESC);
GO

PRINT N'10.notification.sql - 3 tables created successfully';
GO
