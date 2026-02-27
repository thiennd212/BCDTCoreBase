-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Functions (Các hàm hệ thống)
-- Version: 2.0
-- ============================================================

-- ============================================================
-- AUTHORIZATION FUNCTIONS
-- ============================================================

-- Check if user has specific permission
CREATE OR ALTER FUNCTION [dbo].[fn_HasPermission](
    @UserId INT,
    @PermissionCode NVARCHAR(100),
    @OrganizationId INT = NULL
)
RETURNS BIT
AS
BEGIN
    DECLARE @HasPermission BIT = 0;
    
    -- Check direct permissions from roles
    IF EXISTS (
        SELECT 1 
        FROM [dbo].[BCDT_UserRole] ur
        INNER JOIN [dbo].[BCDT_RolePermission] rp ON ur.RoleId = rp.RoleId
        INNER JOIN [dbo].[BCDT_Permission] p ON rp.PermissionId = p.Id
        WHERE ur.UserId = @UserId
          AND ur.IsActive = 1
          AND (ur.ValidTo IS NULL OR ur.ValidTo > GETDATE())
          AND (ur.OrganizationId IS NULL OR ur.OrganizationId = @OrganizationId OR @OrganizationId IS NULL)
          AND p.Code = @PermissionCode
          AND p.IsActive = 1
    )
    BEGIN
        SET @HasPermission = 1;
    END
    
    -- Check delegated permissions
    IF @HasPermission = 0
    BEGIN
        IF EXISTS (
            SELECT 1
            FROM [dbo].[BCDT_UserDelegation] d
            WHERE d.ToUserId = @UserId
              AND d.IsActive = 1
              AND GETDATE() BETWEEN d.ValidFrom AND d.ValidTo
              AND (d.OrganizationId IS NULL OR d.OrganizationId = @OrganizationId OR @OrganizationId IS NULL)
              AND (
                  d.DelegationType = 'Full' 
                  OR @PermissionCode IN (SELECT value FROM OPENJSON(d.Permissions))
              )
        )
        BEGIN
            SET @HasPermission = 1;
        END
    END
    
    RETURN @HasPermission;
END;
GO

-- Get all effective permissions for a user
CREATE OR ALTER FUNCTION [dbo].[fn_GetUserPermissions](
    @UserId INT
)
RETURNS TABLE
AS
RETURN
(
    -- Direct permissions from roles
    SELECT DISTINCT 
        p.Code,
        p.Module,
        p.[Action],
        ur.OrganizationId
    FROM [dbo].[BCDT_UserRole] ur
    INNER JOIN [dbo].[BCDT_RolePermission] rp ON ur.RoleId = rp.RoleId
    INNER JOIN [dbo].[BCDT_Permission] p ON rp.PermissionId = p.Id
    WHERE ur.UserId = @UserId
      AND ur.IsActive = 1
      AND (ur.ValidTo IS NULL OR ur.ValidTo > GETDATE())
      AND p.IsActive = 1
    
    UNION
    
    -- Delegated permissions (Full delegation)
    SELECT DISTINCT
        p.Code,
        p.Module,
        p.[Action],
        d.OrganizationId
    FROM [dbo].[BCDT_UserDelegation] d
    CROSS JOIN [dbo].[BCDT_Permission] p
    WHERE d.ToUserId = @UserId
      AND d.IsActive = 1
      AND GETDATE() BETWEEN d.ValidFrom AND d.ValidTo
      AND d.DelegationType = 'Full'
      AND p.IsActive = 1
);
GO

