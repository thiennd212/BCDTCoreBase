# Đề xuất triển khai B1 – JWT Authentication (cho AI)

Tài liệu hướng dẫn AI triển khai **B1: JWT authentication (login, logout, refresh token)** theo chuẩn BCDT và Clean Architecture.

**Tham chiếu:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [04.GIAI_PHAP_KY_THUAT.md](../script_core/04.GIAI_PHAP_KY_THUAT.md) (mục 7 API response, 1.4 RLS), [03.DATABASE_SCHEMA](../script_core/03.DATABASE_SCHEMA.md).

---

## Agents, Skills và Rules áp dụng cho B1

### Agent nên dùng

| Agent | Khi nào dùng |
|-------|---------------|
| **bcdt-auth-expert** | Triển khai B1 (JWT login, refresh, logout). Chọn agent này trong Composer/Chat khi giao task B1 để có context chuyên về auth. |

**Cách kích hoạt:** Trong Cursor, chọn agent **bcdt-auth-expert** (nếu có) hoặc gõ: *"Dùng agent bcdt-auth-expert, triển khai B1 JWT authentication theo docs/de_xuat_trien_khai/B1_JWT.md."*

### Skills nên dùng

| Skill | Mục đích |
|-------|----------|
| **bcdt-api-endpoint** | Tạo endpoint REST theo chuẩn BCDT: controller action, service method, DTOs. Dùng khi tạo POST `/api/v1/auth/login`, `/auth/refresh`, `/auth/logout` và response format `{ success, data }` / `{ success: false, errors }`. |

**Cách dùng:** Khi tạo từng endpoint (login, refresh, logout), có thể gọi skill **bcdt-api-endpoint** với mô tả (vd: "Tạo POST /api/v1/auth/login nhận LoginRequest, trả LoginResponse theo format success/data").

### Rules áp dụng (Cursor rules)

Áp dụng các rule sau khi triển khai B1 (mở/áp dụng trong session):

| Rule | File | Mục đích |
|------|------|----------|
| **senior-fullstack-standards** | `.cursor/rules/senior-fullstack-standards.mdc` | Chuẩn fullstack: SOLID, Clean Architecture, error handling, async, security (không hardcode secret). |
| **bcdt-project** | `.cursor/rules/bcdt-project.mdc` | Kiến trúc BCDT: layer API → Application → Domain → Infrastructure; naming BCDT_; DTOs, Result\<T\>, không đưa domain logic vào controller. |
| **bcdt-api** | `.cursor/rules/bcdt-api.mdc` | REST API: versioning `/api/v1/`, response `{ success, data, meta, errors }`, HTTP method đúng. |
| **bcdt-backend** | `.cursor/rules/bcdt-backend.mdc` | Backend .NET 8: DI, interface, async, structured logging. |
| **bcdt-database** | `.cursor/rules/bcdt-database.mdc` | SQL Server: bảng BCDT_*, parameterized query, không bypass RLS. |
| **always-verify-after-work** | `.cursor/rules/always-verify-after-work.mdc` | Sau khi làm xong: kiểm tra lại đúng/đủ (vd gọi login/refresh/logout, kiểm tra response format). |

**Lưu ý:** Rule `alwaysApply: true` (vd senior-fullstack-standards, bcdt-project, always-verify-after-work) đã tự áp dụng mọi session. Rule theo file (bcdt-api, bcdt-backend, bcdt-database) áp dụng khi mở file thuộc pattern tương ứng; có thể @-mention rule hoặc bật trong Cursor để đảm bảo.

---

## 1. Mục tiêu B1

| Deliverable | Mô tả |
|-------------|--------|
| API `/auth/login` | POST: nhận Username + Password, trả access_token + refresh_token + user info (theo format success/data). |
| API `/auth/refresh` | POST: nhận refresh_token (body hoặc header), trả access_token mới (+ refresh_token mới nếu rotate). |
| API `/auth/logout` | POST: thu hồi refresh_token (đánh dấu RevokedAt trong BCDT_RefreshToken). |
| Middleware JWT | Validate Bearer token; gắn UserId (và nếu cần OrganizationId) vào Claims. Chưa cần gọi RLS session context trong B1 (sẽ làm ở B3). |

