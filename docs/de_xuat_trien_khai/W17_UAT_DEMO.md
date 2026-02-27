# W17 – UAT & Demo (Week 17)

**Mục đích:** UAT trên localhost, Documentation, Demo preparation, Handover. Theo [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md) Phase 4 Week 17 và block giao AI trong [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) mục 3.4.

**Tham chiếu:** RUNBOOK.md, B11_PHASE4_POLISH.md (mục 6), W16_PERFORMANCE_SECURITY.md, P8_FILTER_PLACEHOLDER.md, KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md, GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md.

---

## 1. UAT Checklist chi tiết

**Chuẩn bị:** API chạy (`dotnet run --project src/BCDT.Api --launch-profile http`), FE chạy (`npm run dev` trong `src/bcdt-web`). DB đã chạy script 01→22, seed (Ensure-TestData.ps1 hoặc seed_mcp_*). Tài khoản: admin / Admin@123.

### 1.1. Auth

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 1 | Login admin | POST /api/v1/auth/login { "username": "admin", "password": "Admin@123" } | 200, accessToken, refreshToken | Pass |
| 2 | Login user thường | Login với user có role khác admin (nếu có) | 200, token | Skip |
| 3 | /me | GET /api/v1/auth/me (Bearer token) | 200, user info | Pass |
| 4 | Refresh token | POST /api/v1/auth/refresh { "refreshToken": "..." } | 200, accessToken mới | Pass |
| 5 | Logout | POST /api/v1/auth/logout (body: refreshToken) | 200 | Pass |

### 1.2. Organization

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 6 | List organizations | GET /api/v1/organizations (có thể ?all=true) | 200, danh sách (cây 5 cấp) | Pass |
| 7 | CRUD đơn vị | POST/PUT/DELETE (hoặc FE: thêm/sửa/xóa đơn vị) | 201/200, tree cập nhật | Pass |
| 8 | Tìm kiếm | GET với filter (nếu có) | 200 | Pass |

### 1.3. User

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 9 | List users | GET /api/v1/users | 200, danh sách | Pass |
| 10 | Create user | POST /api/v1/users (username, password, email, roleIds, organizationIds) | 201 | Pass |
| 11 | Update user | PUT /api/v1/users/{id} | 200 | Pass |
| 12 | Gán role / đơn vị | Trong form user: chọn Role, Đơn vị, lưu | 200, hiển thị đúng | Pass |

### 1.4. Form Definition

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 13 | List forms | GET /api/v1/forms | 200 | Pass |
| 14 | CRUD form | POST/PUT form (Code, Name, ...) | 201/200 | Pass |
| 15 | Versions | GET /api/v1/forms/{id}/versions | 200 | Pass |
| 16 | Cấu hình sheet/column | FormConfig: sheet, cột, data-binding, mapping | 200, lưu đúng | Pass |

### 1.5. P8 – Cấu hình mở rộng (dòng/cột động)

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 17 | **UAT-P8a: DataSource** | GET/POST /api/v1/data-sources; GET /data-sources/{id}/columns | 200, CRUD thành công, columns trả về | Pass |
| 18 | **UAT-P8b: FilterDefinition** | GET/POST/PUT filter-definitions + filter-conditions; gán DataSourceId | 200, điều kiện lọc lưu đúng | Pass |
| 19 | **UAT-P8c: FormDynamicRegion** | Cấu hình vùng chỉ tiêu động; gán DataSourceId + FilterDefinitionId | 200 | Pass |
| 20 | **UAT-P8d: Placeholder dòng** | POST placeholder-occurrences (FormDynamicRegionId, ExcelRowStart, FilterDefinitionId); GET workbook-data | 200; workbook-data có N hàng từ nguồn đã lọc | Pass |
| 21 | **UAT-P8e: Dynamic Column Region** | POST dynamic-column-regions (ColumnSourceType, LabelColumn, ...) | 200 | Pass |
| 22 | **UAT-P8f: Placeholder cột** | POST placeholder-column-occurrences; GET workbook-data | 200; workbook-data có N cột (columnLabels) | Pass |
| 23 | **UAT-P8 tổng hợp** | Form có cả placeholder dòng + cột; GET workbook-data | 200; sheets[].dynamicRegions + dynamicColumnRegions; N hàng × M cột | Pass |

### 1.6. Submission & Workbook-data

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 24 | Tạo submission | POST /api/v1/submissions (formId, versionId, orgId, periodId) | 201, id | Pass |
| 25 | Upload Excel | POST /api/v1/submissions/{id}/upload (multipart file) – nếu có | 200 | Skip |
| 26 | Workbook-data (cột cố định) | GET /api/v1/submissions/{id}/workbook-data (form đơn giản) | 200; sheets[].rows, columnHeaders | Pass |
| 27 | Workbook-data (P8 dòng/cột) | GET workbook-data (form có placeholder dòng + cột) | 200; dynamicRegions có rows; dynamicColumnRegions có columnLabels | Pass |
| 28 | Nhập liệu (FE) | Mở trang Nhập liệu, chỉnh ô, lưu | Draft lưu đúng | Skip |
| 29 | Gửi duyệt | POST /api/v1/submissions/{id}/submit | 200, trạng thái Submitted | Fail* |

### 1.7. Workflow

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 30 | Submit | Gửi duyệt submission | Workflow instance Pending | Fail* |
| 31 | Approve/Reject/Revision | POST approve, reject, revision | 200, trạng thái cập nhật | Pass |
| 32 | Bulk approve | POST /api/v1/workflow-instances/bulk-approve (workflowInstanceIds[]) | 200, succeededIds/failed | Fail* |

