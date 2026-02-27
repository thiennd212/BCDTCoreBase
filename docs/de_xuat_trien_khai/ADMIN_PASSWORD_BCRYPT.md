# Cập nhật mật khẩu admin cho B1 (BCrypt)

Seed trong `14.seed_data.sql` dùng placeholder Argon2. B1 dùng **BCrypt** để verify mật khẩu. Để đăng nhập được với `admin` / `Admin@123`, cần cập nhật cột `PasswordHash` trong `BCDT_User` bằng hash BCrypt của `Admin@123`.

## Cách 1: Chạy C# để lấy hash rồi UPDATE

1. Trong thư mục `src`, chạy:

```bash
dotnet run --project BCDT.Api -- hash-password Admin@123
```

*(Chỉ khi đã thêm lệnh hash-password vào Api – xem Cách 2.)*

2. Hoặc trong C# (REPL / console app có reference BCrypt.Net-Next):

```csharp
var hash = BCrypt.Net.BCrypt.HashPassword("Admin@123");
Console.WriteLine(hash);
```

3. Copy giá trị `hash`, rồi chạy SQL:

```sql
USE BCDT;
UPDATE dbo.BCDT_User
SET PasswordHash = N'<dán_hash_vừa_copy>'
WHERE Username = N'admin';
```

## Cách 2: Thêm endpoint tạm (chỉ dev) để sinh hash

Có thể thêm endpoint **chỉ cho môi trường Development** (vd `GET /api/v1/dev/hash-password?password=Admin@123`) trả về BCrypt hash để copy vào câu UPDATE trên. Nhớ **không** bật endpoint này ở production.

## Sau khi cập nhật

- Gọi `POST /api/v1/auth/login` với body `{ "username": "admin", "password": "Admin@123" }`.
- Kỳ vọng `200` và `data.accessToken`, `data.refreshToken`, `data.user`.
