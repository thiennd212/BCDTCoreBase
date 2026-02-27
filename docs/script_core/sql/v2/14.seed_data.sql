-- ============================================================
-- BCDT - HỆ THỐNG BÁO CÁO ĐIỆN TỬ ĐỘNG
-- Module: Seed Data (Dữ liệu khởi tạo)
-- Version: 2.0
-- ============================================================

-- ============================================================
-- ORGANIZATION TYPES (5 levels)
-- ============================================================
SET IDENTITY_INSERT [dbo].[BCDT_OrganizationType] ON;
INSERT INTO [dbo].[BCDT_OrganizationType] ([Id], [Code], [Name], [Level], [ParentTypeId], [Description], [IsActive])
VALUES 
    (1, 'MINISTRY', N'Bộ/Cơ quan ngang Bộ', 1, NULL, N'Cấp Bộ hoặc cơ quan ngang Bộ', 1),
    (2, 'PROVINCE', N'Tỉnh/Thành phố', 2, 1, N'Tỉnh hoặc thành phố trực thuộc trung ương', 1),
    (3, 'LEVEL3', N'Cấp 3', 3, 2, N'Đơn vị cấp 3 trực thuộc tỉnh', 1),
    (4, 'LEVEL4', N'Cấp 4', 4, 3, N'Đơn vị cấp 4 trực thuộc cấp 3', 1),
    (5, 'LEVEL5', N'Cấp 5', 5, 4, N'Đơn vị cấp 5 trực thuộc cấp 4', 1);
SET IDENTITY_INSERT [dbo].[BCDT_OrganizationType] OFF;
GO

-- ============================================================
-- ROLES (5 standard roles)
-- ============================================================
SET IDENTITY_INSERT [dbo].[BCDT_Role] ON;
INSERT INTO [dbo].[BCDT_Role] ([Id], [Code], [Name], [Description], [Level], [IsSystem], [IsActive])
VALUES 
    (1, 'SYSTEM_ADMIN', N'Quản trị hệ thống', N'Toàn quyền quản trị hệ thống', 0, 1, 1),
    (2, 'FORM_ADMIN', N'Quản trị biểu mẫu', N'Quản lý biểu mẫu và cấu trúc báo cáo', 1, 1, 1),
    (3, 'UNIT_ADMIN', N'Quản trị đơn vị', N'Quản lý người dùng và dữ liệu đơn vị', 2, 1, 1),
    (4, 'DATA_ENTRY', N'Nhập liệu', N'Nhập liệu và nộp báo cáo', 3, 1, 1),
    (5, 'VIEWER', N'Xem báo cáo', N'Chỉ xem báo cáo, không chỉnh sửa', 4, 1, 1);
SET IDENTITY_INSERT [dbo].[BCDT_Role] OFF;
GO

-- ============================================================
-- DATA SCOPES
-- ============================================================
SET IDENTITY_INSERT [dbo].[BCDT_DataScope] ON;
INSERT INTO [dbo].[BCDT_DataScope] ([Id], [Code], [Name], [ScopeType], [Description])
VALUES 
    (1, 'OWN', N'Dữ liệu cá nhân', 'Own', N'Chỉ dữ liệu do chính mình tạo'),
    (2, 'ORGANIZATION', N'Dữ liệu đơn vị', 'Organization', N'Dữ liệu của đơn vị mình'),
    (3, 'CHILDREN', N'Dữ liệu đơn vị con', 'Children', N'Dữ liệu của đơn vị và các đơn vị con'),
    (4, 'ALL', N'Toàn bộ dữ liệu', 'All', N'Tất cả dữ liệu trong hệ thống');
SET IDENTITY_INSERT [dbo].[BCDT_DataScope] OFF;
GO

