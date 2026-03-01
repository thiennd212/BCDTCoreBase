-- ============================================================
-- BCDT – Thêm mục menu "Thông báo" (/notifications)
-- Sprint 5 S5.1: Notification BE + S5.2 Notification FE.
-- Idempotent: chỉ thêm nếu chưa có Code = NOTIFICATIONS.
-- Parent: cùng nhóm "Hệ thống" (MENU_SYSTEM).
-- RequiredPermission: NULL (tất cả người dùng đã đăng nhập đều xem được).
-- ============================================================

-- 1. Insert menu
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Menu] WHERE [Code] = 'NOTIFICATIONS')
BEGIN
  INSERT INTO [dbo].[BCDT_Menu] ([Code], [Name], [ParentId], [Url], [Icon], [DisplayOrder], [IsVisible], [RequiredPermission])
  SELECT 'NOTIFICATIONS', N'Thông báo',
      (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [ParentId] IS NULL AND ([Code] = 'MENU_SYSTEM' OR [Name] = N'Hệ thống') ORDER BY CASE WHEN [Code] = 'MENU_SYSTEM' THEN 0 ELSE 1 END),
      '/notifications', 'BellOutlined', 6, 1, NULL
  FROM (SELECT 1 AS dummy) AS src
  WHERE EXISTS (
    SELECT 1 FROM [dbo].[BCDT_Menu] WHERE [ParentId] IS NULL AND ([Code] = 'MENU_SYSTEM' OR [Name] = N'Hệ thống')
  );
END
GO

-- 2. Gán RoleMenu: SYSTEM_ADMIN(1) – CanView=1, các quyền khác=0 (người dùng chỉ xem thông báo của mình)
DECLARE @MenuId INT = (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [Code] = 'NOTIFICATIONS');
IF @MenuId IS NOT NULL
BEGIN
  INSERT INTO [dbo].[BCDT_RoleMenu] ([RoleId], [MenuId], [CanView], [CanCreate], [CanEdit], [CanDelete], [CanExport], [CanApprove])
  SELECT 1, @MenuId, 1, 0, 1, 1, 0, 0
  WHERE NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_RoleMenu] WHERE [RoleId] = 1 AND [MenuId] = @MenuId);
END
GO

-- 3. Index tối ưu cho BCDT_Notification (nếu chưa có)
IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Notification_UserId_IsRead')
BEGIN
  CREATE INDEX IX_Notification_UserId_IsRead ON [dbo].[BCDT_Notification] ([UserId], [IsRead], [IsDismissed]) INCLUDE ([CreatedAt]);
END
GO

IF NOT EXISTS (SELECT 1 FROM sys.indexes WHERE name = 'IX_Notification_UserId_CreatedAt')
BEGIN
  CREATE INDEX IX_Notification_UserId_CreatedAt ON [dbo].[BCDT_Notification] ([UserId], [CreatedAt] DESC);
END
GO

PRINT N'30.seed_menu_notifications.sql – Menu Thông báo + indexes đã thêm (nếu chưa có).';
GO
