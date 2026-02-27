-- ============================================================
-- BCDT – Thêm mục menu "Quy trình phê duyệt" (/workflow-definitions)
-- Idempotent: chỉ thêm nếu chưa có Code = WORKFLOW_DEFINITIONS.
-- Parent: cùng nhóm "Hệ thống" (MENU_SYSTEM) như SYSTEM_CONFIG.
-- RequiredPermission: Workflow.Configure (role FormAdmin, UnitAdmin, SystemAdmin có quyền).
-- ============================================================

-- 1. Insert menu (không dùng IDENTITY_INSERT để tránh xung đột Id)
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Menu] WHERE [Code] = 'WORKFLOW_DEFINITIONS')
BEGIN
  INSERT INTO [dbo].[BCDT_Menu] ([Code], [Name], [ParentId], [Url], [Icon], [DisplayOrder], [IsVisible], [RequiredPermission])
  SELECT 'WORKFLOW_DEFINITIONS', N'Quy trình phê duyệt',
      (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [ParentId] IS NULL AND ([Code] = 'MENU_SYSTEM' OR [Name] = N'Hệ thống') ORDER BY CASE WHEN [Code] = 'MENU_SYSTEM' THEN 0 ELSE 1 END),
      '/workflow-definitions', 'NodeIndexOutlined', 2, 1, 'Workflow.Configure'
  FROM [dbo].[BCDT_Menu] WHERE [Code] = 'MENU_SYSTEM' AND [ParentId] IS NULL;
END
GO

-- 2. Gán RoleMenu: SYSTEM_ADMIN(1), FORM_ADMIN(2), UNIT_ADMIN(3) – CanView=1, CanEdit=1 (cấu hình quy trình)
DECLARE @MenuId INT = (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [Code] = 'WORKFLOW_DEFINITIONS');
IF @MenuId IS NOT NULL
BEGIN
  INSERT INTO [dbo].[BCDT_RoleMenu] ([RoleId], [MenuId], [CanView], [CanCreate], [CanEdit], [CanDelete], [CanExport], [CanApprove])
  SELECT 1, @MenuId, 1, 1, 1, 1, 0, 0
  WHERE NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_RoleMenu] WHERE [RoleId] = 1 AND [MenuId] = @MenuId);
  INSERT INTO [dbo].[BCDT_RoleMenu] ([RoleId], [MenuId], [CanView], [CanCreate], [CanEdit], [CanDelete], [CanExport], [CanApprove])
  SELECT 2, @MenuId, 1, 1, 1, 1, 0, 0
  WHERE NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_RoleMenu] WHERE [RoleId] = 2 AND [MenuId] = @MenuId);
  INSERT INTO [dbo].[BCDT_RoleMenu] ([RoleId], [MenuId], [CanView], [CanCreate], [CanEdit], [CanDelete], [CanExport], [CanApprove])
  SELECT 3, @MenuId, 1, 1, 1, 1, 0, 0
  WHERE NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_RoleMenu] WHERE [RoleId] = 3 AND [MenuId] = @MenuId);
END
GO

PRINT N'23.seed_menu_workflow_definitions.sql – Menu Quy trình phê duyệt đã thêm (nếu chưa có).';
GO