-- ============================================================
-- ROLE DATA SCOPES
-- ============================================================
INSERT INTO [dbo].[BCDT_RoleDataScope] ([RoleId], [EntityType], [DataScopeId])
VALUES 
    -- SystemAdmin: All
    (1, 'Submission', 4),
    (1, 'Organization', 4),
    (1, 'Report', 4),
    -- FormAdmin: All
    (2, 'Submission', 4),
    (2, 'Organization', 4),
    (2, 'Report', 4),
    -- UnitAdmin: Children
    (3, 'Submission', 3),
    (3, 'Organization', 3),
    (3, 'Report', 3),
    -- DataEntry: Organization
    (4, 'Submission', 2),
    (4, 'Organization', 2),
    (4, 'Report', 2),
    -- Viewer: Organization
    (5, 'Submission', 2),
    (5, 'Organization', 2),
    (5, 'Report', 2);
GO

-- ============================================================
-- PERMISSIONS
-- ============================================================
INSERT INTO [dbo].[BCDT_Permission] ([Code], [Name], [Module], [Action], [Description])
VALUES 
    -- Form permissions
    ('Form.View', N'Xem biểu mẫu', 'Form', 'View', N'Xem danh sách và chi tiết biểu mẫu'),
    ('Form.Create', N'Tạo biểu mẫu', 'Form', 'Create', N'Tạo biểu mẫu mới'),
    ('Form.Edit', N'Sửa biểu mẫu', 'Form', 'Edit', N'Chỉnh sửa biểu mẫu'),
    ('Form.Delete', N'Xóa biểu mẫu', 'Form', 'Delete', N'Xóa biểu mẫu'),
    ('Form.Publish', N'Xuất bản biểu mẫu', 'Form', 'Publish', N'Xuất bản biểu mẫu để sử dụng'),
    
    -- Submission permissions
    ('Submission.View', N'Xem báo cáo', 'Submission', 'View', N'Xem danh sách và chi tiết báo cáo'),
    ('Submission.Create', N'Tạo báo cáo', 'Submission', 'Create', N'Tạo báo cáo mới'),
    ('Submission.Edit', N'Sửa báo cáo', 'Submission', 'Edit', N'Chỉnh sửa báo cáo'),
    ('Submission.Delete', N'Xóa báo cáo', 'Submission', 'Delete', N'Xóa báo cáo'),
    ('Submission.Submit', N'Nộp báo cáo', 'Submission', 'Submit', N'Nộp báo cáo chính thức'),
    ('Submission.Export', N'Xuất báo cáo', 'Submission', 'Export', N'Xuất báo cáo ra file'),
    
    -- Workflow permissions
    ('Workflow.ViewPending', N'Xem chờ duyệt', 'Workflow', 'View', N'Xem danh sách báo cáo chờ duyệt'),
    ('Workflow.Approve', N'Phê duyệt', 'Workflow', 'Approve', N'Phê duyệt báo cáo'),
    ('Workflow.Reject', N'Từ chối', 'Workflow', 'Reject', N'Từ chối báo cáo'),
    ('Workflow.Configure', N'Cấu hình workflow', 'Workflow', 'Configure', N'Cấu hình quy trình phê duyệt'),
    
    -- Report permissions
    ('Report.ViewAggregate', N'Xem báo cáo tổng hợp', 'Report', 'View', N'Xem báo cáo tổng hợp'),
    ('Report.Export', N'Xuất báo cáo tổng hợp', 'Report', 'Export', N'Xuất báo cáo tổng hợp'),
    ('Report.DrillDown', N'Xem chi tiết', 'Report', 'DrillDown', N'Xem chi tiết từ báo cáo tổng hợp'),
    
    -- Admin permissions
    ('Admin.ManageUsers', N'Quản lý người dùng', 'Admin', 'ManageUsers', N'Thêm, sửa, xóa người dùng'),
    ('Admin.ManageRoles', N'Quản lý vai trò', 'Admin', 'ManageRoles', N'Quản lý vai trò và phân quyền'),
    ('Admin.ManageOrg', N'Quản lý đơn vị', 'Admin', 'ManageOrg', N'Quản lý cơ cấu tổ chức'),
    ('Admin.ViewAudit', N'Xem audit log', 'Admin', 'ViewAudit', N'Xem nhật ký hệ thống'),
    ('Admin.SystemConfig', N'Cấu hình hệ thống', 'Admin', 'SystemConfig', N'Cấu hình thông số hệ thống');