-- Get accessible organization IDs for a user
CREATE OR ALTER FUNCTION [dbo].[fn_GetAccessibleOrganizations](
    @UserId INT,
    @EntityType NVARCHAR(50) = 'Submission'
)
RETURNS TABLE
AS
RETURN
(
    WITH UserScopes AS (
        SELECT DISTINCT 
            uo.OrganizationId,
            ds.ScopeType
        FROM [dbo].[BCDT_UserOrganization] uo
        INNER JOIN [dbo].[BCDT_UserRole] ur ON uo.UserId = ur.UserId
        INNER JOIN [dbo].[BCDT_RoleDataScope] rds ON ur.RoleId = rds.RoleId
        INNER JOIN [dbo].[BCDT_DataScope] ds ON rds.DataScopeId = ds.Id
        WHERE uo.UserId = @UserId
          AND uo.IsActive = 1
          AND ur.IsActive = 1
          AND (ur.ValidTo IS NULL OR ur.ValidTo > GETDATE())
          AND rds.EntityType = @EntityType
    ),
    AccessibleOrgs AS (
        -- Scope: All (SystemAdmin, FormAdmin)
        SELECT o.Id AS OrganizationId
        FROM [dbo].[BCDT_Organization] o
        WHERE EXISTS (SELECT 1 FROM UserScopes WHERE ScopeType = 'All')
          AND o.IsActive = 1
        
        UNION
        
        -- Scope: Organization (own org only)
        SELECT us.OrganizationId
        FROM UserScopes us
        WHERE us.ScopeType = 'Organization'
          AND us.OrganizationId IS NOT NULL
        
        UNION
        
        -- Scope: Children (org + all descendants)
        SELECT child.Id
        FROM UserScopes us
        INNER JOIN [dbo].[BCDT_Organization] parent ON us.OrganizationId = parent.Id
        INNER JOIN [dbo].[BCDT_Organization] child ON child.TreePath LIKE parent.TreePath + '%'
        WHERE us.ScopeType = 'Children'
          AND child.IsActive = 1
    )
    SELECT DISTINCT OrganizationId FROM AccessibleOrgs
);
GO

-- ============================================================
-- UTILITY FUNCTIONS
-- ============================================================

-- Generate organization tree path
CREATE OR ALTER FUNCTION [dbo].[fn_GetOrganizationTreePath](
    @OrganizationId INT
)
RETURNS NVARCHAR(500)
AS
BEGIN
    DECLARE @TreePath NVARCHAR(500);
    
    ;WITH OrgHierarchy AS (
        SELECT Id, ParentId, CAST('/' + CAST(Id AS NVARCHAR(10)) + '/' AS NVARCHAR(500)) AS TreePath
        FROM [dbo].[BCDT_Organization]
        WHERE ParentId IS NULL
        
        UNION ALL
        
        SELECT o.Id, o.ParentId, CAST(h.TreePath + CAST(o.Id AS NVARCHAR(10)) + '/' AS NVARCHAR(500))
        FROM [dbo].[BCDT_Organization] o
        INNER JOIN OrgHierarchy h ON o.ParentId = h.Id
    )
    SELECT @TreePath = TreePath
    FROM OrgHierarchy
    WHERE Id = @OrganizationId;
    
    RETURN @TreePath;
END;
GO

-- Get reporting period code based on frequency and date
CREATE OR ALTER FUNCTION [dbo].[fn_GetPeriodCode](
    @FrequencyCode NVARCHAR(20),
    @Date DATE
)
RETURNS NVARCHAR(20)
AS
BEGIN
    DECLARE @PeriodCode NVARCHAR(20);
    
    SET @PeriodCode = CASE @FrequencyCode
        WHEN 'DAILY' THEN FORMAT(@Date, 'yyyy-MM-dd')
        WHEN 'WEEKLY' THEN FORMAT(@Date, 'yyyy') + '-W' + RIGHT('0' + CAST(DATEPART(WEEK, @Date) AS VARCHAR(2)), 2)
        WHEN 'MONTHLY' THEN FORMAT(@Date, 'yyyy-MM')
        WHEN 'QUARTERLY' THEN FORMAT(@Date, 'yyyy') + '-Q' + CAST(DATEPART(QUARTER, @Date) AS VARCHAR(1))
        WHEN 'YEARLY' THEN FORMAT(@Date, 'yyyy')
        ELSE FORMAT(@Date, 'yyyy-MM-dd')
    END;
    
    RETURN @PeriodCode;
END;
GO

-- Calculate submission deadline
CREATE OR ALTER FUNCTION [dbo].[fn_CalculateDeadline](
    @PeriodEndDate DATE,
    @DeadlineOffsetDays INT
)
RETURNS DATE
AS
BEGIN
    RETURN DATEADD(DAY, @DeadlineOffsetDays, @PeriodEndDate);
END;
GO

-- Check if submission is late
CREATE OR ALTER FUNCTION [dbo].[fn_IsSubmissionLate](
    @SubmittedAt DATETIME2,
    @Deadline DATE
)
RETURNS BIT
AS
BEGIN
    RETURN CASE WHEN CAST(@SubmittedAt AS DATE) > @Deadline THEN 1 ELSE 0 END;
END;
GO

PRINT N'13.functions.sql - Functions created successfully';
GO
