# Rà soát nghiệp vụ tổng hợp – BCDT

Tài liệu **tóm tắt các tính năng hiện có**, **luồng nghiệp vụ** và **luồng dữ liệu** của hệ thống BCDT (Báo cáo điện tử động). Tham chiếu: [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [01.YEU_CAU_HE_THONG.md](script_core/01.YEU_CAU_HE_THONG.md).

**Ngày rà soát:** 2026-02-25

---

## 1. Các tính năng đang có (theo module)

### 1.1. Xác thực & phân quyền

| Tính năng | Mô tả | FE (route / trang) | API (Controller) |
|-----------|--------|---------------------|-------------------|
| **Đăng nhập / Đăng xuất** | JWT login, refresh token, logout | `/login` (LoginPage) | AuthController: login, refresh, logout |
| **Thông tin user & vai trò** | /me, danh sách vai trò (role–org), chuyển vai trò | Header dropdown, Modal chọn vai trò | AuthController: me, me/roles |
| **RBAC** | 5 vai trò (SystemAdmin, FormAdmin, UnitAdmin, DataEntry, Viewer), policy theo quyền | Menu lọc theo RequiredPermission | [Authorize(Policy)] trên API |
| **RLS** | Row-Level Security theo OrganizationId, session context | — | sp_SetSystemContext, RLS policy DB |

### 1.2. Tổ chức & người dùng

| Tính năng | Mô tả | FE | API |
|-----------|--------|-----|-----|
| **Loại đơn vị** | CRUD OrganizationType | `/organization-types` (OrganizationTypesPage) | OrganizationTypesController |
| **Đơn vị (cây 5 cấp)** | CRUD, tree, ParentId | `/organizations` (OrganizationsPage, tree) | OrganizationsController (all=true) |
| **Người dùng** | CRUD User, gán vai trò + đơn vị (cặp role–org) | `/users` (UsersPage) | UsersController |
| **Vai trò** | CRUD Role, gán quyền (RolePermission) | `/roles` (RolesPage) | RolesController |
| **Quyền** | CRUD Permission | `/permissions` (PermissionsPage) | PermissionsController |
| **Menu** | CRUD Menu phân cấp, gán menu cho vai trò | `/menus` (MenusPage, tree) | MenusController (all=true) |

### 1.3. Biểu mẫu (Form Definition)

| Tính năng | Mô tả | FE | API |
|-----------|--------|-----|-----|
| **Định nghĩa biểu mẫu** | CRUD FormDefinition, version, từ template/upload Excel | `/forms` (FormsPage), `/forms/:id/config` (FormConfigPage) | FormDefinitionsController (from-template, upload, template-display) |
| **Sheet** | CRUD FormSheet (multi-sheet) | FormConfigPage (tab Sheet) | FormSheetsController |
| **Cột / Hàng** | CRUD FormColumn, FormRow (phân cấp ParentId), từ danh mục chỉ tiêu | FormConfigPage (Cột, Hàng) | FormColumnsController, FormRowsController |
| **Data binding** | 7 loại: Static, Database, API, Formula, Reference, Organization, System | FormConfigPage (Binding) | FormColumnDataBindingController |
| **Mapping cột → ReportDataRow** | TextValue1/2, NumericValue1–20, … | FormConfigPage | FormColumnMappingController |
| **Chỉ tiêu cố định & động (B12)** | FormDynamicRegion, ReportDynamicIndicator, cột/hàng từ danh mục | FormConfigPage (Vùng chỉ tiêu động) | FormDynamicRegionsController |
| **Lọc động & placeholder (P8)** | DataSource, FilterDefinition, FormPlaceholderOccurrence (dòng), FormDynamicColumnRegion, FormPlaceholderColumnOccurrence (cột) | FormConfigPage (Placeholder dòng/cột) | DataSourcesController, FilterDefinitionsController, FormPlaceholderOccurrencesController, FormDynamicColumnRegionsController, FormPlaceholderColumnOccurrencesController |
| **Danh mục chỉ tiêu** | IndicatorCatalog, Indicator (cột/hàng dùng chung) | `/indicator-catalogs` (IndicatorCatalogsPage) | IndicatorCatalogsController, IndicatorsController, IndicatorsByCodeController |

### 1.4. Kỳ báo cáo & tần suất

| Tính năng | Mô tả | FE | API |
|-----------|--------|-----|-----|
| **Tần suất báo cáo** | CRUD ReportingFrequency (Ngày/Tuần/Tháng/Quý/Năm/Đột xuất) | `/reporting-frequencies` | ReportingFrequenciesController |
| **Kỳ báo cáo** | CRUD ReportingPeriod (theo tần suất, deadline, status) | `/reporting-periods` | ReportingPeriodsController |

### 1.5. Báo cáo & nhập liệu (Submission)

| Tính năng | Mô tả | FE | API |
|-----------|--------|-----|-----|
| **Danh sách báo cáo** | List submission theo form, đơn vị, kỳ, trạng thái | `/submissions` (SubmissionsPage) | SubmissionsController |
| **Nhập liệu Excel** | Mở workbook (Fortune-sheet), load/save ReportPresentation, ReportDataRow, chỉ tiêu động | `/submissions/:id/entry` (SubmissionDataEntryPage) | SubmissionsController (workbook-data), ReportPresentationsController (GET/PUT), sync-from-presentation, dynamic-indicators |
| **Xuất Excel / PDF** | Tải .xlsx, (PDF) | Nút Xuất Excel trong trang nhập liệu | workbook-data (export), B11 PDF |

### 1.6. Workflow phê duyệt

| Tính năng | Mô tả | FE | API |
|-----------|--------|-----|-----|
| **Định nghĩa quy trình** | WorkflowDefinition, WorkflowStep (1–5 cấp), FormWorkflowConfig | `/workflow-definitions` (WorkflowDefinitionsPage) | WorkflowDefinitionsController, WorkflowStepsController, FormWorkflowConfigController |
| **Nộp / Duyệt / Từ chối / Yêu cầu sửa** | Submit, Approve, Reject, RequestRevision; WorkflowInstance, WorkflowApproval | SubmissionsPage (nút Nộp), modal duyệt/từ chối | SubmissionsController (submit), WorkflowInstancesController (approve, reject, request-revision, approvals) |

### 1.7. Tổng hợp & Dashboard

| Tính năng | Mô tả | FE | API |
|-----------|--------|-----|-----|
| **Thống kê admin** | Số báo cáo, theo kỳ, theo biểu mẫu | `/dashboard` (DashboardPage) | DashboardController (admin/stats) |
| **Nhiệm vụ user** | Báo cáo nháp, chờ duyệt | `/dashboard` | DashboardController (user/tasks) |
| **Tổng hợp báo cáo** | Aggregation (ReportSummary) từ đơn vị con | — | Reporting (B10) |

### 1.8. Tham chiếu & cấu hình hệ thống

| Tính năng | Mô tả | FE | API |
|-----------|--------|-----|-----|
| **Loại thực thể tham chiếu** | CRUD ReferenceEntityType | `/reference-entity-types` (ReferenceEntityTypesPage) | ReferenceEntityTypesController |
| **Thực thể tham chiếu** | CRUD ReferenceEntity phân cấp (ParentId) | `/reference-entities` (ReferenceEntitiesPage, tree) | ReferenceEntitiesController (all=true) |
| **Cấu hình hệ thống** | Key-value SystemConfig | `/system-config` (SystemConfigPage) | SystemConfigController |
| **Thông báo** | In-app notification (Deadline, Approval, Rejection, Revision, …) | `/notifications` (NotificationsPage), icon Header | NotificationsController |

### 1.9. Cá nhân

| Tính năng | Mô tả | FE | API |
|-----------|--------|-----|-----|
| **Hồ sơ / Đổi mật khẩu** | Profile, change password | `/profile` (ProfilePage) | Auth (me, change-password) |
| **Cài đặt** | SettingsPage | `/settings` | — |

---

## 2. Luồng nghiệp vụ (end-to-end)

### 2.1. Luồng đăng nhập và vào hệ thống

1. User mở app → **ProtectedRoute** kiểm tra auth (loading → PageLoading, chưa đăng nhập → redirect `/login`).
2. **Login**: nhập username/password → POST `/api/v1/auth/login` → lưu accessToken + refreshToken → redirect về trang từ state hoặc `/organizations`.
3. **/me**: load user + danh sách vai trò (role–org). User có thể **chuyển vai trò** (dropdown/modal) → chọn (roleId, organizationId) → redirect `/dashboard`, invalidate menu/quyền.
4. **Menu**: hiển thị theo `currentRole` và RequiredPermission (RolePermission); RLS áp theo OrganizationId của vai trò đang chọn.

### 2.2. Luồng cấu hình biểu mẫu (Admin / FormAdmin)

1. Vào **Biểu mẫu** (`/forms`) → tạo mới (hoặc từ template/upload Excel).
2. Vào **Cấu hình** (`/forms/:id/config`):  
   - **Sheet**: thêm/sửa sheet.  
   - **Cột / Hàng**: thêm cột/hàng (cố định hoặc từ danh mục chỉ tiêu), phân cấp ParentId.  
   - **Data binding**: chọn loại (Static, Database, API, …) và tham số.  
   - **Mapping**: map cột form → cột lưu (TextValue1/2, NumericValue1/2, …).  
   - **B12**: Vùng chỉ tiêu động (FormDynamicRegion, ReportDynamicIndicator).  
   - **P8**: DataSource, FilterDefinition, Placeholder dòng/cột (FormPlaceholderOccurrence, FormDynamicColumnRegion, FormPlaceholderColumnOccurrence).
3. (Tùy chọn) Cấu hình **Workflow** cho form: chọn WorkflowDefinition, FormWorkflowConfig (số cấp, bước).

### 2.3. Luồng tạo kỳ báo cáo

1. **Tần suất** (`/reporting-frequencies`): CRUD (MONTHLY, QUARTERLY, …).
2. **Kỳ báo cáo** (`/reporting-periods`): tạo kỳ theo tần suất (PeriodCode, StartDate, EndDate, Deadline, Status).

### 2.4. Luồng nộp và phê duyệt báo cáo (Submission workflow)

1. **Tạo / mở báo cáo**: SubmissionsPage → chọn Form, Organization, ReportingPeriod → hệ thống tạo hoặc mở submission (trạng thái **Draft**).
2. **Nhập liệu**: vào `/submissions/:id/entry` → load workbook-data (cấu trúc form + ReportDataRow + ReportPresentation + chỉ tiêu động) → chỉnh sửa ô → **Lưu** (PUT presentation / sync-from-presentation, PUT dynamic-indicators nếu có).
3. **Nộp**: nút **Nộp** → POST `submissions/:id/submit` → trạng thái **Submitted**, tạo WorkflowInstance (Pending).
4. **Duyệt** (theo từng bước workflow):  
   - Approve → bước tiếp hoặc trạng thái **Approved**.  
   - Reject → trạng thái **Rejected**.  
   - RequestRevision → trạng thái **Revision** → đơn vị sửa lại bản nháp rồi nộp lại.
5. **Lịch sử duyệt**: GET `workflow-instances/:id/approvals` (WorkflowApproval).

### 2.5. Luồng xem thống kê và thông báo

1. **Dashboard** (`/dashboard`): admin xem thống kê (số báo cáo, theo kỳ, theo form); user xem báo cáo nháp / chờ duyệt.
2. **Thông báo** (`/notifications`): xem danh sách (Deadline, Approval, Rejection, Revision, …), đánh dấu đã đọc.

---

## 3. Luồng dữ liệu (data flow)

### 3.1. Từ định nghĩa biểu mẫu đến dữ liệu nhập

```
FormDefinition (Code, Name, FormType)
  → FormVersion (VersionNumber)
  → FormSheet (SheetIndex, SheetName)
  → FormColumn (ColumnCode, DataType, IndicatorId…)
       → FormColumnMapping (TargetColumnName: TextValue1, NumericValue1, …)
       → FormColumnDataBinding (BindingType, Config)
  → FormRow (phân cấp ParentId)
  → FormDynamicRegion (B12)
  → FormPlaceholderOccurrence (P8 dòng), FormPlaceholderColumnOccurrence (P8 cột)
       → FilterDefinition → FilterCondition, DataSource
```

- **Build workbook**: khi mở trang nhập liệu hoặc gọi `workbook-data`, backend build workbook từ FormDefinition + FormVersion + Sheet/Column/Row + DataBinding + B12/P8 → JSON workbook + resolve placeholder (lọc theo FilterDefinition, DataSource).
- **Ô nhập liệu** map vào **ReportDataRow**: SheetIndex, RowIndex, TextValue1/2, NumericValue1–20 (theo FormColumnMapping).

### 3.2. Lưu trữ báo cáo (Hybrid storage)

| Thành phần | Mục đích |
|------------|----------|
| **ReportSubmission** | Metadata: FormDefinitionId, FormVersionId, OrganizationId, ReportingPeriodId, **Status** (Draft / Submitted / Approved / Rejected / Revision), Version, RevisionNumber, SubmittedAt/By, ApprovedAt/By. |
| **ReportPresentation** | JSON workbook (layout, merge, style) – 1 bản per submission (hoặc per sheet tùy thiết kế). |
| **ReportDataRow** | Dữ liệu ô theo dòng: SubmissionId, SheetIndex, RowIndex, TextValue1/2, NumericValue1–20 (và cột mở rộng nếu có). |
| **ReportDynamicIndicator** | Chỉ tiêu động (B12) đã expand theo FormDynamicRegion. |
| **ReportSummary** | Dữ liệu tổng hợp (B10) từ đơn vị con (aggregation). |

### 3.3. Luồng trạng thái submission

```
Draft → (Submit) → Submitted
         → (Approve hết bước) → Approved
         → (Reject) → Rejected
         → (RequestRevision) → Revision → (sửa + Submit lại) → Submitted
```

- WorkflowInstance (Status: Pending | Approved | Rejected | Cancelled) và WorkflowApproval (Action: Approve | Reject | RequestRevision | Skip) gắn với submission.

### 3.4. Phân quyền và phạm vi dữ liệu

- **RLS**: mọi bảng dữ liệu theo đơn vị (OrganizationId) đều áp RLS; session set qua `sp_SetSystemContext` (CurrentUserId, CurrentOrganizationId).
- **API**: [Authorize] + policy theo role; list submission/form/org chỉ trả về đúng phạm vi user/vai trò hiện tại.

---

## 4. Tóm tắt số liệu (rà soát code)

| Hạng mục | Số lượng |
|----------|----------|
| **FE routes (trang)** | 22+ (login, organizations, users, forms, submissions, dashboard, workflow-definitions, …) |
| **BE Controllers** | 28 |
| **DB bảng** | 59 (BCDT_*) |
| **Phase MVP** | Phase 1–4 đã hoàn thành (A1, A2, B1–B12, P8, W16, W17) |

---

## 5. Tài liệu tham chiếu

- **Yêu cầu:** [01.YEU_CAU_HE_THONG.md](script_core/01.YEU_CAU_HE_THONG.md), [YEU_CAU_HE_THONG_TONG_HOP.md](YEU_CAU_HE_THONG_TONG_HOP.md).
- **Tiến độ:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [RA_SOAT_TIEN_DO_CHI_TIET.md](RA_SOAT_TIEN_DO_CHI_TIET.md).
- **Review từng module:** `docs/de_xuat_trien_khai/REVIEW_NGHIEP_VU_*.md` (Auth, Org/User, Form, Submission, Workflow, Reporting, B12, P8).
- **Cấu trúc & API:** [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md), [API_HTTP_AND_BUSINESS_STATUS.md](API_HTTP_AND_BUSINESS_STATUS.md).