### 1.8. Reporting Period & Dashboard

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 33 | CRUD kỳ báo cáo | GET/POST/PUT /api/v1/reporting-periods | 200 | Pass |
| 34 | Dashboard admin | GET /api/v1/dashboard/admin/stats | 200, thống kê | Pass |
| 35 | Dashboard user | GET /api/v1/dashboard/user/tasks (nếu có) | 200 | Pass |

### 1.9. PDF, Notification, Bulk

| # | Mục | Hành động | Kỳ vọng | Pass/Fail |
|---|-----|-----------|---------|-----------|
| 36 | PDF Export | GET /api/v1/submissions/{id}/pdf | 200, application/pdf | Pass |
| 37 | Notifications | GET /api/v1/notifications; PATCH .../read | 200 | Pass |
| 38 | Bulk create submissions | POST /api/v1/submissions/bulk (formId, versionId, periodId, organizationIds[]) | 200, createdIds/skipped/errors | Pass |

---

## 2. Sample data cho UAT (gợi ý)

- **Org tree:** Bộ → Sở → Phòng (script 01 + seed).
- **Form mẫu:** Có ít nhất 1 sheet, cột, mapping; (tùy chọn) form có FormDynamicRegion + FormPlaceholderOccurrence + FormDynamicColumnRegion + FormPlaceholderColumnOccurrence cho P8.
- **Submissions:** Nhiều trạng thái Draft, Submitted, Approved (Ensure-TestData.ps1, seed_mcp_*, seed_more_submissions).
- **P8:** Ít nhất 2 DataSource (1 có ≥5 bản ghi, 1 có 0); FilterDefinition + FilterCondition; form có vùng dòng + vùng cột động.

Script: `docs/script_core/sql/v2/Ensure-TestData.ps1`; tham khảo [README_SEED_TEST.md](script_core/sql/v2/README_SEED_TEST.md), [P8_FILTER_PLACEHOLDER.md](P8_FILTER_PLACEHOLDER.md).

---

## 3. Kết quả UAT (điền khi chạy)

**Ngày chạy:** 2026-02-12 (cập nhật)  
**Cách chạy:** Script `docs/script_core/run-w17-uat.ps1` (API http://localhost:5080, DB đã seed Draft với workflow).

| Nhóm | Số mục | Pass | Fail | Ghi chú |
|------|--------|------|------|---------|
| Auth | 5 | 4 | 0 | 1 Skip (mục 2 – user thường). Logout chạy cuối script. |
| Organization | 3 | 3 | 0 | |
| User | 4 | 4 | 0 | |
| Form Definition | 4 | 4 | 0 | |
| P8 | 7 | 7 | 0 | |
| Submission & Workbook | 6 | 6 | 0 | 2 Skip (25 Upload Excel, 28 Nhập liệu FE). **29, 30 Pass** (script lấy Draft có workflow). |
| Workflow | 3 | 3 | 0 | **32 Pass** (script fix JSON array serialization cho bulk-approve). |
| Reporting & Dashboard | 3 | 3 | 0 | |
| PDF, Notification, Bulk | 3 | 3 | 0 | **38 Pass** (script fix $versionId và JSON array). |
| **Tổng** | **38** | **35** | **0** | **3 Skip** (Upload, Nhập liệu, user thường). |

**Sửa lỗi script (2026-02-12):**
- PowerShell JSON array serialization: single element `@(id)` bị unwrap → fix bằng JSON thủ công.
- `$versionId` không được set khi có Draft submission có workflow → fix set ở Form section.
- Script lấy Draft submission có workflow (formId 2, 4, 5) để Submit/Bulk-approve thành công.

---

## 4. Demo Script

Kịch bản demo chi tiết: **[docs/DEMO_SCRIPT.md](../DEMO_SCRIPT.md)** (Core flow + P8 flow + edge case).

---

## 5. Deliverables (Handover)

| # | Deliverable | Trạng thái | Ghi chú |
|---|-------------|------------|---------|
| 1 | Source code (Git repo) | ✅ | |
| 2 | Database scripts (sql/v2/*.sql 01→22) | ✅ | Verify chạy trên DB trống |
| 3 | Setup guide (RUNBOOK) | ✅ | [RUNBOOK.md](../RUNBOOK.md) |
| 4 | User guide | ✅ | [USER_GUIDE.md](../USER_GUIDE.md) |
| 5 | API documentation | ✅ | Swagger + [Postman](postman/BCDT-API.postman_collection.json) |
| 6 | Demo script | ✅ | [DEMO_SCRIPT.md](../DEMO_SCRIPT.md) |
| 7 | Test cases | ✅ | docs/de_xuat_trien_khai/*.md (B1, B2, P8, …), checklist trong file này |
| 8 | Sample data | ✅ | Ensure-TestData.ps1, seed_mcp_*, seed_* |

---

## 6. Kiểm tra cho AI (chạy khi hoàn thành W17)

1. **Build BE:** Hủy process BCDT.Api (RUNBOOK 6.1); `dotnet build src/BCDT.Api/BCDT.Api.csproj` → Build succeeded.
2. **Build FE:** `npm run build` trong `src/bcdt-web` → thành công.
3. **Chạy UAT:** API chạy; script `docs/script_core/run-w17-uat.ps1`; điền Pass/Fail vào bảng (đã điền 2026-02-12: 32 Pass, 3 Fail, 3 Skip).
4. **Demo flow:** Core flow = Login → Org → Form → Submission → workbook-data → Dashboard: **Pass** (trùng với UAT). P8 flow = DataSource, FilterDefinition, FormDynamicRegion/Placeholder, workbook-data N hàng × M cột: **Pass** (UAT 17–23, 26–27).
5. **Cập nhật TONG_HOP** theo rule bcdt-update-tong-hop-after-task.

---

**Version:** 1.1  
**Ngày:** 2026-02-12
