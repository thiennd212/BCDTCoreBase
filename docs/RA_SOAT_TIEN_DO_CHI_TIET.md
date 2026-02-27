# Rà soát chi tiết toàn bộ tiến độ công việc – BCDT

Tài liệu tổng hợp **trạng thái từng hạng mục** công việc: đã hoàn thành, chưa làm, và thứ tự ưu tiên. Tham chiếu: [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md](de_xuat_trien_khai/KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md), [06.KE_HOACH_MVP.md](script_core/06.KE_HOACH_MVP.md).

**Ngày rà soát:** 2026-02-11

---

## 1. Công việc đã hoàn thành (MVP Phase 1–4 đến hết W15)

### 1.1. Setup & Foundation

| Mã | Hạng mục | Trạng thái | Tài liệu / Ghi chú |
|----|-----------|------------|---------------------|
| A1 | SQL schema 01→22 (59 bảng, RLS, seed) | ✅ Đã xong | script_core/sql/v2/, VERIFY_TABLES.md |
| A2 | appsettings, RUNBOOK, Build BE | ✅ Đã xong | RUNBOOK.md |
| B1 | JWT Auth (login, refresh, logout, /me) | ✅ Đã xong | B1_JWT.md |
| B2 | RBAC (5 roles, policy FormStructureAdmin) | ✅ Đã xong | B2_RBAC.md – *chưa có quản lý vai trò/quyền, chưa User-Role-Org* |
| B3 | RLS & Session Context | ✅ Đã xong | B3_RLS.md |
| B4 | Organization CRUD (cây 5 cấp) | ✅ Đã xong | B4_ORGANIZATION.md |
| B5 | User Management CRUD | ✅ Đã xong | B5_USER_MANAGEMENT.md – *gán RoleIds + OrganizationIds tách nhau; UserRole luôn OrganizationId=null* |
| B6 | Frontend (Login, Org/User, Tree đơn vị, E2E) | ✅ Đã xong | B6_FRONTEND.md, B6_DE_XUAT_TREE_DON_VI.md |

### 1.2. Form & Data

| Mã | Hạng mục | Trạng thái | Tài liệu / Ghi chú |
|----|-----------|------------|---------------------|
| B7 | Form Definition CRUD | ✅ Đã xong | B7_FORM_DEFINITION.md |
| B8 | Sheet, Column, Data Binding, Mapping (25/25 Pass) | ✅ Đã xong | B8_FORM_SHEET_COLUMN_DATA_BINDING.md |
| — | Excel Generator, Data Storage, Submission, Data Binding Resolver | ✅ Đã xong | — |
| — | Nhập liệu Excel (Fortune-sheet, workbook-data, export .xlsx) | ✅ Đã xong | FORTUNE_EXCEL_STYLES_FIX.md, SEED_VIA_MCP.md |

### 1.3. Workflow & Reporting

| Mã | Hạng mục | Trạng thái | Tài liệu / Ghi chú |
|----|-----------|------------|---------------------|
| B9 | Workflow (submit, approve/reject/revision) | ✅ Đã xong | B9_WORKFLOW.md |
| B10 | Reporting Period, Aggregation, Dashboard | ✅ Đã xong | B10_REPORTING_PERIOD.md |

### 1.4. Phase 4 W15 – Polish

| Mã | Hạng mục | Trạng thái | Tài liệu / Ghi chú |
|----|-----------|------------|---------------------|
| B11 | PDF Export, Notification (in-app + email mock), Bulk | ✅ Đã xong | B11_PHASE4_POLISH.md |
| — | FE Phase 2–3 (Dashboard, Forms, Submissions, Workflow UI) | ✅ Đã xong | FE_PHASE2_3.md |
| B12 | P1–P7 Chỉ tiêu cố định & động (R1–R11) | ✅ Đã xong | B12_CHI_TIEU_CO_DINH_DONG.md |
| P8 | P8a–P8f Lọc động, placeholder dòng + cột | ✅ Đã xong | P8_FILTER_PLACEHOLDER.md, KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md |

### 1.5. Hạ tầng & công cụ

| Hạng mục | Trạng thái | Ghi chú |
|----------|------------|---------|
| Cấu trúc codebase, Giải pháp kỹ thuật, Workflow Guide | ✅ | CẤU_TRÚC_CODEBASE.md, 04.GIAI_PHAP_KY_THUAT.md, WORKFLOW_GUIDE.md |
| Postman collection (~150 requests, P8 + workbook-data, Notifications, Audit) | ✅ | postman/BCDT-API.postman_collection.json |
| Seed test data, Ensure-TestData.ps1, script test | ✅ | README_SEED_TEST.md, scripts seed + test-* |
| HIERARCHICAL_DATA_BASE_AND_RULE | ✅ | Tài liệu + base phân cấp |