GO

-- ============================================================
-- ROLE PERMISSIONS MAPPING
-- ============================================================
-- SystemAdmin: All permissions
INSERT INTO [dbo].[BCDT_RolePermission] ([RoleId], [PermissionId])
SELECT 1, Id FROM [dbo].[BCDT_Permission];
GO

-- FormAdmin: Form + Submission + Workflow + Report + ViewAudit
INSERT INTO [dbo].[BCDT_RolePermission] ([RoleId], [PermissionId])
SELECT 2, Id FROM [dbo].[BCDT_Permission] 
WHERE [Module] IN ('Form', 'Submission', 'Workflow', 'Report') 
   OR [Code] = 'Admin.ViewAudit';
GO

-- UnitAdmin: Limited admin + Submission + Workflow + Report
INSERT INTO [dbo].[BCDT_RolePermission] ([RoleId], [PermissionId])
SELECT 3, Id FROM [dbo].[BCDT_Permission] 
WHERE [Module] IN ('Submission', 'Workflow', 'Report')
   OR [Code] IN ('Form.View', 'Admin.ManageUsers', 'Admin.ManageOrg', 'Admin.ViewAudit');
GO

-- DataEntry: Submission (no delete) + limited workflow + report view
INSERT INTO [dbo].[BCDT_RolePermission] ([RoleId], [PermissionId])
SELECT 4, Id FROM [dbo].[BCDT_Permission] 
WHERE [Code] IN ('Form.View', 'Submission.View', 'Submission.Create', 'Submission.Edit', 
                 'Submission.Submit', 'Submission.Export', 'Report.ViewAggregate', 'Report.Export');
GO

-- Viewer: View only
INSERT INTO [dbo].[BCDT_RolePermission] ([RoleId], [PermissionId])
SELECT 5, Id FROM [dbo].[BCDT_Permission] 
WHERE [Code] IN ('Form.View', 'Submission.View', 'Submission.Export', 
                 'Report.ViewAggregate', 'Report.Export');
GO

-- ============================================================
-- REPORTING FREQUENCIES
-- ============================================================
INSERT INTO [dbo].[BCDT_ReportingFrequency] ([Code], [Name], [NameEn], [DaysInPeriod], [CronExpression], [Description], [DisplayOrder])
VALUES 
    ('DAILY', N'Hàng ngày', 'Daily', 1, '0 0 * * *', N'Báo cáo hàng ngày', 1),
    ('WEEKLY', N'Hàng tuần', 'Weekly', 7, '0 0 * * 1', N'Báo cáo hàng tuần (thứ 2)', 2),
    ('MONTHLY', N'Hàng tháng', 'Monthly', 30, '0 0 1 * *', N'Báo cáo hàng tháng (ngày 1)', 3),
    ('QUARTERLY', N'Hàng quý', 'Quarterly', 90, '0 0 1 1,4,7,10 *', N'Báo cáo hàng quý', 4),
    ('YEARLY', N'Hàng năm', 'Yearly', 365, '0 0 1 1 *', N'Báo cáo hàng năm', 5),
    ('ADHOC', N'Đột xuất', 'Ad-hoc', 0, NULL, N'Báo cáo đột xuất theo yêu cầu', 6);
GO

-- ============================================================
-- AUTH PROVIDERS
-- ============================================================
INSERT INTO [dbo].[BCDT_AuthProvider] ([ProviderType], [Name], [IsEnabled], [Priority], [Settings])
VALUES 
    ('BuiltIn', N'Đăng nhập nội bộ', 1, 100, 
     '{"passwordMinLength":8,"requireUppercase":true,"requireDigit":true,"requireSpecialChar":true,"lockoutThreshold":5,"lockoutDurationMinutes":30}'),
    ('SSO', N'Single Sign-On (OAuth2/SAML)', 0, 50, 
     '{"authorizeEndpoint":"","tokenEndpoint":"","userInfoEndpoint":"","clientId":"","clientSecret":"","scopes":"openid profile email"}'),
    ('LDAP', N'LDAP/Active Directory', 0, 75, 
     '{"server":"","port":389,"useSsl":false,"baseDn":"","userDnPrefix":"cn=","syncSchedule":"0 0 * * *"}');
