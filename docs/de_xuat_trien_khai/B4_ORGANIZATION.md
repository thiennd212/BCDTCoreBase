# Đề xuất triển khai B4 – Organization CRUD (cho AI)

Tài liệu hướng dẫn AI triển khai **B4: Organization CRUD** – API /api/v1/organizations, cây 5 cấp; entity Organization, OrganizationType; không bypass RLS.

**Tham chiếu:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [03.DATABASE_SCHEMA.md](../script_core/03.DATABASE_SCHEMA.md) (Organization module), [01.organization.sql](../script_core/sql/v2/01.organization.sql).

---

## Agents, Skills và Rules áp dụng cho B4

| Agent | Khi nào dùng |
|-------|---------------|
| **bcdt-org-admin** | Triển khai B4 (Organization CRUD). Chọn agent này khi giao task B4. |

| Skill | Mục đích |
|-------|-----------|
| **bcdt-entity-crud** | Controller, Service, Repository, DTOs, Validator. |
| **bcdt-api-endpoint** | REST conventions, paging, response format. |

| Rule | Mục đích |
|------|----------|
| **always-verify-after-work** | Build, test cases, báo Pass/Fail. |
| **bcdt-project** | API → Application → Domain → Infrastructure; không đưa domain logic vào controller. |
| **bcdt-database** | Parameterized query, **không bypass RLS**. |
| **senior-fullstack-standards** | SOLID, error handling, async. |

---

## 1. Mục tiêu B4

| Deliverable | Mô tả |
|-------------|--------|
| API /api/v1/organizations | GET (list, cây 5 cấp / filter parentId, typeId), GET by id, POST, PUT, DELETE (soft delete). |
| Entity Organization, OrganizationType | Domain + EF mapping BCDT_Organization, BCDT_OrganizationType. |
| DTOs, Service, Controller | OrganizationDto, CreateOrganizationRequest, UpdateOrganizationRequest; IOrganizationService; OrganizationsController. |

---

## 2. Đặc tả kỹ thuật (theo 01.organization.sql)

- **BCDT_OrganizationType:** Id, Code, Name, Level (1–5), ParentTypeId, Description, IsActive.
- **BCDT_Organization:** Id, Code, Name, ShortName, OrganizationTypeId, ParentId, TreePath, Level, Address, Phone, Email, TaxCode, IsActive, DisplayOrder, IsDeleted.
- Cây 5 cấp: ParentId, TreePath (/1/5/12/), Level. List có thể filter theo ParentId (null = root), OrganizationTypeId.

---

## 3. Kiến trúc gợi ý

- **Domain:** OrganizationType, Organization entities.
- **Infrastructure:** AppDbContext DbSet OrganizationType, Organization; mapping bảng BCDT_*.
- **Application:** IOrganizationService (GetById, GetList, Create, Update, Delete); DTOs; Validator (Code, Name required).
- **API:** [Authorize] OrganizationsController; response chuẩn ApiSuccessResponse/ApiErrorResponse.

---

## 4. Kiểm tra sau khi triển khai

Xem mục **7.1. Kiểm tra cho AI** bên dưới; AI tự chạy đủ bước và báo Pass/Fail từng bước trước khi báo xong.

---

## 7.1. Kiểm tra cho AI (tự chạy và báo kết quả)

**AI sau khi triển khai B4 (hoặc khi được yêu cầu kiểm tra B4) nên chạy lần lượt các bước dưới đây và báo Pass/Fail.**

1. **Build**
   - Lệnh: `dotnet build src/BCDT.Api/BCDT.Api.csproj`
   - Kỳ vọng: Build succeeded. Nếu build Fail do file lock bởi BCDT.Api: tắt process BCDT.Api rồi build lại (theo rule always-verify-after-work).

2. **API đang chạy**
   - Khởi động API (vd `dotnet run --project src/BCDT.Api/BCDT.Api.csproj --launch-profile http`). Base URL: `http://localhost:5080`.

3. **Login + lấy Bearer token**
   - Login: `Invoke-RestMethod -Uri "http://localhost:5080/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"Admin@123"}' -ContentType "application/json"`.
   - Lấy `data.accessToken` từ response (dùng cho các request tiếp theo).

4. **GET /api/v1/organizations (có auth)**
   - GET `/api/v1/organizations` với header `Authorization: Bearer <accessToken>`.
   - Kỳ vọng: 200, `success: true`, `data` là mảng (có thể rỗng). Không bypass RLS (session context đã set bởi B3).

5. **GET /api/v1/organizations không token**
   - GET `/api/v1/organizations` **không** gửi header Authorization.
   - Kỳ vọng: 401 Unauthorized.

6. **GET /api/v1/organizations/{id} (trước khi có dữ liệu)**
   - GET `/api/v1/organizations/1` với Bearer token.
   - Kỳ vọng: 404 (không tìm thấy) khi chưa có org id=1.

7. **POST /api/v1/organizations (bắt buộc)**
   - POST với body hợp lệ: `{ "code": "ORG01", "name": "Đơn vị test", "organizationTypeId": 1, "parentId": null, "isActive": true, "displayOrder": 0 }`. Bearer token.
   - Kỳ vọng: 200, `success: true`, `data` có Id mới (vd id=1).

8. **GET /api/v1/organizations/{id} (sau khi tạo)**
   - GET `/api/v1/organizations/{id}` với id vừa tạo. Bearer token.
   - Kỳ vọng: 200, `success: true`, `data` trùng code/name.

9. **PUT /api/v1/organizations/{id} (bắt buộc)**
   - PUT với body: `{ "code": "ORG01", "name": "Đơn vị test (đã sửa)", "organizationTypeId": 1, "parentId": null, "isActive": true, "displayOrder": 0 }`. Bearer token.
   - Kỳ vọng: 200, `success: true`, `data.name` đã đổi.

10. **DELETE /api/v1/organizations/{id} (bắt buộc)**
    - DELETE `/api/v1/organizations/{id}` với Bearer token.
    - Kỳ vọng: 200, `success: true`.

11. **GET /api/v1/organizations/{id} (sau khi xóa)**
    - GET `/api/v1/organizations/{id}` với id vừa xóa. Bearer token.
    - Kỳ vọng: 404 (đã soft delete).

12. **Postman collection**
    - Cập nhật `docs/postman/BCDT-API.postman_collection.json` nếu B4 thêm endpoint; xác thực JSON parse.

**Báo kết quả:** Liệt kê từng bước (1–12) kèm **Pass** hoặc **Fail** (và lỗi nếu có). **Không skip** bước nào.

---

**Version:** 1.1  
**Ngày:** 2026-02-04
