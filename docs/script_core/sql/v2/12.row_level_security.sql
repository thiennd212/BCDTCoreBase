-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Row-Level Security (RLS)
-- Version: 2.0
-- ============================================================

-- ============================================================
-- SECURITY PREDICATE FUNCTION
-- ============================================================

-- Function to check if user can access organization data
CREATE OR ALTER FUNCTION [dbo].[fn_SecurityPredicate_Organization](
    @OrganizationId INT
)
RETURNS TABLE
WITH SCHEMABINDING
AS
RETURN
(
    SELECT 1 AS Result
    WHERE 
        -- System context (background jobs, migrations)
        CAST(SESSION_CONTEXT(N'IsSystemContext') AS BIT) = 1
        
        OR
        
        -- User has access to this organization
        EXISTS (
            SELECT 1 
            FROM [dbo].[BCDT_UserOrganization] uo
            INNER JOIN [dbo].[BCDT_Organization] target ON target.Id = @OrganizationId
            INNER JOIN [dbo].[BCDT_Organization] userOrg ON uo.OrganizationId = userOrg.Id
            WHERE uo.UserId = CAST(SESSION_CONTEXT(N'UserId') AS INT)
              AND uo.IsActive = 1
              AND (
                  -- Direct access to own organization
                  uo.OrganizationId = @OrganizationId
                  
                  OR
                  
                  -- Access to child organizations (based on TreePath)
                  target.TreePath LIKE userOrg.TreePath + '%'
              )
        )
        
        OR
        
        -- User has 'All' data scope (SystemAdmin, FormAdmin)
        EXISTS (
            SELECT 1
            FROM [dbo].[BCDT_UserRole] ur
            INNER JOIN [dbo].[BCDT_RoleDataScope] rds ON ur.RoleId = rds.RoleId
            INNER JOIN [dbo].[BCDT_DataScope] ds ON rds.DataScopeId = ds.Id
            WHERE ur.UserId = CAST(SESSION_CONTEXT(N'UserId') AS INT)
              AND ur.IsActive = 1
              AND (ur.ValidTo IS NULL OR ur.ValidTo > GETDATE())
              AND rds.EntityType = 'Submission'
              AND ds.ScopeType = 'All'
        )
);
GO

-- ============================================================
-- SECURITY POLICIES
-- ============================================================

-- Policy for ReportSubmission
CREATE SECURITY POLICY [dbo].[SecurityPolicy_ReportSubmission]
ADD FILTER PREDICATE [dbo].[fn_SecurityPredicate_Organization]([OrganizationId])
ON [dbo].[BCDT_ReportSubmission],
ADD BLOCK PREDICATE [dbo].[fn_SecurityPredicate_Organization]([OrganizationId])
ON [dbo].[BCDT_ReportSubmission] AFTER INSERT,
ADD BLOCK PREDICATE [dbo].[fn_SecurityPredicate_Organization]([OrganizationId])
ON [dbo].[BCDT_ReportSubmission] AFTER UPDATE
WITH (STATE = ON);
GO

-- Policy for ReferenceEntity (organization-scoped)
CREATE SECURITY POLICY [dbo].[SecurityPolicy_ReferenceEntity]
ADD FILTER PREDICATE [dbo].[fn_SecurityPredicate_Organization]([OrganizationId])
ON [dbo].[BCDT_ReferenceEntity]
WITH (STATE = ON);
GO

-- ============================================================
-- HELPER PROCEDURES FOR SESSION CONTEXT
-- ============================================================

-- Set user context (call at start of request)
CREATE OR ALTER PROCEDURE [dbo].[sp_SetUserContext]
    @UserId INT,
    @IsSystemContext BIT = 0
AS
BEGIN
    EXEC sp_set_session_context N'UserId', @UserId;
    EXEC sp_set_session_context N'IsSystemContext', @IsSystemContext;
END;
GO

-- Clear user context (call at end of request or on error)
CREATE OR ALTER PROCEDURE [dbo].[sp_ClearUserContext]
AS
BEGIN
    EXEC sp_set_session_context N'UserId', NULL;
    EXEC sp_set_session_context N'IsSystemContext', NULL;
END;
GO

-- Set system context for background jobs
CREATE OR ALTER PROCEDURE [dbo].[sp_SetSystemContext]
AS
BEGIN
    EXEC sp_set_session_context N'IsSystemContext', 1;
END;
GO

-- ============================================================
-- NOTES ON RLS USAGE
-- ============================================================
/*
USAGE IN .NET APPLICATION:

1. At the start of each request (middleware or filter):
   
   using var connection = _context.Database.GetDbConnection();
   await connection.OpenAsync();
   using var command = connection.CreateCommand();
   command.CommandText = "EXEC sp_SetUserContext @UserId";
   command.Parameters.Add(new SqlParameter("@UserId", currentUserId));
   await command.ExecuteNonQueryAsync();

2. For background jobs:
   
   using var command = connection.CreateCommand();
   command.CommandText = "EXEC sp_SetSystemContext";
   await command.ExecuteNonQueryAsync();

3. RLS automatically filters data based on user's organization access.

4. To temporarily disable RLS for admin operations:
   
   ALTER SECURITY POLICY SecurityPolicy_ReportSubmission WITH (STATE = OFF);
   -- Perform admin operation
   ALTER SECURITY POLICY SecurityPolicy_ReportSubmission WITH (STATE = ON);
*/

PRINT N'12.row_level_security.sql - RLS policies created successfully';
GO
