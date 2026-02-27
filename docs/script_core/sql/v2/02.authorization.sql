-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Authorization (Phân quyền)
-- Version: 2.0
-- Tables: 9
-- ============================================================

-- ============================================================
-- 1. BCDT_Role - Vai trò
-- ============================================================
CREATE TABLE [dbo].[BCDT_Role](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(50) NOT NULL,            -- SYSTEM_ADMIN, FORM_ADMIN, etc.
    [Name] NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500) NULL,
    [Level] INT NOT NULL DEFAULT 0,          -- 0=highest (SystemAdmin), 4=lowest (Viewer)
    [IsSystem] BIT NOT NULL DEFAULT 0,       -- System roles cannot be deleted
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    
    CONSTRAINT [PK_BCDT_Role] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Role_Code] UNIQUE NONCLUSTERED ([Code] ASC)
) ON [PRIMARY];
GO

-- ============================================================
-- 2. BCDT_Permission - Quyền
-- ============================================================
CREATE TABLE [dbo].[BCDT_Permission](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(100) NOT NULL,           -- Form.Create, Submission.Approve, etc.
    [Name] NVARCHAR(200) NOT NULL,
    [Module] NVARCHAR(50) NOT NULL,          -- Form, Submission, Workflow, Report, Admin
    [Action] NVARCHAR(50) NOT NULL,          -- View, Create, Edit, Delete, Approve, Export
    [Description] NVARCHAR(500) NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    
    CONSTRAINT [PK_BCDT_Permission] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_Permission_Code] UNIQUE NONCLUSTERED ([Code] ASC)
) ON [PRIMARY];
GO

CREATE INDEX [IX_Permission_Module] ON [dbo].[BCDT_Permission]([Module]);
GO

-- ============================================================
-- 3. BCDT_RolePermission - Role ↔ Permission mapping
-- ============================================================
CREATE TABLE [dbo].[BCDT_RolePermission](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [RoleId] INT NOT NULL,
    [PermissionId] INT NOT NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    
    CONSTRAINT [PK_BCDT_RolePermission] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_RolePerm_Role] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[BCDT_Role]([Id]),
    CONSTRAINT [FK_RolePerm_Permission] FOREIGN KEY ([PermissionId]) REFERENCES [dbo].[BCDT_Permission]([Id]),
    CONSTRAINT [UQ_RolePermission] UNIQUE NONCLUSTERED ([RoleId], [PermissionId])
) ON [PRIMARY];
GO

-- ============================================================
-- 4. BCDT_UserRole - User ↔ Role mapping (per Organization)
-- ============================================================
CREATE TABLE [dbo].[BCDT_UserRole](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] INT NOT NULL,
    [RoleId] INT NOT NULL,
    [OrganizationId] INT NULL,               -- NULL = all organizations
    [ValidFrom] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [ValidTo] DATETIME2 NULL,                -- NULL = no expiry
    [IsActive] BIT NOT NULL DEFAULT 1,
    [GrantedBy] INT NOT NULL,
    [GrantedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [RevokedBy] INT NULL,
    [RevokedAt] DATETIME2 NULL,
    [RevokedReason] NVARCHAR(500) NULL,
    
    CONSTRAINT [PK_BCDT_UserRole] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_UserRole_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [FK_UserRole_Role] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[BCDT_Role]([Id]),
    CONSTRAINT [FK_UserRole_Org] FOREIGN KEY ([OrganizationId]) REFERENCES [dbo].[BCDT_Organization]([Id])
) ON [PRIMARY];
GO

CREATE INDEX [IX_UserRole_User] ON [dbo].[BCDT_UserRole]([UserId], [IsActive]);
CREATE INDEX [IX_UserRole_Org] ON [dbo].[BCDT_UserRole]([OrganizationId]);
GO

-- ============================================================
-- 5. BCDT_Menu - Menu/Feature hierarchy
-- ============================================================
CREATE TABLE [dbo].[BCDT_Menu](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [ParentId] INT NULL,                     -- Self-reference for hierarchy
    [Url] NVARCHAR(200) NULL,
    [Icon] NVARCHAR(50) NULL,
    [DisplayOrder] INT NOT NULL DEFAULT 0,
    [IsVisible] BIT NOT NULL DEFAULT 1,
    [RequiredPermission] NVARCHAR(100) NULL, -- Permission code required to see this menu
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_BCDT_Menu] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Menu_Parent] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[BCDT_Menu]([Id]),
    CONSTRAINT [UQ_Menu_Code] UNIQUE NONCLUSTERED ([Code] ASC)
) ON [PRIMARY];
GO