---

## 2. Công việc chưa làm – MVP (06.KE_HOACH_MVP)

| Mã | Hạng mục | Trạng thái | Ghi chú |
|----|-----------|------------|---------|
| W16 | Week 16 – Performance & Security | ✅ Đã xong | Baseline đo (w16-measure-baseline.ps1), OWASP Pass, tối ưu batch DataSource. [W16_PERFORMANCE_SECURITY.md](de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md). |
| W17 | Week 17 – UAT, Documentation, Demo | ⏳ Chưa làm (ưu tiên tiếp) | UAT checklist (gồm P8), User Guide, Demo Script, Handover. Block giao AI trong TONG_HOP mục 3.4. |

### 2.1. Công việc tùy chọn (MVP)

| Hạng mục | Trạng thái | Ghi chú |
|----------|------------|---------|
| Kiểm tra thủ công Refresh token FE | Chưa làm | RA_SOAT_REFRESH_TOKEN.md mục 5.1 |
| Phân cấp Menu / ReferenceEntity (tree) | Chưa làm | HIERARCHICAL_DATA_BASE_AND_RULE.md |

### 2.2. Thiếu sót nhỏ (Post-MVP / bổ sung)

| # | Phạm vi | Mô tả |
|---|---------|--------|
| 1 | BE Entity | 10 entity có DB chưa C#: Permission, RolePermission, Menu, RoleMenu, DataScope, RoleDataScope, UserDelegation, FormCell, SystemConfig, AuditLog. |
| 2 | FE | Trang quản lý WorkflowDefinitions / WorkflowSteps (admin). |
| 3 | Postman | ~17 endpoints thiếu (Forms from-template/upload/display, Workflow CRUD, ReportingPeriods by id, sync-from-presentation, v.v.). |

---

## 3. Công việc User–Role–Org & Quản lý vai trò/quyền (chưa làm)

Theo [KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md](de_xuat_trien_khai/KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md) và [CACH_XU_LY_USER_ROLE_ORG_PHAN_QUYEN_CHUC_NANG.md](de_xuat_trien_khai/CACH_XU_LY_USER_ROLE_ORG_PHAN_QUYEN_CHUC_NANG.md). **Toàn bộ 8 phase hiện ở trạng thái Chưa làm.**

### 3.1. Phase 1 – Backend: Effective roles + header

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 1.1 | IEffectiveRoleService (GetEffectiveRoleCodes) | ⏳ Chưa làm |
| 1.2 | Implement + đăng ký DI | ⏳ Chưa làm |
| 1.3 | Middleware đọc X-Organization-Id → HttpContext.Items["CurrentOrganizationId"] | ⏳ Chưa làm |
| 1.4 | (Tùy chọn) Cache effective roles vào Items | ⏳ Chưa làm |

### 3.2. Phase 2 – Backend: Authorization theo effective roles

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 2.1 | Requirement + Handler (OrgScopedRoleRequirement) | ⏳ Chưa làm |
| 2.2 | Đăng ký policy FormStructureAdmin dùng handler mới | ⏳ Chưa làm |
| 2.3 | Kiểm tra mọi endpoint [Authorize(Policy = "FormStructureAdmin")] | ⏳ Chưa làm |

### 3.3. Phase 3 – Backend: API User cặp (RoleId, OrganizationId)

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 3.1 | DTO: List&lt;UserRoleOrgItem&gt; (RoleId, OrganizationId?) + fallback RoleIds/OrganizationIds | ⏳ Chưa làm |
| 3.2 | UserService Create: ghi UserRole với OrganizationId | ⏳ Chưa làm |
| 3.3 | UserService Update: sync UserRole từ cặp | ⏳ Chưa làm |
| 3.4 | UserDto/GetById: trả về roleOrgPairs (và/hoặc RoleIds) | ⏳ Chưa làm |

### 3.4. Phase 4 – Backend: API danh sách ngữ cảnh

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 4.1 | GET /api/v1/auth/me/contexts (hoặc mở rộng /auth/me) | ⏳ Chưa làm |
| 4.2 | (Tùy chọn) Field contexts trong /auth/me | ⏳ Chưa làm |

### 3.5. Phase 5 – Frontend: Header + chuyển ngữ cảnh

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 5.1 | apiClient gửi X-Organization-Id từ AuthContext/storage | ⏳ Chưa làm |
| 5.2 | Sau login: lấy contexts; 1 cặp auto-set, ≥2 hiển thị dropdown | ⏳ Chưa làm |
| 5.3 | Đổi ngữ cảnh → invalidate/redirect/reload dữ liệu | ⏳ Chưa làm |
| 5.4 | Hiển thị "Đang làm việc: Vai trò @ Đơn vị" | ⏳ Chưa làm |

