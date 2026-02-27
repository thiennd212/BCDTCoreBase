-- ============================================================
-- BCDT – Sửa 2 group "Hệ thống": gắn Cấu hình hệ thống vào group MENU_SYSTEM, xóa group trùng (SYSTEM_GROUP)
-- Chạy 1 lần khi sidebar đang hiển thị 2 nhóm "Hệ thống" (một có Thông báo, một có Cấu hình hệ thống).
-- ============================================================

-- Bước 1: Gắn "Cấu hình hệ thống" (SYSTEM_CONFIG) vào group "Hệ thống" có Code = MENU_SYSTEM (group có "Thông báo")
UPDATE [dbo].[BCDT_Menu]
SET [ParentId] = (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [Code] = 'MENU_SYSTEM' AND [ParentId] IS NULL),
    [DisplayOrder] = 2
WHERE [Code] = 'SYSTEM_CONFIG';
GO

-- Bước 2: Xóa quyền gắn với group trùng (SYSTEM_GROUP) trước khi xóa menu
DELETE FROM [dbo].[BCDT_RoleMenu] WHERE [MenuId] IN (SELECT [Id] FROM [dbo].[BCDT_Menu] WHERE [Code] = 'SYSTEM_GROUP');
GO

-- Bước 3: Xóa group "Hệ thống" trùng (Code=SYSTEM_GROUP). Chỉ xóa khi không còn menu con trỏ vào nó (đã update bước 1)
DELETE FROM [dbo].[BCDT_Menu] WHERE [Code] = 'SYSTEM_GROUP' AND [ParentId] IS NULL;
GO

PRINT N'16.fix_duplicate_system_group.sql – Đã gắn Cấu hình hệ thống vào group MENU_SYSTEM và xóa group trùng.';
GO
