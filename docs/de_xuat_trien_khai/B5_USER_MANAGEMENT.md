# Đề xuất triển khai B5 – User management CRUD (cho AI)

Tài liệu hướng dẫn AI triển khai **B5: User management CRUD** – API /api/v1/users, CRUD user; gán UserRole, UserOrganization; không bypass RLS.

**Tham chiếu:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [03.DATABASE_SCHEMA.md](../script_core/03.DATABASE_SCHEMA.md) (Organization + Authorization), [04.GIAI_PHAP_KY_THUAT.md](../script_core/04.GIAI_PHAP_KY_THUAT.md) (1.4 RLS).

---

## Agents, Skills và Rules áp dụng cho B5

| Agent | Khi nào dùng |
|-------|---------------|
| **bcdt-org-admin** | Triển khai B5 (User CRUD + gán role/org). Chọn agent này khi giao task B5. |

| Skill | Mục đích |
|-------|----------|
| **bcdt-entity-crud** | Controller, Service, DTOs, Validator. |
| **bcdt-api-endpoint** | REST conventions, response format. |

| Rule | Mục đích |
|------|----------|
| **always-verify-after-work** | Build, test cases, báo Pass/Fail. |
| **bcdt-project** | API → Application → Domain → Infrastructure; không đưa domain logic vào controller. |
| **bcdt-database** | Parameterized query, **không bypass RLS**. |
| **senior-fullstack-standards** | SOLID, error handling, async. |

---

## 1. Mục tiêu B5

| Deliverable | Mô tả |
|-------------|--------|
| API /api/v1/users | GET (list, filter), GET by id, POST (tạo user + gán role/org), PUT (cập nhật + gán role/org), DELETE (soft delete). |
| Entity UserOrganization | Domain + EF mapping BCDT_UserOrganization (User đã có trong Authentication). |
| DTOs, Service, Controller | UserDto (kèm RoleIds, OrganizationIds), CreateUserRequest, UpdateUserRequest; IUserService; UsersController. |

---

## 2. Đặc tả kỹ thuật (theo 01.organization.sql, 02.authorization.sql)

- **BCDT_User:** Id, Username, PasswordHash, Email, FullName, Phone, Avatar, AuthProvider, IsActive, IsDeleted, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy, …
- **BCDT_UserRole:** UserId, RoleId, OrganizationId (nullable), IsActive, GrantedBy, GrantedAt (SQL có thêm ValidFrom, ValidTo, Revoked*).
- **BCDT_UserOrganization:** UserId, OrganizationId, IsPrimary, IsActive, JoinedAt, LeftAt, CreatedAt, CreatedBy.
- **Gán role:** Khi tạo/cập nhật user, nhận danh sách roleIds (và tùy chọn organizationId cho từng role). Sync: xóa bớt UserRole không còn trong danh sách, thêm mới những role chưa có.
- **Gán org:** Nhận danh sách organizationIds (và IsPrimary cho một org). Sync UserOrganization tương tự.

---

## 3. Kiến trúc gợi ý

- **Domain:** Entity UserOrganization (User, UserRole, Role, Organization đã có).
- **Infrastructure:** AppDbContext thêm DbSet UserOrganizations; cấu hình FK UserId, OrganizationId.
- **Application:** IUserService (GetById, GetList, Create, Update, Delete); UserDto (Id, Username, Email, FullName, RoleIds, OrganizationIds); CreateUserRequest (Username, Password, Email, FullName, RoleIds, OrganizationIds, IsPrimaryOrganizationId?); UpdateUserRequest (có thể đổi mật khẩu optional).
- **API:** [Authorize] UsersController; response chuẩn ApiSuccessResponse/ApiErrorResponse.

---

## 4. Kiểm tra sau khi triển khai

Xem mục **7.1. Kiểm tra cho AI** bên dưới; AI tự chạy đủ bước và báo Pass/Fail từng bước trước khi báo xong.

