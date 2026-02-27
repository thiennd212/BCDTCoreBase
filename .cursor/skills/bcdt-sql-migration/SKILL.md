---
name: bcdt-sql-migration
description: Create SQL migration scripts for BCDT database changes. Handles new tables, columns, indexes, and constraints following project conventions. Use when user says "thêm bảng", "thêm cột", "tạo migration", "alter table", or wants to modify database schema.
---

# BCDT SQL Migration Generator

Create SQL migration scripts following project conventions.

## Workflow

1. **Gather requirements**:
   - Change type: New table, Add column, Add index, Modify column
   - Table name (with BCDT_ prefix)
   - Column details (name, type, nullable, default)
   - Foreign keys and constraints

2. **Generate SQL script**:

### New Table
```sql
-- ============================================================
-- Migration: Add BCDT_{TableName}
-- Date: {YYYY-MM-DD}
-- Author: {Author}
-- Description: {Description}
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.tables WHERE name = 'BCDT_{TableName}')
BEGIN
    CREATE TABLE [dbo].[BCDT_{TableName}](
        [Id] INT IDENTITY(1,1) NOT NULL,
        [Code] NVARCHAR(50) NOT NULL,
        [Name] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(1000) NULL,
        
        -- Foreign keys
        [OrganizationId] INT NOT NULL,
        
        -- Audit columns (required)
        [IsActive] BIT NOT NULL DEFAULT 1,
        [CreatedAt] DATETIME2 NOT NULL DEFAULT GETDATE(),
        [CreatedBy] INT NOT NULL,
        [UpdatedAt] DATETIME2 NULL,
        [UpdatedBy] INT NULL,
        [IsDeleted] BIT NOT NULL DEFAULT 0,
        
        CONSTRAINT [PK_BCDT_{TableName}] PRIMARY KEY CLUSTERED ([Id] ASC),
        CONSTRAINT [UQ_{TableName}_Code] UNIQUE NONCLUSTERED ([Code] ASC),
        CONSTRAINT [FK_{TableName}_Organization] FOREIGN KEY ([OrganizationId]) 
            REFERENCES [dbo].[BCDT_Organization]([Id])
    ) ON [PRIMARY];
    
    -- Indexes
    CREATE INDEX [IX_{TableName}_Organization] ON [dbo].[BCDT_{TableName}]([OrganizationId]);
    CREATE INDEX [IX_{TableName}_Active] ON [dbo].[BCDT_{TableName}]([IsActive]) 
        WHERE [IsDeleted] = 0;
    
    PRINT N'Table BCDT_{TableName} created successfully';
END
GO
```

### Add Column
```sql
-- ============================================================
-- Migration: Add {ColumnName} to BCDT_{TableName}
-- Date: {YYYY-MM-DD}
-- ============================================================

IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('BCDT_{TableName}') AND name = '{ColumnName}'
)
BEGIN
    ALTER TABLE [dbo].[BCDT_{TableName}]
    ADD [{ColumnName}] {DataType} {NULL/NOT NULL} {DEFAULT value};
    
    PRINT N'Column {ColumnName} added to BCDT_{TableName}';
END
GO

-- Add index if needed
IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_{TableName}_{ColumnName}')
BEGIN
    CREATE INDEX [IX_{TableName}_{ColumnName}] 
    ON [dbo].[BCDT_{TableName}]([{ColumnName}]);
END
GO
```

### Add Foreign Key
```sql
-- ============================================================
-- Migration: Add FK from BCDT_{TableName} to BCDT_{RefTable}
-- Date: {YYYY-MM-DD}
-- ============================================================

-- Add column if not exists
IF NOT EXISTS (
    SELECT * FROM sys.columns 
    WHERE object_id = OBJECT_ID('BCDT_{TableName}') AND name = '{RefTable}Id'
)
BEGIN
    ALTER TABLE [dbo].[BCDT_{TableName}]
    ADD [{RefTable}Id] INT NULL;
END
GO

-- Add foreign key
IF NOT EXISTS (
    SELECT * FROM sys.foreign_keys 
    WHERE name = 'FK_{TableName}_{RefTable}'
)
BEGIN
    ALTER TABLE [dbo].[BCDT_{TableName}]
    ADD CONSTRAINT [FK_{TableName}_{RefTable}] 
    FOREIGN KEY ([{RefTable}Id]) REFERENCES [dbo].[BCDT_{RefTable}]([Id]);
    
    CREATE INDEX [IX_{TableName}_{RefTable}] 
    ON [dbo].[BCDT_{TableName}]([{RefTable}Id]);
END
GO
```

### Add Index
```sql
-- ============================================================
-- Migration: Add index on BCDT_{TableName}
-- Date: {YYYY-MM-DD}
-- ============================================================

IF NOT EXISTS (SELECT * FROM sys.indexes WHERE name = 'IX_{TableName}_{Columns}')
BEGIN
    CREATE {NONCLUSTERED/CLUSTERED} INDEX [IX_{TableName}_{Columns}]
    ON [dbo].[BCDT_{TableName}]([{Column1}], [{Column2}])
    INCLUDE ([{IncludeColumn}])
    WHERE [{FilterColumn}] = {Value};  -- Optional filtered index
END
GO
```

### Modify Column
```sql
-- ============================================================
-- Migration: Modify {ColumnName} in BCDT_{TableName}
-- Date: {YYYY-MM-DD}
-- ============================================================

-- Drop dependent constraints first
IF EXISTS (SELECT * FROM sys.default_constraints WHERE name = 'DF_{TableName}_{ColumnName}')
    ALTER TABLE [dbo].[BCDT_{TableName}] DROP CONSTRAINT [DF_{TableName}_{ColumnName}];

-- Alter column
ALTER TABLE [dbo].[BCDT_{TableName}]
ALTER COLUMN [{ColumnName}] {NewDataType} {NULL/NOT NULL};

-- Re-add default if needed
ALTER TABLE [dbo].[BCDT_{TableName}]
ADD CONSTRAINT [DF_{TableName}_{ColumnName}] DEFAULT ({DefaultValue}) FOR [{ColumnName}];
GO
```

## Naming Conventions

| Object | Pattern | Example |
|--------|---------|---------|
| Table | `BCDT_{Entity}` | `BCDT_FormDefinition` |
| PK | `PK_BCDT_{Entity}` | `PK_BCDT_FormDefinition` |
| FK | `FK_{Table}_{RefTable}` | `FK_FormColumn_FormSheet` |
| UQ | `UQ_{Table}_{Column}` | `UQ_Form_Code` |
| IX | `IX_{Table}_{Columns}` | `IX_Submission_Org_Period` |
| DF | `DF_{Table}_{Column}` | `DF_User_IsActive` |
| CK | `CK_{Table}_{Rule}` | `CK_Period_DateRange` |

## Data Types Reference

| Use Case | SQL Type |
|----------|----------|
| ID (small table) | `INT IDENTITY(1,1)` |
| ID (large table) | `BIGINT IDENTITY(1,1)` |
| Short text | `NVARCHAR(50/100/200)` |
| Long text | `NVARCHAR(MAX)` |
| Money | `DECIMAL(18,4)` |
| Boolean | `BIT` |
| Date only | `DATE` |
| DateTime | `DATETIME2` |
| JSON | `NVARCHAR(MAX)` |
| Binary | `VARBINARY(MAX)` |

## Checklist
- [ ] Idempotent (IF NOT EXISTS)
- [ ] BCDT_ prefix on table names
- [ ] Required audit columns
- [ ] Foreign key indexes
- [ ] Naming conventions followed
- [ ] PRINT statement for confirmation