GO

-- ============================================================
-- 2FA PROVIDERS
-- ============================================================
INSERT INTO [dbo].[BCDT_TwoFactorProvider] ([ProviderType], [Name], [IsEnabled], [Settings])
VALUES 
    ('TOTP', N'Ứng dụng Authenticator (TOTP)', 0, '{"issuer":"BCDT","algorithm":"SHA1","digits":6,"period":30}'),
    ('SMS', N'Mã OTP qua SMS', 0, '{"codeLength":6,"expiryMinutes":5,"provider":"","apiKey":""}'),
    ('Email', N'Mã OTP qua Email', 0, '{"codeLength":6,"expiryMinutes":10}');
GO

-- ============================================================
-- SIGNATURE PROVIDERS
-- ============================================================
INSERT INTO [dbo].[BCDT_SignatureProvider] ([ProviderType], [Name], [IsEnabled], [RequiresHardwareToken], [Settings])
VALUES 
    ('Audit', N'Phê duyệt (Audit-based)', 1, 0, '{"hashAlgorithm":"SHA256"}'),
    ('Simple', N'Chữ ký điện tử đơn giản', 0, 0, '{"captureMethod":"typed"}'),
    ('VGCA', N'Chữ ký số VGCA', 0, 1, '{"timestampUrl":"","requireTimestamp":true}');
GO

-- ============================================================
-- MENUS – Cấu hình hệ thống (con của group "Hệ thống" đã có trong DB)
-- ============================================================
-- Chỉ thêm menu "Cấu hình hệ thống" làm con của group "Hệ thống" đã tồn tại (ưu tiên Code=MENU_SYSTEM).
SET IDENTITY_INSERT [dbo].[BCDT_Menu] ON;
INSERT INTO [dbo].[BCDT_Menu] ([Id], [Code], [Name], [ParentId], [Url], [Icon], [DisplayOrder], [IsVisible], [RequiredPermission])
SELECT 100, 'SYSTEM_CONFIG', N'Cấu hình hệ thống',
    (SELECT TOP 1 [Id] FROM [dbo].[BCDT_Menu] WHERE [ParentId] IS NULL AND ([Code] = 'MENU_SYSTEM' OR [Name] = N'Hệ thống' OR [Code] = 'SYSTEM_GROUP') ORDER BY CASE WHEN [Code] = 'MENU_SYSTEM' THEN 0 ELSE 1 END),
    '/system-config', 'SettingOutlined', 1, 1, 'Admin.SystemConfig';
SET IDENTITY_INSERT [dbo].[BCDT_Menu] OFF;
-- RoleMenu: SYSTEM_ADMIN(1), FORM_ADMIN(2) – xem + sửa Cấu hình hệ thống (chỉ menu con 100)
INSERT INTO [dbo].[BCDT_RoleMenu] ([RoleId], [MenuId], [CanView], [CanCreate], [CanEdit], [CanDelete], [CanExport], [CanApprove])
VALUES (1, 100, 1, 0, 1, 0, 0, 0), (2, 100, 1, 0, 1, 0, 0, 0);
GO