---

## 7.1. Kiểm tra cho AI (tự chạy và báo kết quả)

**AI sau khi triển khai B5 (hoặc khi được yêu cầu kiểm tra B5) nên chạy lần lượt các bước dưới đây và báo Pass/Fail.**

1. **Build**
   - Lệnh: `dotnet build src/BCDT.Api/BCDT.Api.csproj`
   - Kỳ vọng: Build succeeded.

2. **API đang chạy**
   - Khởi động API (vd `dotnet run --project src/BCDT.Api/BCDT.Api.csproj --launch-profile http`). Base URL: `http://localhost:5080`.

3. **Login + lấy Bearer token**
   - Login: `Invoke-RestMethod -Uri "http://localhost:5080/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"Admin@123"}' -ContentType "application/json"`.
   - Lấy `data.accessToken` từ response.

4. **GET /api/v1/users (có auth)**
   - GET `/api/v1/users` với header `Authorization: Bearer <accessToken>`.
   - Kỳ vọng: 200, `success: true`, `data` là mảng (có thể rỗng hoặc có admin).

5. **GET /api/v1/users không token**
   - GET `/api/v1/users` **không** gửi header Authorization.
   - Kỳ vọng: 401 Unauthorized.

6. **GET /api/v1/users/{id} (trước khi tạo user mới)**
   - GET `/api/v1/users/99999` với Bearer token (id không tồn tại).
   - Kỳ vọng: 404.

7. **POST /api/v1/users (tạo user mới)**
   - POST với body hợp lệ: `{ "username": "user1", "password": "Pass@123", "email": "user1@test.local", "fullName": "User One", "isActive": true, "roleIds": [1], "organizationIds": [], "primaryOrganizationId": null }`. Bearer token. (roleIds: seed có Role id=1; organizationIds có thể rỗng nếu chưa có đơn vị; nếu đã có Organization id=1 thì dùng [1] và primaryOrganizationId: 1.)
   - Kỳ vọng: 200, `success: true`, `data` có Id mới.

8. **GET /api/v1/users/{id} (sau khi tạo)**
   - GET `/api/v1/users/{id}` với id vừa tạo. Bearer token.
   - Kỳ vọng: 200, `success: true`, `data` trùng username/email; có roleIds, organizationIds.

9. **PUT /api/v1/users/{id}**
   - PUT với body: `{ "email": "user1@updated.local", "fullName": "User One Updated", "isActive": true, "roleIds": [1], "organizationIds": [], "primaryOrganizationId": null }` (hoặc có [1] nếu đã có org). Bearer token.
   - Kỳ vọng: 200, `success: true`, `data` đã cập nhật.

10. **DELETE /api/v1/users/{id}**
    - DELETE `/api/v1/users/{id}` với id user vừa tạo (không xóa admin). Bearer token.
    - Kỳ vọng: 200, `success: true`.

11. **GET /api/v1/users/{id} (sau khi xóa)**
    - GET `/api/v1/users/{id}` với id vừa xóa. Bearer token.
    - Kỳ vọng: 404 (đã soft delete).

12. **Postman collection**
    - Cập nhật `docs/postman/BCDT-API.postman_collection.json` thêm folder Users với request List, Get by ID (và tùy chọn POST/PUT/DELETE). Xác thực JSON parse.

**Báo kết quả:** Liệt kê từng bước (1–12) kèm **Pass** hoặc **Fail** (và lỗi nếu có). **Không skip** bước nào.

**Chạy nhanh:** `powershell -ExecutionPolicy Bypass -File scripts/test-b5-checklist.ps1` (API phải đang chạy trên http://localhost:5080; bước 1 Build và 2 API chạy trước).

---

**Version:** 1.1  
**Ngày:** 2026-02-05  
**Checklist 7.1:** Đã chạy đủ 12 bước – **tất cả Pass** (2026-02-05).