-- ============================================================
-- 6. BCDT_RoleMenu - Role ↔ Menu access with CRUD flags
-- ============================================================
CREATE TABLE [dbo].[BCDT_RoleMenu](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [RoleId] INT NOT NULL,
    [MenuId] INT NOT NULL,
    [CanView] BIT NOT NULL DEFAULT 1,
    [CanCreate] BIT NOT NULL DEFAULT 0,
    [CanEdit] BIT NOT NULL DEFAULT 0,
    [CanDelete] BIT NOT NULL DEFAULT 0,
    [CanExport] BIT NOT NULL DEFAULT 0,
    [CanApprove] BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT [PK_BCDT_RoleMenu] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_RoleMenu_Role] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[BCDT_Role]([Id]),
    CONSTRAINT [FK_RoleMenu_Menu] FOREIGN KEY ([MenuId]) REFERENCES [dbo].[BCDT_Menu]([Id]),
    CONSTRAINT [UQ_RoleMenu] UNIQUE NONCLUSTERED ([RoleId], [MenuId])
) ON [PRIMARY];
GO

-- ============================================================
-- 7. BCDT_DataScope - Phạm vi dữ liệu
-- ============================================================
CREATE TABLE [dbo].[BCDT_DataScope](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(100) NOT NULL,
    [ScopeType] NVARCHAR(20) NOT NULL,       -- Own, Organization, Children, All
    [Description] NVARCHAR(500) NULL,
    
    CONSTRAINT [PK_BCDT_DataScope] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_DataScope_Code] UNIQUE NONCLUSTERED ([Code] ASC),
    CONSTRAINT [CK_DataScope_Type] CHECK ([ScopeType] IN ('Own', 'Organization', 'Children', 'All'))
) ON [PRIMARY];
GO

-- ============================================================
-- 8. BCDT_RoleDataScope - Role ↔ DataScope per entity type
-- ============================================================
CREATE TABLE [dbo].[BCDT_RoleDataScope](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [RoleId] INT NOT NULL,
    [EntityType] NVARCHAR(50) NOT NULL,      -- Submission, Report, Organization
    [DataScopeId] INT NOT NULL,
    
    CONSTRAINT [PK_BCDT_RoleDataScope] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_RoleScope_Role] FOREIGN KEY ([RoleId]) REFERENCES [dbo].[BCDT_Role]([Id]),
    CONSTRAINT [FK_RoleScope_Scope] FOREIGN KEY ([DataScopeId]) REFERENCES [dbo].[BCDT_DataScope]([Id]),
    CONSTRAINT [UQ_RoleDataScope] UNIQUE NONCLUSTERED ([RoleId], [EntityType])
) ON [PRIMARY];
GO

-- ============================================================
-- 9. BCDT_UserDelegation - Ủy quyền tạm thời
-- ============================================================
CREATE TABLE [dbo].[BCDT_UserDelegation](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [FromUserId] INT NOT NULL,               -- Người ủy quyền
    [ToUserId] INT NOT NULL,                 -- Người được ủy quyền
    [DelegationType] NVARCHAR(20) NOT NULL,  -- Full, Partial
    [Permissions] NVARCHAR(MAX) NULL,        -- JSON array of permission codes (for Partial)
    [OrganizationId] INT NULL,               -- Scope of delegation
    [Reason] NVARCHAR(500) NULL,
    [ValidFrom] DATETIME2 NOT NULL,
    [ValidTo] DATETIME2 NOT NULL,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [RevokedAt] DATETIME2 NULL,
    [RevokedBy] INT NULL,
    [RevokedReason] NVARCHAR(500) NULL,
    
    CONSTRAINT [PK_BCDT_UserDelegation] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Delegation_From] FOREIGN KEY ([FromUserId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [FK_Delegation_To] FOREIGN KEY ([ToUserId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [FK_Delegation_Org] FOREIGN KEY ([OrganizationId]) REFERENCES [dbo].[BCDT_Organization]([Id]),
    CONSTRAINT [CK_Delegation_Date] CHECK ([ValidTo] > [ValidFrom]),
    CONSTRAINT [CK_Delegation_Type] CHECK ([DelegationType] IN ('Full', 'Partial'))
) ON [PRIMARY];
GO

CREATE INDEX [IX_Delegation_To] ON [dbo].[BCDT_UserDelegation]([ToUserId], [IsActive]);
CREATE INDEX [IX_Delegation_Valid] ON [dbo].[BCDT_UserDelegation]([ValidFrom], [ValidTo]) WHERE [IsActive] = 1;
GO

PRINT N'02.authorization.sql - 9 tables created successfully';
GO
