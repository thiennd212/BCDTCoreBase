-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Reference Data (Dữ liệu tham chiếu - EAV Pattern)
-- Version: 2.0
-- Tables: 3
-- ============================================================

-- ============================================================
-- 1. BCDT_ReferenceEntityType - Entity type definitions
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReferenceEntityType](
    [Id] INT IDENTITY(1,1) NOT NULL,
    [Code] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(200) NOT NULL,
    [Description] NVARCHAR(1000) NULL,
    [TableName] NVARCHAR(100) NULL,          -- For DB-backed entities
    [ApiEndpoint] NVARCHAR(500) NULL,        -- For API-backed entities
    [DisplayTemplate] NVARCHAR(500) NULL,    -- How to display entity: "{Code} - {Name}"
    [SearchColumns] NVARCHAR(500) NULL,      -- Columns to search: "Code,Name,Description"
    [OrderByColumn] NVARCHAR(100) NULL,      -- Default order column
    [IsSystem] BIT NOT NULL DEFAULT 0,       -- System entities cannot be deleted
    [IsActive] BIT NOT NULL DEFAULT 1,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    
    CONSTRAINT [PK_BCDT_ReferenceEntityType] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [UQ_ReferenceEntityType_Code] UNIQUE NONCLUSTERED ([Code] ASC)
) ON [PRIMARY];
GO

-- ============================================================
-- 2. BCDT_ReferenceEntity - Dynamic entities (EAV rows)
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReferenceEntity](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [EntityTypeId] INT NOT NULL,
    [Code] NVARCHAR(50) NOT NULL,
    [Name] NVARCHAR(500) NOT NULL,
    [ParentId] BIGINT NULL,                  -- For hierarchical entities
    [OrganizationId] INT NULL,               -- Entity belongs to organization
    [DisplayOrder] INT NOT NULL DEFAULT 0,
    [IsActive] BIT NOT NULL DEFAULT 1,
    [ValidFrom] DATE NULL,
    [ValidTo] DATE NULL,
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [CreatedBy] INT NOT NULL DEFAULT -1,
    [UpdatedAt] DATETIME2 NULL,
    [UpdatedBy] INT NULL,
    [IsDeleted] BIT NOT NULL DEFAULT 0,
    
    CONSTRAINT [PK_BCDT_ReferenceEntity] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_ReferenceEntity_Type] FOREIGN KEY ([EntityTypeId]) REFERENCES [dbo].[BCDT_ReferenceEntityType]([Id]),
    CONSTRAINT [FK_ReferenceEntity_Parent] FOREIGN KEY ([ParentId]) REFERENCES [dbo].[BCDT_ReferenceEntity]([Id]),
    CONSTRAINT [FK_ReferenceEntity_Org] FOREIGN KEY ([OrganizationId]) REFERENCES [dbo].[BCDT_Organization]([Id]),
    CONSTRAINT [UQ_ReferenceEntity_Code] UNIQUE NONCLUSTERED ([EntityTypeId], [Code])
) ON [PRIMARY];
GO

CREATE INDEX [IX_ReferenceEntity_Type] ON [dbo].[BCDT_ReferenceEntity]([EntityTypeId], [IsActive]);
CREATE INDEX [IX_ReferenceEntity_Org] ON [dbo].[BCDT_ReferenceEntity]([OrganizationId]) WHERE [OrganizationId] IS NOT NULL;
CREATE INDEX [IX_ReferenceEntity_Parent] ON [dbo].[BCDT_ReferenceEntity]([ParentId]) WHERE [ParentId] IS NOT NULL;
GO

-- ============================================================
-- 3. BCDT_ReferenceEntityAttribute - EAV attributes
-- ============================================================
CREATE TABLE [dbo].[BCDT_ReferenceEntityAttribute](
    [Id] BIGINT IDENTITY(1,1) NOT NULL,
    [EntityId] BIGINT NOT NULL,
    [AttributeName] NVARCHAR(100) NOT NULL,
    [AttributeType] NVARCHAR(20) NOT NULL,   -- String, Number, Date, Boolean, Json
    
    -- Value columns (use appropriate based on AttributeType)
    [StringValue] NVARCHAR(MAX) NULL,
    [NumberValue] DECIMAL(18,4) NULL,
    [DateValue] DATE NULL,
    [BooleanValue] BIT NULL,
    
    [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
    [UpdatedAt] DATETIME2 NULL,
    
    CONSTRAINT [PK_BCDT_ReferenceEntityAttribute] PRIMARY KEY CLUSTERED ([Id] ASC),
    CONSTRAINT [FK_EntityAttribute_Entity] FOREIGN KEY ([EntityId]) REFERENCES [dbo].[BCDT_ReferenceEntity]([Id]),
    CONSTRAINT [UQ_EntityAttribute] UNIQUE NONCLUSTERED ([EntityId], [AttributeName]),
    CONSTRAINT [CK_EntityAttribute_Type] CHECK ([AttributeType] IN ('String', 'Number', 'Date', 'Boolean', 'Json'))
) ON [PRIMARY];
GO

CREATE INDEX [IX_EntityAttribute_Entity] ON [dbo].[BCDT_ReferenceEntityAttribute]([EntityId]);
GO

PRINT N'09.reference_data.sql - 3 tables created successfully';
GO