### 3.6. Phase 6 – Frontend: Form User gán cặp (Vai trò, Đơn vị)

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 6.1 | UsersPage: form cặp (Vai trò + Đơn vị), thêm/xóa dòng, "Toàn hệ thống" | ⏳ Chưa làm |
| 6.2 | Load user → map roleOrgPairs; submit gửi roleOrgPairs | ⏳ Chưa làm |

### 3.7. Phase 7 – Quản lý vai trò (Role)

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 7.1 | Backend: API GET/POST/PUT /api/v1/roles, Service, DTO, validate IsSystem | ⏳ Chưa làm |
| 7.2 | Frontend: RolesPage (bảng, modal CRUD) | ⏳ Chưa làm |

### 3.8. Phase 8 – Quản lý quyền (Permission) + gán quyền cho vai trò

| Bước | Nội dung | Trạng thái |
|------|----------|------------|
| 8.1 | Backend: Entity Permission, RolePermission + DbContext | ⏳ Chưa làm |
| 8.2 | Backend: GET /permissions, GET/PUT /roles/{id}/permissions | ⏳ Chưa làm |
| 8.3 | Frontend: Nút "Phân quyền" / modal gán quyền theo role (checkbox theo Module) | ⏳ Chưa làm |

---

## 4. Bảng tổng hợp trạng thái theo nhóm

| Nhóm | Số hạng mục | Đã xong | Chưa làm | Ghi chú |
|------|-------------|---------|----------|---------|
| **MVP Setup & Foundation (A1, A2, B1–B6)** | 8 | 8 | 0 | 100% |
| **MVP Form & Data (B7, B8, B12, P8)** | 4+ | 4+ | 0 | 100% |
| **MVP Workflow & Reporting (B9, B10)** | 2 | 2 | 0 | 100% |
| **MVP Phase 4 W15 (B11, FE Phase 2–3)** | 2+ | 2+ | 0 | 100% |
| **MVP W16 – Performance & Security** | 1 | 1 | 0 | ✅ Đã xong |
| **MVP W17 – UAT, Doc, Demo** | 1 | 0 | 1 | Sau W16 |
| **MVP tùy chọn (Refresh token, Menu tree)** | 2 | 0 | 2 | Tùy chọn |
| **User–Role–Org (Phase 1–6)** | 6 phase | 0 | 6 | 22 bước chi tiết |
| **Quản lý vai trò (Phase 7)** | 1 phase | 0 | 1 | 2 bước BE+FE |
| **Quản lý quyền (Phase 8)** | 1 phase | 0 | 1 | 3 bước BE+FE |
| **Post-MVP (entity thiếu, FE Workflow admin, Postman thiếu)** | 3 mục | 0 | 3 | Bổ sung khi cần |

---

## 5. Thứ tự ưu tiên đề xuất

1. **Ưu tiên 1 (MVP đóng phase):**  
   ~~**W16**~~ ✅ Đã xong. **W17** (UAT, Documentation, Demo) – ưu tiên tiếp.  
   Tham chiếu block giao AI trong TONG_HOP mục 3.4.

2. **Ưu tiên 2 (Phân quyền theo đơn vị + quản lý vai trò/quyền):**  
   **Phase 1 → 2 → 3** (BE effective roles, policy, User cặp Role–Org) → có thể song song **Phase 7** (quản lý vai trò) → **Phase 4 → 5 → 6** (API contexts, FE header + selector, form user cặp) → **Phase 8** (quản lý quyền).  
   Tham chiếu KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md.

3. **Tùy chọn:** Refresh token FE, Phân cấp Menu, bổ sung Postman/entity/Workflow admin FE.

---

## 6. Tham chiếu nhanh

| Tài liệu | Nội dung |
|----------|----------|
| [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) | Tổng hợp hiện trạng, công việc tiếp theo, block giao AI W16/W17 |
| [KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md](de_xuat_trien_khai/KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md) | Kế hoạch 8 phase User–Role–Org + quản lý vai trò/quyền |
| [CACH_XU_LY_USER_ROLE_ORG_PHAN_QUYEN_CHUC_NANG.md](de_xuat_trien_khai/CACH_XU_LY_USER_ROLE_ORG_PHAN_QUYEN_CHUC_NANG.md) | Giải pháp kỹ thuật (header, effective roles, bảo mật, chuyển ngữ cảnh) |
| [DANH_GIA_THIET_KE_PHAN_QUYEN_VA_ROLE.md](de_xuat_trien_khai/DANH_GIA_THIET_KE_PHAN_QUYEN_VA_ROLE.md) | Đánh giá gap phân quyền, đề xuất mở rộng |
| [06.KE_HOACH_MVP.md](script_core/06.KE_HOACH_MVP.md) | Timeline 17 tuần, Phase 1–4 |

---

**Version:** 1.0  
**Ngày:** 2026-02-11