---

## 2. Cấu hình đã có

- **appsettings.Development.json:** Đã có `ConnectionStrings.DefaultConnection`, `Jwt.SecretKey`, `Jwt.Issuer`, `Jwt.Audience`, `Jwt.ExpiryMinutes`. Dùng các key này khi đăng ký JWT và DbContext.

---

## 3. Bảng DB liên quan

| Bảng | Mục đích |
|------|----------|
| **BCDT_User** | Username, PasswordHash, Email, FullName, IsActive, AuthProvider (BuiltIn). Validate mật khẩu bằng hash (Argon2 hoặc ASP.NET Identity compatible). |
| **BCDT_RefreshToken** | UserId, Token, ExpiresAt, CreatedAt, CreatedByIp, RevokedAt, RevokedByIp, ReplacedByToken. Lưu refresh token; logout = set RevokedAt. |

Seed admin: Username `admin`, password hash tương ứng `Admin@123` (đã có trong 14.seed_data.sql – có thể cần cập nhật hash thật nếu seed dùng placeholder).

---

## 4. Kiến trúc gợi ý (theo BCDT)

- **BCDT.Api:** Controllers (AuthController), Middleware (JWT Bearer), đăng ký DbContext + JWT + services.
- **BCDT.Application:** DTOs (LoginRequest, LoginResponse, RefreshRequest, RefreshResponse, UserInfoDto), Interfaces (IAuthService, IJwtService), AuthService, JwtService (hoặc gộp vào AuthService).
- **BCDT.Infrastructure:** Repository/query User theo Username; hash password (verify); lưu/đọc/revoke RefreshToken. Có thể dùng EF Core cho BCDT_User và BCDT_RefreshToken.
- **BCDT.Domain:** Entity User, RefreshToken (nếu muốn); không chứa logic JWT.

**Nguyên tắc:** Controller chỉ gọi IAuthService; không gọi DbContext/Repository trực tiếp. Response theo format [04 mục 7](../script_core/04.GIAI_PHAP_KY_THUAT.md): `{ success, data }` / `{ success: false, errors: [{ code, message, field? }] }`.

---

## 5. Thứ tự triển khai gợi ý (cho AI)

1. **DbContext + Entity (Infrastructure/Domain)**  
   - Thêm DbSet `BCDT_User`, `BCDT_RefreshToken` (entity map đúng tên bảng/cột).  
   - Đăng ký DbContext với ConnectionStrings từ config.

2. **JWT options + IJwtService / JwtService (Application + Infrastructure)**  
   - Bind `Jwt:SecretKey`, `Issuer`, `Audience`, `ExpiryMinutes` từ config.  
   - IJwtService: `string GenerateAccessToken(int userId, string username, IEnumerable<string>? roles)`, `string GenerateRefreshToken()`, `(int? userId, bool valid) ValidateRefreshToken(string token)` (optional: validate và trả userId).  
   - Access token: claims gồm ít nhất `UserId` (NameIdentifier hoặc custom), `Username`, có thể `Role` (sau B2). Expiry = Jwt.ExpiryMinutes.

3. **IAuthService / AuthService (Application + Infrastructure)**  
   - `Result<LoginResponse> Login(LoginRequest request)` (Username, Password).  
     - Query User theo Username; verify password hash; nếu sai trả `Result.Fail` (UNAUTHORIZED).  
     - Tạo access_token (JwtService), refresh_token (random + lưu BCDT_RefreshToken, ExpiresAt = now + 7 ngày hoặc config).  
     - Trả `LoginResponse`: access_token, refresh_token, expires_in (giây), user: { id, username, email, fullName }.  
   - `Result<RefreshResponse> Refresh(RefreshRequest request)` (RefreshToken).  
     - Tìm BCDT_RefreshToken theo Token, chưa revoke, chưa hết hạn; lấy UserId; (tùy chọn) rotate: revoke cũ, tạo mới.  
     - Tạo access_token mới; trả RefreshResponse (access_token, expires_in, [refresh_token nếu rotate]).  
   - `Result Logout(RefreshRequest request)` hoặc `Logout(int userId, string? refreshToken)`.  
     - Cập nhật RevokedAt (và RevokedByIp nếu có) cho bản ghi RefreshToken tương ứng.