-- ============================================================
-- SYSTEM CONFIGURATION
-- ============================================================
INSERT INTO [dbo].[BCDT_SystemConfig] ([ConfigKey], [ConfigValue], [DataType], [Description])
VALUES 
    ('System.Name', N'Hệ thống Báo cáo Điện tử Động', 'String', N'Tên hệ thống'),
    ('System.Version', '2.0.0', 'String', N'Phiên bản hệ thống'),
    ('Auth.SessionTimeoutMinutes', '30', 'Number', N'Thời gian timeout phiên làm việc'),
    ('Auth.MaxConcurrentSessions', '1', 'Number', N'Số phiên đăng nhập đồng thời tối đa'),
    ('TwoFactor.Enabled', 'false', 'Boolean', N'Bật/tắt xác thực 2 lớp'),
    ('TwoFactor.RequiredRoles', '["SYSTEM_ADMIN","FORM_ADMIN"]', 'Json', N'Vai trò yêu cầu 2FA'),
    ('Upload.MaxFileSizeMB', '10', 'Number', N'Kích thước file upload tối đa (MB)'),
    ('Upload.AllowedExtensions', '.xlsx,.xls', 'String', N'Định dạng file cho phép'),
    ('Excel.MaxRowsPerSheet', '10000', 'Number', N'Số dòng tối đa mỗi sheet'),
    ('Notification.EmailEnabled', 'true', 'Boolean', N'Bật/tắt thông báo email'),
    ('Notification.SmsEnabled', 'false', 'Boolean', N'Bật/tắt thông báo SMS');
GO

-- ============================================================
-- SAMPLE ORGANIZATION (cho gán vai trò theo đơn vị + chuyển vai trò)
-- ============================================================
IF NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_Organization] WHERE [Code] = N'MOF')
INSERT INTO [dbo].[BCDT_Organization] ([Code], [Name], [OrganizationTypeId], [ParentId], [TreePath], [Level], [IsActive], [DisplayOrder], [CreatedBy])
VALUES (N'MOF', N'Bộ Tài chính', 1, NULL, N'/1/', 1, 1, 0, -1);
GO

-- ============================================================
-- DEFAULT ADMIN USER (password: Admin@123)
-- ============================================================
INSERT INTO [dbo].[BCDT_User] ([Username], [PasswordHash], [Email], [FullName], [AuthProvider], [IsActive], [CreatedBy])
VALUES ('admin', 
        -- Argon2 hash of 'Admin@123' - Replace with actual hash in production
        '$argon2id$v=19$m=65536,t=3,p=4$c29tZXNhbHQ$RdescudvJCsgt3ub+b+dWRWJTmaaJObG', 
        'admin@bcdt.gov.vn', 
        N'Quản trị viên hệ thống', 
        'BuiltIn', 
        1, 
        -1);
GO

-- Assign SystemAdmin role to admin user (toàn hệ thống, OrganizationId = NULL)
INSERT INTO [dbo].[BCDT_UserRole] ([UserId], [RoleId], [OrganizationId], [IsActive], [GrantedBy])
SELECT u.Id, 1, NULL, 1, -1
FROM [dbo].[BCDT_User] u WHERE u.Username = 'admin';
GO

-- Gán đơn vị mẫu và vai trò theo đơn vị cho admin (để test chuyển vai trò: 2 lựa chọn)
INSERT INTO [dbo].[BCDT_UserOrganization] ([UserId], [OrganizationId], [IsPrimary], [IsActive], [JoinedAt], [CreatedAt], [CreatedBy])
SELECT u.Id, o.Id, 1, 1, GETDATE(), GETDATE(), -1
FROM [dbo].[BCDT_User] u CROSS JOIN [dbo].[BCDT_Organization] o
WHERE u.Username = N'admin' AND o.Code = N'MOF'
  AND NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_UserOrganization] uo WHERE uo.UserId = u.Id AND uo.OrganizationId = o.Id);
INSERT INTO [dbo].[BCDT_UserRole] ([UserId], [RoleId], [OrganizationId], [IsActive], [GrantedBy])
SELECT u.Id, 3, o.Id, 1, -1
FROM [dbo].[BCDT_User] u CROSS JOIN [dbo].[BCDT_Organization] o
WHERE u.Username = N'admin' AND o.Code = N'MOF'
  AND NOT EXISTS (SELECT 1 FROM [dbo].[BCDT_UserRole] ur WHERE ur.UserId = u.Id AND ur.RoleId = 3 AND ur.OrganizationId = o.Id);
GO

PRINT N'14.seed_data.sql - Seed data inserted successfully';
PRINT N'';
PRINT N'==============================================';
PRINT N'BCDT DATABASE SCHEMA v2.0 - COMPLETED';
PRINT N'Total Tables: 44';
PRINT N'==============================================';
GO
