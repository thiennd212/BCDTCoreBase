-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Organization (Tổ chức)
-- Version: 2.0
-- Tables: 4
-- ============================================================

-- ============================================================
-- 1. BCDT_OrganizationType - Loại đơn vị (5 cấp)
-- ============================================================
CREATE TABLE [dbo].[BCDT_OrganizationType](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(20) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [Level] INT NOT NULL,                    -- 1=Bộ, 2=Tỉnh, 3=Cấp 3, 4=Cấp 4, 5=Cấp 5
    [ParentTypeId] INT NULL,
    [Description] NVARCHAR(500) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    
    CONSTRAINT [PK_BCDT_OrganizationType] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_OrganizationType_Code] UNIQUE NONCLUSTERED ([Code] ASC),
    CONSTRAINT [FK_OrgType_Parent] FOREIGN KEY ([ParentTypeId]) REFERENCES [dbo].[BCDT_OrganizationType]([Id])
) ON [PRIMARY];
GO

-- ============================================================
-- 2. BCDT_Organization - Đơn vị
-- ============================================================
CREATE TABLE [dbo].[BCDT_Organization](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [ShortName] NVARCHAR(100) NULL,
    [OrganizationTypeId] INT NOT NULL,
    [ParentId] INT NULL,
    [TreePath] NVARCHAR(500) NOT NULL,       -- Hierarchical path: /1/5/12/
    [Level] INT NOT NULL,                     -- Depth level in tree
    [Address] NVARCHAR(500) NULL,
    [Phone] NVARCHAR(20) NULL,
    [Email] NVARCHAR(100) NULL,
    [TaxCode] NVARCHAR(20) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [DisplayOrder] INT NOT NULL DEFAULT 0,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    [IsDeleted] BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT [PK_BCDT_Organization] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Organization_Code] UNIQUE NONCLUSTERED ([Code] ASC),
    CONSTRAINT [FK_Org_Type] FOREIGN KEY ([OrganizationTypeId]) REFERENCES [dbo].[BCDT_OrganizationType]([Id]),
    CONSTRAINT [FK_Org_Parent] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[BCDT_Organization]([Id])
) ON [PRIMARY];
GO

-- Index for tree traversal
CREATE INDEX [IX_Organization_TreePath] ON [dbo].[BCDT_Organization]([TreePath]);
CREATE INDEX [IX_Organization_Parent] ON [dbo].[BCDT_Organization]([ParentId]);
CREATE INDEX [IX_Organization_Type] ON [dbo].[BCDT_Organization]([OrganizationTypeId]);
GO

-- ============================================================
-- 3. BCDT_User - Người dùng
-- ============================================================
CREATE TABLE [dbo].[BCDT_User](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Username] NVARCHAR(50) NOT NULL,
    [PasswordHash] NVARCHAR(500) NULL,       -- NULL if using external auth
    [Email] NVARCHAR(100) NOT NULL,
    [FullName] NVARCHAR(200) NOT NULL,
    [Phone] NVARCHAR(20) NULL,
    [Avatar] NVARCHAR(500) NULL,
    
    -- Authentication
    [AuthProvider] NVARCHAR(50) NOT NULL DEFAULT 'BuiltIn',  -- BuiltIn, SSO, LDAP
    [ExternalId] NVARCHAR(255) NULL,         -- ID from external provider
    [LastSyncFromExternalAt] DATETIME2 NULL,
    
    -- Security
    [FailedLoginAttempts] INT NOT NULL DEFAULT 0,
    [LockoutEnd] DATETIME2 NULL,
    [PasswordChangedAt] DATETIME2 NULL,
    [MustChangePassword] BIT NOT NULL DEFAULT 0,
    
    -- 2FA
    [TwoFactorEnabled] BIT NOT NULL DEFAULT 0,
    [TwoFactorProvider] NVARCHAR(20) NULL,   -- TOTP, SMS, Email
    
    -- Status
    [IsActive] BIT NOT NULL DEFAULT 1,
    [LastLoginAt] DATETIME2 NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    [IsDeleted] BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT [PK_BCDT_User] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_User_Username] UNIQUE NONCLUSTERED ([Username] ASC),
    CONSTRAINT [UQ_User_Email] UNIQUE NONCLUSTERED ([Email] ASC)
) ON [PRIMARY];
GO

-- ============================================================
-- 4. BCDT_UserOrganization - User ↔ Organization mapping
-- ============================================================
CREATE TABLE [dbo].[BCDT_UserOrganization](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] INT NOT NULL,
    [OrganizationId] INT NOT NULL,
    [IsPrimary] BIT NOT NULL DEFAULT 0,      -- Primary organization
    [IsActive] BIT NOT NULL DEFAULT 1,
    [JoinedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [LeftAt] DATETIME2 NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    
    CONSTRAINT [PK_BCDT_UserOrganization] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_UserOrg_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [FK_UserOrg_Org] FOREIGN KEY ([OrganizationId]) REFERENCES [dbo].[BCDT_Organization]([Id]),
    CONSTRAINT [UQ_UserOrganization] UNIQUE NONCLUSTERED ([UserId], [OrganizationId])
) ON [PRIMARY];
GO

CREATE INDEX [IX_UserOrg_User] ON [dbo].[BCDT_UserOrganization]([UserId]);
CREATE INDEX [IX_UserOrg_Org] ON [dbo].[BCDT_UserOrganization]([OrganizationId]);
GO

PRINT N'01.organization.sql - 4 tables created successfully';
GO
