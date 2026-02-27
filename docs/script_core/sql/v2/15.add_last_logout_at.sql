-- Thêm cột LastLogoutAt vào BCDT_User để vô hiệu hóa access token sau logout (B1 fix).
-- Access token có claim iat (issued at) < LastLogoutAt sẽ bị từ chối trong OnTokenValidated;
-- sau khi gọi /logout, gọi /me với cùng access token sẽ trả 401.
-- Chạy sau 14.seed_data.sql. Chỉ cần chạy một lần.

IF NOT EXISTS (
    SELECT 1 FROM sys.columns c
    INNER JOIN sys.tables t ON c.object_id = t.object_id
    WHERE t.name = N'BCDT_User' AND c.name = N'LastLogoutAt'
)
BEGIN
    ALTER TABLE [dbo].[BCDT_User]
    ADD [LastLogoutAt] DATETIME2 NULL;
END
GO
