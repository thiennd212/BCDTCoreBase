-- ============================================================
-- BCDT – Thêm mục menu "Ủy quyền người dùng" (/user-delegations)
-- Sprint 4 S4.3: kết hợp với UserDelegationsPage (S4.1 FE).
-- Idempotent: chỉ thêm nếu chưa có Code = USER_DELEGATIONS.
-- Parent: cùng nhóm "Hệ thống" (MENU_SYSTEM).
-- RequiredPermission: Admin.ManageUsers (role SystemAdmin có quyền quản lý ủy quyền).
-- ============================================================

-- 1. Insert menu (không dùng IDENTITY_INSERT để tránh xung đột Id)
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Menu] WHERE [Code] = 'USER_DELEGATIONS')
BEGIN
  INSERT INTO [dbo].[BCDT_Menu] ([Code], [Name], [ParentId], [Url], [Icon], [DisplayOrder], [IsVisible], [RequiredPermission])
  SELECT 'USER_DELEGATIONS', N'Ủy quyền người dùng',
      (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [ParentId] IS NULL AND ([Code] = 'MENU_SYSTEM' OR [Name] = N'Hệ thống') ORDER BY CASE WHEN [Code] = 'MENU_SYSTEM' THEN 0 ELSE 1 END),
      '/user-delegations', 'SwapOutlined', 5, 1, 'Admin.ManageUsers'
  FROM (SELECT 1 AS dummy) AS src
  WHERE EXISTS (
    SELECT 1 FROM [dbo].[BCDT_Menu] WHERE [ParentId] IS NULL AND ([Code] = 'MENU_SYSTEM' OR [Name] = N'Hệ thống')
  );
END
GO

-- 2. Gán RoleMenu: SYSTEM_ADMIN(1) – CanView=1, CanCreate=1, CanEdit=1, CanDelete=1
DECLARE @MenuId INT = (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [Code] = 'USER_DELEGATIONS');
IF @MenuId IS NOT NULL
BEGIN
  INSERT INTO [dbo].[BCDT_RoleMenu] ([RoleId], [MenuId], [CanView], [CanCreate], [CanEdit], [CanDelete], [CanExport], [CanApprove])
  SELECT 1, @MenuId, 1, 1, 1, 1, 0, 0
  WHERE NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_RoleMenu] WHERE [RoleId] = 1 AND [MenuId] = @MenuId);
END
GO

PRINT N'29.seed_menu_user_delegations.sql – Menu Ủy quyền người dùng đã thêm (nếu chưa có).';
GO
