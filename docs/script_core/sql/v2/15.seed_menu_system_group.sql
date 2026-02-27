-- ============================================================
-- BCDT – Gắn menu "Cấu hình hệ thống" vào group "Hệ thống" đã có
-- Chạy khi DB đã có menu SYSTEM_CONFIG (Id=100) nhưng đang nằm ngoài hoặc dưới group sai.
-- Không tạo group "Hệ thống" mới – chỉ cập nhật ParentId trỏ vào group đã có.
-- ============================================================

-- Cập nhật ParentId của "Cấu hình hệ thống" thành Id của group "Hệ thống" đã có (ưu tiên MENU_SYSTEM – group có "Thông báo")
UPDATE [dbo].[BCDT_Menu]
SET [ParentId] = (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [ParentId] IS NULL AND ([Code] = 'MENU_SYSTEM' OR [Name] = N'Hệ thống' OR [Code] = 'SYSTEM_GROUP') ORDER BY CASE WHEN [Code] = 'MENU_SYSTEM' THEN 0 ELSE 1 END),
    [DisplayOrder] = 2
WHERE [Code] = 'SYSTEM_CONFIG'
  AND EXISTS (SELECT 1 FROM [dbo].[BCDT_Menu] WHERE [ParentId] IS NULL AND ([Code] = 'MENU_SYSTEM' OR [Name] = N'Hệ thống' OR [Code] = 'SYSTEM_GROUP'));
GO

-- RoleMenu cho menu Cấu hình hệ thống (100): đảm bảo SYSTEM_ADMIN(1), FORM_ADMIN(2) có quyền
DECLARE @MenuId INT = (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [Code] = 'SYSTEM_CONFIG');
IF @MenuId IS NOT NULL
BEGIN
  INSERT INTO [dbo].[BCDT_RoleMenu] ([RoleId], [MenuId], [CanView], [CanCreate], [CanEdit], [CanDelete], [CanExport], [CanApprove])
  SELECT 1, @MenuId, 1, 0, 1, 0, 0, 0
  WHERE NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_RoleMenu] WHERE [RoleId] = 1 AND [MenuId] = @MenuId);
  INSERT INTO [dbo].[BCDT_RoleMenu] ([RoleId], [MenuId], [CanView], [CanCreate], [CanEdit], [CanDelete], [CanExport], [CanApprove])
  SELECT 2, @MenuId, 1, 0, 1, 0, 0, 0
  WHERE NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_RoleMenu] WHERE [RoleId] = 2 AND [MenuId] = @MenuId);
END
GO

PRINT N'15.seed_menu_system_group.sql – Cập nhật menu Cấu hình hệ thống vào group Hệ thống xong.';
GO
