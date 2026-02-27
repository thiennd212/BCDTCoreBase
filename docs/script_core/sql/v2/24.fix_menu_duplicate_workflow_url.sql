-- ============================================================
-- BCDT – Xóa menu trùng Url /workflow-definitions (giữ WORKFLOW_DEFINITIONS Id 102)
-- Chạy khi tồn tại 2 mục menu cùng Url: MENU_WORKFLOW (35) và WORKFLOW_DEFINITIONS (102).
-- Giữ: WORKFLOW_DEFINITIONS (102) dưới Hệ thống. Xóa: MENU_WORKFLOW (35) dưới Biểu mẫu & Báo cáo.
-- Idempotent: chỉ xóa khi có đúng Code = MENU_WORKFLOW và Url = /workflow-definitions.
-- ============================================================

-- 1. Xóa RoleMenu trỏ tới menu 35 (nếu có)
DELETE FROM [dbo].[BCDT_RoleMenu] WHERE [MenuId] = 35;

-- 2. Xóa menu trùng (MENU_WORKFLOW – cùng Url với WORKFLOW_DEFINITIONS)
DELETE FROM [dbo].[BCDT_Menu]
WHERE [Id] = 35 AND [Code] = N'MENU_WORKFLOW' AND [Url] = N'/workflow-definitions';

PRINT N'24.fix_menu_duplicate_workflow_url.sql – Đã xóa menu trùng Url /workflow-definitions (MENU_WORKFLOW Id 35).';
GO
