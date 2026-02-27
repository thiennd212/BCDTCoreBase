-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Reporting Period (Chu kỳ báo cáo)
-- Version: 2.0
-- Tables: 3
-- ============================================================

-- ============================================================
-- 1. BCDT_ReportingFrequency - Chu kỳ định nghĩa
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReportingFrequency](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(20) NOT NULL,            -- DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY, ADHOC
    [Name] NVARCHAR(100) NOT NULL,
    [NameEn] NVARCHAR(50) NULL,
    [DaysInPeriod] INT NOT NULL,             -- Average days in period
    [CronExpression] NVARCHAR(50) NULL,      -- For auto-generation
    [Description] NVARCHAR(500) NULL,
    [DisplayOrder] INT NOT NULL DEFAULT 0,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_BCDT_ReportingFrequency] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_ReportingFrequency_Code] UNIQUE NONCLUSTERED ([Code] ASC)
) ON [PRIMARY];
GO

-- ============================================================
-- 2. BCDT_ReportingPeriod - Kỳ báo cáo cụ thể
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReportingPeriod](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ReportingFrequencyId] INT NOT NULL,
    [PeriodCode] NVARCHAR(20) NOT NULL,      -- 2026-01, 2026-W05, 2026-Q1
    [PeriodName] NVARCHAR(100) NOT NULL,     -- Tháng 01/2026, Tuần 05/2026
    [Year] INT NOT NULL,
    [Quarter] TINYINT NULL,                  -- 1-4
    [Month] TINYINT NULL,                    -- 1-12
    [Week] TINYINT NULL,                     -- 1-53
    [Day] TINYINT NULL,                      -- 1-31
    [StartDate] DATE NOT NULL,
    [EndDate] DATE NOT NULL,
    [Deadline] DATE NOT NULL,                -- Submission deadline
    [Status] NVARCHAR(20) NOT NULL DEFAULT 'Open',  -- Open, Closed, Archived
    [IsCurrent] BIT NOT NULL DEFAULT 0,
    [IsLocked] BIT NOT NULL DEFAULT 0,
    [LockedAt] DATETIME2 NULL,
    [LockedBy] INT NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    
    CONSTRAINT [PK_BCDT_ReportingPeriod] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Period_Frequency] FOREIGN KEY ([ReportingFrequencyId]) REFERENCES [dbo].[BCDT_ReportingFrequency]([Id]),
    CONSTRAINT [UQ_ReportingPeriod_Code] UNIQUE NONCLUSTERED ([ReportingFrequencyId], [PeriodCode]),
    CONSTRAINT [CK_Period_Date] CHECK ([EndDate] >= [StartDate]),
    CONSTRAINT [CK_Period_Status] CHECK ([Status] IN ('Open', 'Closed', 'Archived'))
) ON [PRIMARY];
GO

CREATE INDEX [IX_Period_Dates] ON [dbo].[BCDT_ReportingPeriod]([StartDate], [EndDate]);
CREATE INDEX [IX_Period_Year] ON [dbo].[BCDT_ReportingPeriod]([Year], [Month]);
CREATE INDEX [IX_Period_Current] ON [dbo].[BCDT_ReportingPeriod]([IsCurrent]) WHERE [IsCurrent] = 1;
GO

-- ============================================================
-- 3. BCDT_ScheduleJob - Background jobs
-- ============================================================
CREATE TABLE [dbo].[BCDT_ScheduleJob](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [JobCode] NVARCHAR(50) NOT NULL,
    [JobName] NVARCHAR(200) NOT NULL,
    [JobType] NVARCHAR(50) NOT NULL,         -- CreatePeriod, SendReminder, CloseSubmission, Aggregate
    [CronExpression] NVARCHAR(50) NOT NULL,  -- Cron schedule
    [FormDefinitionId] INT NULL,             -- NULL = all forms
    [ReportingFrequencyId] INT NULL,
    [Parameters] NVARCHAR(MAX) NULL,         -- JSON parameters
    [IsActive] BIT NOT NULL DEFAULT 1,
    [LastRunAt] DATETIME2 NULL,
    [LastRunStatus] NVARCHAR(20) NULL,       -- Success, Failed
    [LastRunMessage] NVARCHAR(1000) NULL,
    [NextRunAt] DATETIME2 NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    
    CONSTRAINT [PK_BCDT_ScheduleJob] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_ScheduleJob_Code] UNIQUE NONCLUSTERED ([JobCode] ASC),
    CONSTRAINT [FK_ScheduleJob_Form] FOREIGN KEY ([FormDefinitionId]) REFERENCES [dbo].[BCDT_FormDefinition]([Id]),
    CONSTRAINT [FK_ScheduleJob_Frequency] FOREIGN KEY ([ReportingFrequencyId]) REFERENCES [dbo].[BCDT_ReportingFrequency]([Id])
) ON [PRIMARY];
GO

-- Job execution history (optional, for audit)
CREATE TABLE [dbo].[BCDT_ScheduleJobHistory](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [ScheduleJobId] INT NOT NULL,
    [StartedAt] DATETIME2 NOT NULL,
    [CompletedAt] DATETIME2 NULL,
    [Status] NVARCHAR(20) NOT NULL,          -- Running, Success, Failed
    [Message] NVARCHAR(MAX) NULL,
    [RecordsProcessed] INT NULL,
    
    CONSTRAINT [PK_BCDT_ScheduleJobHistory] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_JobHistory_Job] FOREIGN KEY ([ScheduleJobId]) REFERENCES [dbo].[BCDT_ScheduleJob]([Id])
) ON [PRIMARY];
GO

CREATE INDEX [IX_JobHistory_Job] ON [dbo].[BCDT_ScheduleJobHistory]([ScheduleJobId], [StartedAt] DESC);
GO

PRINT N'07.reporting_period.sql - 3 tables created successfully';
GO