4. **DTOs & Request/Response (Application)**  
   - LoginRequest: Username, Password.  
   - LoginResponse: AccessToken, RefreshToken, ExpiresIn, User (UserInfoDto).  
   - RefreshRequest: RefreshToken.  
   - RefreshResponse: AccessToken, ExpiresIn, [RefreshToken].  
   - UserInfoDto: Id, Username, Email, FullName (không trả PasswordHash).

5. **AuthController (Api)**  
   - POST `/api/v1/auth/login` → body LoginRequest → gọi IAuthService.Login → trả 200 + data (LoginResponse) hoặc 401 + errors (UNAUTHORIZED).  
   - POST `/api/v1/auth/refresh` → body RefreshRequest → gọi IAuthService.Refresh → trả 200 + data hoặc 401.  
   - POST `/api/v1/auth/logout` → body RefreshRequest (hoặc chỉ cần Bearer token + refresh token) → gọi IAuthService.Logout → trả 200.

6. **Đăng ký dịch vụ (Program.cs)**  
   - AddDbContext\<TContext\>(ConnectionStrings).  
   - AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options => ...) (SecretKey, Issuer, Audience, ValidateLifetime).  
   - AddAuthorization().  
   - Đăng ký IAuthService, IJwtService (và Repository nếu tách).  
   - app.UseAuthentication(); app.UseAuthorization(); (thứ tự đúng).

7. **Swagger**  
   - Cấu hình Bearer auth cho Swagger UI để test gửi Authorization: Bearer \<token\>.

8. **Password hash**  
   - Seed admin trong 14.seed_data dùng Argon2 placeholder. Cần **tạo hash thật** cho password `Admin@123` và update vào DB (hoặc script one-off) để login được. Hoặc dùng thư viện verify Argon2 giống format seed; nếu khác format thì đổi seed hoặc đổi code verify.

---

## 6. Response format (chuẩn BCDT)

- **Login/Refresh success:**  
  `{ "success": true, "data": { "accessToken": "...", "refreshToken": "...", "expiresIn": 3600, "user": { "id": 1, "username": "admin", "email": "...", "fullName": "..." } } }`

- **Login/Refresh fail (sai mật khẩu hoặc token invalid):**  
  HTTP 401, `{ "success": false, "errors": [ { "code": "UNAUTHORIZED", "message": "Sai tên đăng nhập hoặc mật khẩu." } ] }`

- **Logout success:**  
  HTTP 200, `{ "success": true, "data": null }`

---

## 7. Kiểm tra sau khi triển khai

| Bước | Hành động |
|------|-----------|
| 1 | Chạy API; gọi POST `/api/v1/auth/login` với `{ "username": "admin", "password": "Admin@123" }` (sau khi đã có hash đúng trong DB). Kỳ vọng 200 + accessToken + refreshToken + user. |
| 2 | Gọi GET một endpoint cần auth (vd tạm GET `/api/v1/auth/me` trả user từ Claims) với header `Authorization: Bearer <accessToken>`. Kỳ vọng 200 + user. |
| 3 | Gọi POST `/api/v1/auth/refresh` với body `{ "refreshToken": "<refresh_token>" }`. Kỳ vọng 200 + accessToken mới. |
| 4 | Gọi POST `/api/v1/auth/logout` với body `{ "refreshToken": "..." }`. Sau đó gọi lại refresh với token đó; kỳ vọng 401. |
| 5 | Gửi request với accessToken hết hạn hoặc sai; kỳ vọng 401. |

---

## 7.1. Kiểm tra cho AI (tự chạy và báo kết quả)

**AI sau khi triển khai B1 (hoặc khi được yêu cầu kiểm tra B1) nên chạy lần lượt các bước dưới đây và báo Pass/Fail.**

1. **Build**
   - Lệnh: `dotnet build src/BCDT.Api/BCDT.Api.csproj`
   - Kỳ vọng: Build succeeded. Nếu Fail → báo lỗi.

