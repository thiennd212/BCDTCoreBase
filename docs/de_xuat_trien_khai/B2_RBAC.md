# Đề xuất triển khai B2 – RBAC (cho AI)

Tài liệu hướng dẫn AI triển khai **B2: Role-Based Access Control** – policy/authorization theo Role và Permission (5 roles, matrix theo 03.DATABASE_SCHEMA); [Authorize] theo role/permission; không bypass RLS.

**Tham chiếu:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [03.DATABASE_SCHEMA.md](../script_core/03.DATABASE_SCHEMA.md) (Authorization, Permission Matrix), [04.GIAI_PHAP_KY_THUAT.md](../script_core/04.GIAI_PHAP_KY_THUAT.md) mục 8 (Phân quyền endpoint).

---

## Agents, Skills và Rules áp dụng cho B2

| Agent | Khi nào dùng |
|-------|---------------|
| **bcdt-auth-expert** | Triển khai B2 (policy, role/permission). Chọn agent này khi giao task B2. |

| Rule | Mục đích |
|------|----------|
| **senior-fullstack-standards** | SOLID, error handling, async. |
| **bcdt-project** | Layer API → Application → Domain → Infrastructure. |
| **bcdt-database** | Parameterized query, **không bypass RLS**. |
| **always-verify-after-work** | Sau khi làm xong: build, chạy đủ test cases (mục 7.1), báo Pass/Fail từng bước. |

---

## 1. Mục tiêu B2

| Deliverable | Mô tả |
|-------------|--------|
| Role trong JWT | Khi login/refresh, lấy danh sách Role (Code) của user từ BCDT_UserRole + BCDT_Role, đưa vào JWT (ClaimTypes.Role). |
| Policy theo Role | Dùng [Authorize(Roles = "SYSTEM_ADMIN,FORM_ADMIN")] hoặc policy tên; trả 403 khi không đủ role. |
| (Tùy chọn) Policy theo Permission | Policy kiểm tra quyền (vd Form.View) từ DB hoặc từ claim; trả 403 khi không có quyền. |

---

## 2. Đặc tả kỹ thuật (theo 03.DATABASE_SCHEMA, 04.GIAI_PHAP_KY_THUAT)

1. **5 roles (Code):** SYSTEM_ADMIN, FORM_ADMIN, UNIT_ADMIN, DATA_ENTRY, VIEWER. Seed đã có trong 14.seed_data.sql.
2. **UserRole:** BCDT_UserRole (UserId, RoleId, OrganizationId, IsActive). Lấy Role.Code từ join BCDT_Role.
3. **JWT:** GenerateAccessToken(userId, username, roles) đã hỗ trợ tham số roles; cần gọi với danh sách role Code khi login/refresh.
4. **Authorization:** AddAuthorization(); [Authorize], [Authorize(Roles = "...")]; trả 403 Forbidden khi thiếu quyền (04.GIAI_PHAP_KY_THUAT mục 7.3, 8).

---

## 3. Kiến trúc gợi ý

- **AuthService (Login/Refresh):** Query role codes của user (BCDT_UserRole join BCDT_Role, IsActive = 1), truyền vào IJwtService.GenerateAccessToken(..., roles).
- **API:** Endpoint cần bảo vệ: [Authorize] (chỉ cần đăng nhập) hoặc [Authorize(Roles = "SYSTEM_ADMIN")] (theo role). Không bypass RLS; session context đã set bởi B3 middleware.

---

## 4. Bảng DB liên quan

| Bảng | Mô tả |
|------|--------|
| BCDT_Role | Id, Code (SYSTEM_ADMIN, FORM_ADMIN, …), Name, Level, IsActive. |
| BCDT_UserRole | UserId, RoleId, OrganizationId, IsActive, ValidFrom, ValidTo. |
| BCDT_Permission | Code (Form.View, Submission.Submit, …). |
| BCDT_RolePermission | RoleId, PermissionId. |

---

## 5. Thứ tự triển khai gợi ý

1. (Nếu chưa có) Thêm entity/mapping cho Role, UserRole trong Domain/Infrastructure để query role codes; hoặc dùng raw SQL/Dapper.
2. AuthService: khi LoginAsync và RefreshAsync, lấy danh sách Role.Code của user, gọi GenerateAccessToken(userId, username, roleCodes).
3. Giữ AddAuthorization(); áp [Authorize] hoặc [Authorize(Roles = "...")] lên endpoint cần bảo vệ.
4. (Tùy chọn) Thêm policy theo permission (IAuthorizationHandler + Requirement) nếu cần kiểm tra theo từng quyền.

---

## 6. Kiểm tra sau khi triển khai

| Bước | Hành động | Kỳ vọng |
|------|-----------|---------|
| 1 | Build | Build succeeded. |
| 2 | Login, kiểm tra JWT payload | Có claim role (vd System.Claims.ClaimsIdentity có Role = SYSTEM_ADMIN). |
| 3 | GET /api/v1/auth/me với Bearer token | 200, response có user. |
| 4 | Gọi endpoint [Authorize(Roles = "SYSTEM_ADMIN")] với user có role SYSTEM_ADMIN | 200 (hoặc 200/404 tùy endpoint). |
| 5 | Gọi endpoint [Authorize(Roles = "FORM_ADMIN")] với user chỉ có DATA_ENTRY | 403 Forbidden. |

---

## 7.1. Kiểm tra cho AI (tự chạy và báo kết quả)

1. **Build:** `dotnet build src/BCDT.Api/BCDT.Api.csproj` → Build succeeded.
2. **API đang chạy:** Khởi động API (base URL http://localhost:5080).
3. **Login + Me:** Login với admin/Admin@123; GET /api/v1/auth/me với Bearer token → 200, có user.
4. **JWT có role:** Decode JWT (accessToken), kiểm tra có claim "role" (vd SYSTEM_ADMIN).
5. **Me không token:** GET /api/v1/auth/me không header Authorization → 401.
6. (Nếu có endpoint bảo vệ theo role) User có role → 200; user không có role → 403.

**Báo kết quả:** Liệt kê từng bước (1–6) kèm **Pass** hoặc **Fail**.

---

**Version:** 1.0  
**Ngày:** 2026-02-04
