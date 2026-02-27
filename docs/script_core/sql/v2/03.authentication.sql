-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Authentication (Xác thực)
-- Version: 2.0
-- Tables: 5
-- ============================================================

-- ============================================================
-- 1. BCDT_AuthProvider - Cấu hình Authentication Provider
-- ============================================================
CREATE TABLE [dbo].[BCDT_AuthProvider](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ProviderType] NVARCHAR(50) NOT NULL,    -- BuiltIn, SSO, LDAP
    [Name] NVARCHAR(100) NOT NULL,
    [IsEnabled] BIT NOT NULL DEFAULT 0,
    [Priority] INT NOT NULL DEFAULT 100,     -- Lower = higher priority
    [Settings] NVARCHAR(MAX) NULL,           -- JSON configuration
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [UpdatedAt] DATETIME2 NULL,
    
    CONSTRAINT [PK_BCDT_AuthProvider] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_AuthProvider_Type] UNIQUE NONCLUSTERED ([ProviderType] ASC)
) ON [PRIMARY];
GO

-- ============================================================
-- 2. BCDT_UserExternalIdentity - SSO/LDAP identity links
-- ============================================================
CREATE TABLE [dbo].[BCDT_UserExternalIdentity](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] INT NOT NULL,
    [ProviderType] NVARCHAR(50) NOT NULL,
    [ExternalId] NVARCHAR(255) NOT NULL,     -- ID from external provider
    [ExternalUsername] NVARCHAR(255) NULL,
    [ExternalEmail] NVARCHAR(255) NULL,
    [Metadata] NVARCHAR(MAX) NULL,           -- JSON: additional claims
    [LinkedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [LastSyncAt] DATETIME2 NULL,
    
    CONSTRAINT [PK_BCDT_UserExternalIdentity] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ExtIdentity_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [UQ_ExtIdentity] UNIQUE NONCLUSTERED ([ProviderType], [ExternalId])
) ON [PRIMARY];
GO

CREATE INDEX [IX_ExtIdentity_User] ON [dbo].[BCDT_UserExternalIdentity]([UserId]);
GO

-- ============================================================
-- 3. BCDT_TwoFactorProvider - 2FA Provider configuration
-- ============================================================
CREATE TABLE [dbo].[BCDT_TwoFactorProvider](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ProviderType] NVARCHAR(20) NOT NULL,    -- TOTP, SMS, Email
    [Name] NVARCHAR(100) NOT NULL,
    [IsEnabled] BIT NOT NULL DEFAULT 0,
    [Settings] NVARCHAR(MAX) NULL,           -- JSON configuration
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [UpdatedAt] DATETIME2 NULL,
    
    CONSTRAINT [PK_BCDT_TwoFactorProvider] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_2FAProvider_Type] UNIQUE NONCLUSTERED ([ProviderType] ASC)
) ON [PRIMARY];
GO

-- ============================================================
-- 4. BCDT_UserTwoFactor - User 2FA configuration
-- ============================================================
CREATE TABLE [dbo].[BCDT_UserTwoFactor](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] INT NOT NULL,
    [ProviderType] NVARCHAR(20) NOT NULL,
    [SecretEncrypted] VARBINARY(MAX) NOT NULL,  -- Encrypted secret key
    [IsEnabled] BIT NOT NULL DEFAULT 0,
    [EnabledAt] DATETIME2 NULL,
    [LastUsedAt] DATETIME2 NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_BCDT_UserTwoFactor] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_User2FA_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [UQ_User2FA] UNIQUE NONCLUSTERED ([UserId], [ProviderType])
) ON [PRIMARY];
GO

-- ============================================================
-- 5. BCDT_UserBackupCode - 2FA Backup codes
-- ============================================================
CREATE TABLE [dbo].[BCDT_UserBackupCode](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] INT NOT NULL,
    [CodeHash] NVARCHAR(128) NOT NULL,       -- Hashed backup code
    [IsUsed] BIT NOT NULL DEFAULT 0,
    [UsedAt] DATETIME2 NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    
    CONSTRAINT [PK_BCDT_UserBackupCode] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_BackupCode_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[BCDT_User]([Id])
) ON [PRIMARY];
GO

CREATE INDEX [IX_BackupCode_User] ON [dbo].[BCDT_UserBackupCode]([UserId]) WHERE [IsUsed] = 0;
GO

-- ============================================================
-- RefreshToken table for JWT refresh
-- ============================================================
CREATE TABLE [dbo].[BCDT_RefreshToken](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [UserId] INT NOT NULL,
    [Token] NVARCHAR(500) NOT NULL,
    [ExpiresAt] DATETIME2 NOT NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedByIp] NVARCHAR(50) NULL,
    [RevokedAt] DATETIME2 NULL,
    [RevokedByIp] NVARCHAR(50) NULL,
    [ReplacedByToken] NVARCHAR(500) NULL,
    
    CONSTRAINT [PK_BCDT_RefreshToken] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_RefreshToken_User] FOREIGN KEY ([UserId]) REFERENCES [dbo].[BCDT_User]([Id])
) ON [PRIMARY];
GO

CREATE INDEX [IX_RefreshToken_User] ON [dbo].[BCDT_RefreshToken]([UserId]);
CREATE INDEX [IX_RefreshToken_Token] ON [dbo].[BCDT_RefreshToken]([Token]);
GO

PRINT N'03.authentication.sql - 5 tables created successfully';
GO