2. **API đang chạy** (nếu chưa chạy: khởi động API trong nền, đợi vài giây)
   - Base URL mặc định: `https://localhost:7xxx` hoặc `http://localhost:5xxx` (xem `src/BCDT.Api/Properties/launchSettings.json`).

3. **Login**
   - Base URL: `http://localhost:5080` (hoặc `https://localhost:7115` – xem `BCDT.Api/Properties/launchSettings.json`).
   - Lệnh (PowerShell):  
     `Invoke-RestMethod -Uri "http://localhost:5080/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"Admin@123"}' -ContentType "application/json"`
   - Hoặc curl:  
     `curl -s -X POST "http://localhost:5080/api/v1/auth/login" -H "Content-Type: application/json" -d "{\"username\":\"admin\",\"password\":\"Admin@123\"}"`
   - Kỳ vọng: HTTP 200, body có `success: true`, `data.accessToken`, `data.refreshToken`, `data.user`. Nếu 401 → báo "Login Fail (sai mật khẩu hoặc chưa set PasswordHash)".

4. **Me (cần accessToken từ bước 3)**
   - Lệnh: gọi GET `/api/v1/auth/me` với header `Authorization: Bearer <accessToken>`.
   - Kỳ vọng: HTTP 200, `data` có `id`, `username`, `email`, `fullName`.

5. **Refresh**
   - Lệnh: POST `/api/v1/auth/refresh` body `{ "refreshToken": "<refresh_token_từ_bước_3>" }`.
   - Kỳ vọng: HTTP 200, có `data.accessToken`.

6. **Logout + Refresh lại**
   - POST `/api/v1/auth/logout` với `refreshToken` → 200. Sau đó POST `/api/v1/auth/refresh` với cùng token đó → kỳ vọng 401.

7. **MCP mssql (nếu có): kiểm tra admin có PasswordHash**
   - Query: `SELECT Id, Username, LEFT(PasswordHash,10) AS P FROM dbo.BCDT_User WHERE Username = N'admin'`
   - Kỳ vọng: 1 dòng, `P` bắt đầu bằng `$2a$` (BCrypt).

8. **Postman collection (kiểm thử thủ công)**
   - Tạo hoặc cập nhật collection trong `docs/postman/` (vd `BCDT-API.postman_collection.json`) với các request: Auth – Login, Me, Refresh, Logout; dùng biến `baseUrl`, `accessToken`, `refreshToken`; script Tests trong Login để lưu token vào biến.
   - **Tuân thủ chuẩn bắt buộc** trong rule [always-verify-after-work](.cursor/rules/always-verify-after-work.mdc) mục "Postman collection – chuẩn bắt buộc": `info._postman_id`, `request.url` dạng chuỗi, JSON hợp lệ, UTF-8. Sau khi ghi file, **chạy xác thực JSON** (vd `Get-Content docs/postman/BCDT-API.postman_collection.json -Raw -Encoding UTF8 | ConvertFrom-Json`) và chỉ báo Pass khi parse thành công.
   - Kỳ vọng: File JSON hợp lệ; import vào Postman, set `baseUrl` (vd `http://localhost:5080`), chạy Login → Me / Refresh / Logout theo thứ tự hoạt động đúng.

**Báo kết quả:** Liệt kê từng bước (1–8) kèm **Pass** hoặc **Fail** (và lỗi nếu có). Ví dụ: "1. Build: Pass. 2. API: Pass. 3. Login: Pass. … 8. Postman collection: Pass."

---

## 8. Lưu ý cho AI

- **Không** hardcode SecretKey, connection string; đọc từ IConfiguration.
- **Không** trả stack trace hay chi tiết lỗi DB ra response; log server-side.
- Dùng **Result\<T\>** (hoặc tương đương) trong service; controller map Result.Fail → HTTP 401/400 và errors.
- Sau B1 chưa cần RLS session context (B3); chỉ cần JWT validate và Claims (UserId, Username).
- Nếu seed admin chưa có password hash đúng: tạo hash cho `Admin@123` (Argon2 hoặc Identity) và cập nhật BCDT_User cho user admin, hoặc bổ sung script/migration one-off.

---

**Version:** 1.0  
**Ngày:** 2026-02-03
