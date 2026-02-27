# Rà soát dữ liệu đã seeding – BCDT

Tài liệu tóm tắt **toàn bộ dữ liệu seeding** trong dự án: phân loại, thứ tự chạy, bảng/entity đụng, và đối chiếu với tài liệu hiện có.

**Ngày rà soát:** 2026-02-23.

---

## 1. Phân loại và thứ tự

### 1.1. Schema + Core seed (bắt buộc khi setup DB)

Chạy theo thứ tự **01 → 14** (xem [script_core/README.md](../README.md#thứ-tự-chạy)):

| # | File | Mô tả |
|---|------|-------|
| 1–10 | 01.organization.sql … 10.notification.sql | Tạo bảng (49 bảng theo VERIFY_TABLES) |
| 11 | 11.indexes.sql | Indexes |
| 12 | 12.row_level_security.sql | RLS |
| 13 | 13.functions.sql | Hàm (vd. sp_SetSystemContext) |
| **14** | **14.seed_data.sql** | **Dữ liệu core** (xem mục 2) |

### 1.2. Script mở rộng (15–23, chạy sau 01–14)

| File | Mục đích |
|------|----------|
| 15.add_last_logout_at.sql | Cột User.LastLogoutAt |
| 15.seed_menu_system_group.sql | Gắn menu "Cấu hình hệ thống" vào group "Hệ thống"; RoleMenu |
| 16.add_form_column_group.sql | Cột FormColumn.ColumnGroupName |
| 16.fix_duplicate_system_group.sql | Sửa trùng group Hệ thống |
| 17–22 | Form structure, P8 filter/column, … |
| **23.seed_menu_workflow_definitions.sql** | Menu "Quy trình phê duyệt" (/workflow-definitions) + RoleMenu (role 1,2,3) |

### 1.3. Seed dữ liệu test (nhập liệu Excel)

Dùng cho màn nhập liệu (`/submissions/{id}/entry`). **Điều kiện:** Đã chạy 01–14 (và 16 nếu form dùng ColumnGroupName).

| Thứ tự | File | Mô tả |
|--------|------|-------|
| 1 | seed_test_excel_entry.sql | Form TEST_EXCEL_ENTRY + 1 submission + ~80 ReportDataRow |
| 2 | seed_more_submissions_excel_entry.sql | Thêm submission + ~30 ReportDataRow/submission (cho entry) |
| 3 | seed_test_excel_full_form.sql | Form TEST_EXCEL_FULL (8 cột) + 1 submission + ~20 ReportDataRow |

**Batch MCP (một batch, không GO):** seed_mcp_1_test_excel_entry.sql → seed_mcp_2_test_excel_full.sql → seed_mcp_3_more_submissions.sql. Chi tiết: [SEED_VIA_MCP.md](SEED_VIA_MCP.md).

**Script tự động:** [Ensure-TestData.ps1](Ensure-TestData.ps1) (PowerShell) – kiểm tra điều kiện rồi chạy seed khi thiếu. Chi tiết: [README_SEED_TEST.md](README_SEED_TEST.md).

**Khác:** seed_b12_p4_workbook_dynamic.sql – dữ liệu mẫu cho B12 P4 (workbook động).

---

## 2. Nội dung 14.seed_data.sql (core)

| Bảng / nhóm | Nội dung |
|-------------|----------|
| BCDT_OrganizationType | 5 loại (MINISTRY → LEVEL5) |
| BCDT_Role | 5 vai trò (SYSTEM_ADMIN, FORM_ADMIN, UNIT_ADMIN, DATA_ENTRY, VIEWER) |
| BCDT_DataScope, BCDT_RoleDataScope | Phạm vi dữ liệu theo vai trò |
| BCDT_Permission, BCDT_RolePermission | Quyền Form/Submission/Workflow/Report/Admin; gán theo role |
| BCDT_ReportingFrequency | DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY, ADHOC |
| BCDT_AuthProvider, BCDT_TwoFactorProvider, BCDT_SignatureProvider | BuiltIn/SSO/LDAP; TOTP/SMS/Email; Audit/Simple/VGCA |
| BCDT_Menu, BCDT_RoleMenu | Menu "Cấu hình hệ thống" (Code=SYSTEM_CONFIG, Id=100) |
| BCDT_SystemConfig | System.Name, Auth.*, Upload.*, Excel.*, Notification.* |
| BCDT_Organization | 1 đơn vị mẫu: MOF (Bộ Tài chính) |
| BCDT_User | admin (password Admin@123, hash Argon2) |
| BCDT_UserRole | admin = SYSTEM_ADMIN (toàn hệ thống) + UNIT_ADMIN@MOF |
| BCDT_UserOrganization | admin thuộc đơn vị MOF (primary) |

---

## 3. Đối chiếu tài liệu

| Tài liệu | Nội dung seed | Trạng thái |
|----------|----------------|------------|
| [script_core/README.md](../README.md) | Thứ tự 01→14; 14 = Dữ liệu seed | ✅ Đồng bộ |
| [RUNBOOK.md](../../RUNBOOK.md) | DB 01→14; seed test: Ensure-TestData.ps1 hoặc MCP (seed_mcp_1/2/3) | ✅ Đồng bộ |
| [README_SEED_TEST.md](README_SEED_TEST.md) | Thứ tự seed test (entry → more → full); Ensure-TestData điều kiện | ✅ Đồng bộ |
| [SEED_VIA_MCP.md](SEED_VIA_MCP.md) | seed_mcp_1/2/3; query kiểm tra HasEntry, HasFull, SubCount | ✅ Đồng bộ |
| TONG_HOP mục 5.3 | Seed Scripts: 7 file (seed_test_excel_*, seed_mcp_1/2/3, seed_b12_p4), Ensure-TestData.ps1 | ✅ Đồng bộ |

---

## 5. Đầy đủ cho toàn bộ nghiệp vụ

Ma trận phủ seed theo nhóm nghiệp vụ (tham chiếu [01.YEU_CAU_HE_THONG.md](../../01.YEU_CAU_HE_THONG.md)):

| Nghiệp vụ | Seed phủ | File | Ghi chú |
|-----------|----------|------|--------|
| **Cơ cấu tổ chức (ORG-01–06)** | OrganizationType 5 cấp, Organization MOF, User admin, UserRole, UserOrganization | 14 | Đủ đăng nhập, chuyển vai trò, RLS theo đơn vị |
| **5 vai trò + phân quyền** | Role, Permission, RolePermission, DataScope, RoleDataScope | 14 | SYSTEM_ADMIN, FORM_ADMIN, UNIT_ADMIN, DATA_ENTRY, VIEWER |
| **Đăng nhập / Auth** | User admin (Admin@123), AuthProvider, TwoFactorProvider | 14 | BuiltIn; 2FA/Signature cấu hình |
| **Menu & điều hướng** | Menu SYSTEM_CONFIG (14), gắn group (15), menu Quy trình phê duyệt (23) | 14, 15, 23 | Sidebar đủ cho admin/form/unit |
| **Chu kỳ báo cáo (CK-01)** | ReportingFrequency (DAILY…ADHOC) | 14 | **ReportingPeriod:** 14 không tạo kỳ mẫu; seed test (entry/mcp_1) tạo 1 kỳ (vd 2026-01) nếu chưa có. Để có kỳ ngay sau setup: chạy seed test hoặc thêm script tạo 1 kỳ. |
| **Workflow (WF-01–06)** | Quyền Workflow.*, menu Quy trình phê duyệt | 14, 23 | Định nghĩa quy trình/bước: tạo qua FE (không seed sẵn) |
| **Biểu mẫu & nhập liệu (BM, FR-NL)** | Form TEST_EXCEL_ENTRY, TEST_EXCEL_FULL + submission + ReportDataRow | seed_test_* / seed_mcp_* | Đủ test màn nhập liệu Excel |
| **B12 P4 (chỉ tiêu động)** | IndicatorCatalog, Indicator, form mẫu động | seed_b12_p4_workbook_dynamic | Tùy chọn |
| **ReferenceEntity / danh mục** | — | — | Không có trong seed core; tạo qua FE hoặc script riêng nếu cần demo |

**Kết luận:** Seed hiện tại phủ đủ nghiệp vụ chính (auth, org, role, menu, chu kỳ tần suất, test nhập liệu). Thiếu: (1) **Một kỳ báo cáo mẫu** trong 14 (đang do seed test bù); (2) **ReferenceEntityType/ReferenceEntity** nếu cần demo danh mục phân cấp ngay sau setup.

---

## 6. Trùng lặp và chồng chéo

### 6.1. Idempotent (chạy lại an toàn)

| File | Idempotent | Cách |
|------|------------|------|
| 15.seed_menu_system_group.sql | Có | WHERE NOT EXISTS (RoleMenu) |
| 23.seed_menu_workflow_definitions.sql | Có | IF NOT EXISTS (Menu Code=WORKFLOW_DEFINITIONS); WHERE NOT EXISTS (RoleMenu) |
| seed_test_excel_entry.sql | Có | IF EXISTS (Form TEST_EXCEL_ENTRY) RETURN |
| seed_test_excel_full_form.sql | Có | IF EXISTS (Form TEST_EXCEL_FULL) RETURN |
| seed_mcp_1/2/3, seed_more_submissions, seed_b12_p4_workbook_dynamic | Có | IF EXISTS form / WHERE NOT EXISTS submission (hoặc tương đương) |

### 6.2. Không idempotent (chỉ chạy một lần)

| File | Ghi chú |
|------|--------|
| **14.seed_data.sql** | INSERT trực tiếp (SET IDENTITY_INSERT); chỉ Organization MOF có IF NOT EXISTS. **Chạy lại sẽ trùng** Role, Permission, User admin, Menu 100, SystemConfig, v.v. Chỉ dùng trên **DB mới** (sau 01–13). |

### 6.3. Chồng chéo (cùng dữ liệu – chỉ dùng một cách)

**BCDT_Menu – Url trùng:** Đã xử lý (2026-02-23): script [24.fix_menu_duplicate_workflow_url.sql](24.fix_menu_duplicate_workflow_url.sql) xóa MENU_WORKFLOW (Id 35); chỉ còn WORKFLOW_DEFINITIONS (102). Chi tiết: [RA_SOAT_BCDT_MENU.md](RA_SOAT_BCDT_MENU.md).

| Nhóm | File tương đương | Khuyến nghị |
|------|-------------------|-------------|
| Form TEST_EXCEL_ENTRY | seed_test_excel_entry.sql ↔ seed_mcp_1_test_excel_entry.sql | **Chỉ chạy một trong hai:** thủ công (sqlcmd/SSMS) **hoặc** MCP (mcp_mssql_execute_sql). Cả hai đều idempotent; chạy cả hai không tạo bản ghi trùng nhưng dư. |
| Form TEST_EXCEL_FULL | seed_test_excel_full_form.sql ↔ seed_mcp_2_test_excel_full.sql | Tương tự; chọn thủ công hoặc MCP. |
| Thêm submission (TEST_EXCEL_ENTRY) | seed_more_submissions_excel_entry.sql ↔ seed_mcp_3_more_submissions.sql | Cùng mục đích; có thể chạy một hoặc cả hai (đều WHERE NOT EXISTS nên không trùng submission). Chạy cả hai = nhiều submission hơn. |

### 6.4. Thứ tự tránh xung đột

- **01 → 14** bắt buộc trước mọi seed khác. **15, 23** (menu) chạy sau 14.
- Seed test (entry/full/more hoặc mcp_1/2/3) sau 14; nếu dùng form có ColumnGroupName thì sau **16.add_form_column_group.sql**.

---

## 7. Kiểm tra cho AI (rà soát dữ liệu đã seeding)

Khi cần **rà soát lại** hoặc **xác nhận** dữ liệu seeding:

1. **Đọc tài liệu:** RA_SOAT_DU_LIEU_SEEDING.md (file này), README_SEED_TEST.md, SEED_VIA_MCP.md, RUNBOOK mục 3.
2. **Đối chiếu file:** Liệt kê file trong `docs/script_core/sql/v2/` có tên `seed*.sql` và `14.seed_data.sql`, `15.seed_menu_*.sql`, `23.seed_menu_*.sql`; so với mục 1.
3. **Đầy đủ nghiệp vụ / trùng chéo:** Rà mục 5 (ma trận nghiệp vụ), mục 6 (idempotent, chồng chéo, thứ tự).
4. **Nếu có MCP SQL:** Chạy query kiểm tra trong SEED_VIA_MCP.md (HasEntry, HasFull, SubCount) để báo hiện trạng DB.
5. **Cập nhật doc:** Nếu thêm/xóa script seed, cập nhật file này (mục 1, 5, 6), README_SEED_TEST, SEED_VIA_MCP và TONG_HOP 5.3.
6. **Báo Pass/Fail:** Báo từng mục (đối chiếu file, đối chiếu doc, nghiệp vụ/trùng chéo, query nếu chạy).

---

## 8. Kết quả kiểm tra MCP (mẫu – dùng execute_sql)

Dùng MCP SQL Server (`user-mssql` / `execute_sql`) để kiểm tra đúng, đủ, không trùng:

**Bước 1 – Số dòng từng bảng:**  
`SELECT t.name, SUM(p.rows) AS Cnt FROM sys.tables t INNER JOIN sys.partitions p ON t.object_id = p.object_id WHERE t.name LIKE 'BCDT_%' AND p.index_id IN (0,1) GROUP BY t.name ORDER BY t.name`

**Bước 2 – Kiểm tra trùng Code/Username (phải trả 0 dòng):**
- `SELECT Code, COUNT(*) AS Cnt FROM BCDT_OrganizationType GROUP BY Code HAVING COUNT(*) > 1`
- `SELECT Code, COUNT(*) AS Cnt FROM BCDT_Role GROUP BY Code HAVING COUNT(*) > 1`
- `SELECT Username, COUNT(*) AS Cnt FROM BCDT_User GROUP BY Username HAVING COUNT(*) > 1`
- `SELECT Code, COUNT(*) AS Cnt FROM BCDT_FormDefinition GROUP BY Code HAVING COUNT(*) > 1`
- `SELECT Code, COUNT(*) AS Cnt FROM BCDT_Menu GROUP BY Code HAVING COUNT(*) > 1`
- `SELECT Code, COUNT(*) AS Cnt FROM BCDT_Organization GROUP BY Code HAVING COUNT(*) > 1`
- `SELECT Code, COUNT(*) AS Cnt FROM BCDT_ReferenceEntityType GROUP BY Code HAVING COUNT(*) > 1`

**Bước 3 – Đối chiếu seed core (14):**  
OrganizationType = 5 (MINISTRY→LEVEL5), Role ≥ 5, Permission = 23, ReportingFrequency = 6 (DAILY..ADHOC), User có admin, Organization có MOF, Menu có SYSTEM_CONFIG (41) và WORKFLOW_DEFINITIONS (102) nếu đã chạy 23.

**Kết quả kiểm tra mẫu (2026-02-23, một môi trường DB):**
- **Trùng lặp:** Không phát hiện (các query HAVING COUNT(*) > 1 đều trả 0 dòng).
- **Đủ seed core:** OrganizationType 5, Role 6 (5 seed + 1 thêm), Permission 23, ReportingFrequency 6, User có admin, Organization có MOF, Menu 20 (có SYSTEM_CONFIG, WORKFLOW_DEFINITIONS).
- **Form:** FormDefinition có TEST_EXCEL_ENTRY, TEST_EXCEL_FULL (đúng nếu đã chạy seed test).
- **Submission/ReportDataRow:** Tùy môi trường (0 nếu chưa chạy seed test hoặc đã xóa).

Số liệu phụ thuộc DB đang kết nối; khi rà soát lại nên chạy lại bước 1–3 và ghi nhận Pass/Fail.

---

**Version:** 1.2 · **Last Updated:** 2026-02-23 (thêm mục 8 Kiểm tra MCP – đúng, đủ, không trùng)
