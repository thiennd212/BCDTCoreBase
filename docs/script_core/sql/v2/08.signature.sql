-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Digital Signature (Chữ ký số)
-- Version: 2.0
-- Tables: 2
-- ============================================================

-- ============================================================
-- 1. BCDT_SignatureProvider - Signature provider configuration
-- ============================================================
CREATE TABLE [dbo].[BCDT_SignatureProvider](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [ProviderType] NVARCHAR(20) NOT NULL,    -- Audit, Simple, VGCA
    [Name] NVARCHAR(100) NOT NULL,
    [IsEnabled] BIT NOT NULL DEFAULT 0,
    [RequiresHardwareToken] BIT NOT NULL DEFAULT 0,
    [Settings] NVARCHAR(MAX) NULL,           -- JSON configuration
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [UpdatedAt] DATETIME2 NULL,
    
    CONSTRAINT [PK_BCDT_SignatureProvider] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_SignatureProvider_Type] UNIQUE NONCLUSTERED ([ProviderType] ASC),
    CONSTRAINT [CK_SignatureProvider_Type] CHECK ([ProviderType] IN ('Audit', 'Simple', 'VGCA'))
) ON [PRIMARY];
GO

-- ============================================================
-- 2. BCDT_DocumentSignature - Document signatures
-- ============================================================
CREATE TABLE [dbo].[BCDT_DocumentSignature](
    [Id] NVARCHAR(32) NOT NULL,              -- GUID without dashes
    [DocumentId] NVARCHAR(50) NOT NULL,      -- SubmissionId or other document
    [DocumentType] NVARCHAR(50) NOT NULL DEFAULT 'Submission',
    [SignerId] INT NOT NULL,
    [SignerRole] NVARCHAR(50) NOT NULL,
    [SignatureType] NVARCHAR(20) NOT NULL,   -- Approval, Simple, Digital, VGCA
    
    -- Audit-based signature fields (MVP)
    [DocumentHashAtSigning] NVARCHAR(100) NULL,  -- SHA256 hash of document
    
    -- PKI/VGCA signature fields (Future)
    [SignatureData] VARBINARY(MAX) NULL,     -- PKCS#7 signature blob
    [CertificateSubject] NVARCHAR(500) NULL,
    [CertificateIssuer] NVARCHAR(500) NULL,
    [CertificateSerialNumber] NVARCHAR(100) NULL,
    [CertificateValidFrom] DATETIME2 NULL,
    [CertificateValidTo] DATETIME2 NULL,
    
    -- Timestamp (for VGCA compliance)
    [TimestampToken] VARBINARY(MAX) NULL,
    [TimestampAuthority] NVARCHAR(200) NULL,
    [TimestampedAt] DATETIME2 NULL,
    
    -- Metadata
    [SignedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [IpAddress] NVARCHAR(50) NULL,
    [UserAgent] NVARCHAR(500) NULL,
    [Comments] NVARCHAR(1000) NULL,
    
    -- Revocation
    [IsRevoked] BIT NOT NULL DEFAULT 0,
    [RevokedAt] DATETIME2 NULL,
    [RevokedBy] INT NULL,
    [RevokedReason] NVARCHAR(500) NULL,
    
    CONSTRAINT [PK_BCDT_DocumentSignature] PRIMARY KEY NONCLUSTERED ([Id] ASC),
    CONSTRAINT [FK_Signature_Signer] FOREIGN KEY ([SignerId]) REFERENCES [dbo].[BCDT_User]([Id]),
    CONSTRAINT [CK_Signature_Type] CHECK ([SignatureType] IN ('Approval', 'Simple', 'Digital', 'VGCA'))
) ON [PRIMARY];
GO

-- Clustered index for chronological access
CREATE CLUSTERED INDEX [CIX_Signature_Date] ON [dbo].[BCDT_DocumentSignature]([SignedAt] DESC);
CREATE INDEX [IX_Signature_Document] ON [dbo].[BCDT_DocumentSignature]([DocumentId], [DocumentType]);
CREATE INDEX [IX_Signature_Signer] ON [dbo].[BCDT_DocumentSignature]([SignerId]);
GO

PRINT N'08.signature.sql - 2 tables created successfully';
GO
