# Phân tích luồng nghiệp vụ: Tạo template biểu mẫu → Đơn vị nhập liệu

Tài liệu mô tả **chi tiết** luồng từ khi tạo template biểu mẫu đến khi đơn vị nhập liệu: **công việc gì**, **ai làm** (vai trò), **làm như thế nào**, **tương ứng chức năng nào** (FE route, API). Tham chiếu: [01.YEU_CAU_HE_THONG.md](script_core/01.YEU_CAU_HE_THONG.md), [03.DATABASE_SCHEMA.md](script_core/03.DATABASE_SCHEMA.md) (Permission Matrix), [DEMO_SCRIPT.md](DEMO_SCRIPT.md).

**Ngày:** 2026-02-25

---

## 1. Tổng quan luồng (5 giai đoạn)

```
[A] Chuẩn bị hạ tầng (đơn vị, user, kỳ, quy trình)
         ↓
[B] Tạo template biểu mẫu (FormDefinition)
         ↓
[C] Cấu hình chi tiết biểu mẫu (sheet, cột, binding, workflow)
         ↓
[D] Mở kỳ báo cáo & (tuỳ chọn) tạo submission cho đơn vị
         ↓
[E] Đơn vị nhập liệu → Lưu → Gửi duyệt
```

---

## 2. Ma trận quyền (ai được làm gì)

| Quyền / Hành động | SystemAdmin | FormAdmin | UnitAdmin | DataEntry | Viewer |
|-------------------|-------------|-----------|-----------|-----------|--------|
| Form.Create / Form.Edit | ✓ | ✓ | — | — | — |
| Submission.Create / Submission.Submit | ✓ | ✓ | ✓* | ✓* | — |
| Workflow.Approve | ✓ | ✓ | ✓* | — | — |
| Admin.ManageUsers (trong phạm vi đơn vị) | ✓ | — | ✓* | — | — |
| Submission.View / Form.View | ✓ | ✓ | ✓ | ✓ | ✓ |

\* UnitAdmin / DataEntry: trong phạm vi **đơn vị** (OrganizationId) do RLS và vai trò đang chọn (role–org).

---

## 3. Giai đoạn A – Chuẩn bị hạ tầng

**Mục đích:** Có đơn vị, user, tần suất/kỳ báo cáo, (tuỳ chọn) quy trình phê duyệt để gắn với biểu mẫu và submission.

| # | Công việc | Ai làm | Làm như thế nào | Chức năng (FE / API) |
|---|-----------|--------|------------------|----------------------|
| A1 | **Tạo loại đơn vị** (nếu chưa có) | SystemAdmin, FormAdmin | Vào **Loại đơn vị** → Thêm (Code, Tên). | FE: `/organization-types` (OrganizationTypesPage). API: POST/GET/PUT/DELETE `/api/v1/organization-types`. |
| A2 | **Tạo đơn vị (cây 5 cấp)** | SystemAdmin, FormAdmin | Vào **Đơn vị** → Thêm đơn vị (Code, Tên, Loại, Đơn vị cha nếu có). Có thể tạo nhiều cấp (Bộ → Tỉnh → …). | FE: `/organizations` (OrganizationsPage, tree, TreeSelect cha). API: `/api/v1/organizations` (CRUD, `all=true` cho cây). |
| A3 | **Tạo user & gán vai trò + đơn vị** | SystemAdmin (toàn hệ thống), UnitAdmin (trong đơn vị) | Vào **Người dùng** → Thêm/sửa user; chọn **cặp (Vai trò, Đơn vị)**. User đăng nhập sau đó chọn vai trò trong ngữ cảnh (role–org) để làm việc. | FE: `/users` (UsersPage). API: `/api/v1/users` (CRUD, body có role–org pairs). |
| A4 | **Tạo tần suất báo cáo** | SystemAdmin, FormAdmin | Vào **Tần suất báo cáo** → Thêm (vd. MONTHLY, QUARTERLY). | FE: `/reporting-frequencies` (ReportingFrequenciesPage). API: `/api/v1/reporting-frequencies`. |
| A5 | **Tạo kỳ báo cáo** | SystemAdmin, FormAdmin | Vào **Kỳ báo cáo** → Thêm kỳ (Tên, Tần suất, Ngày bắt đầu/kết thúc, Hạn nộp, Trạng thái). Đơn vị sẽ nộp báo cáo theo **kỳ** này. | FE: `/reporting-periods` (ReportingPeriodsPage). API: `/api/v1/reporting-periods`. |
| A6 | **(Tuỳ chọn) Định nghĩa quy trình phê duyệt** | SystemAdmin, FormAdmin | Vào **Quy trình phê duyệt** → Tạo quy trình (Tên) → Thêm các **bước duyệt** (thứ tự, tên, có thể yêu cầu sửa hay không). Sau đó sẽ **gắn quy trình này vào biểu mẫu** ở giai đoạn C. | FE: `/workflow-definitions` (WorkflowDefinitionsPage). API: `/api/v1/workflow-definitions`, `/api/v1/workflow-definitions/{id}/steps` (WorkflowStepsController). |

**Kết quả A:** Có Organization, User (với role–org), ReportingFrequency, ReportingPeriod; (tuỳ chọn) WorkflowDefinition + WorkflowStep.

---

## 4. Giai đoạn B – Tạo template biểu mẫu (FormDefinition)

**Mục đích:** Có một **biểu mẫu** (form) với mã, tên, loại (Input/Aggregate), có thể kèm file Excel template. Chưa có cấu trúc chi tiết (sheet/cột) nếu tạo “trống”; nếu tạo **từ template Excel** thì hệ thống có thể parse sơ bộ hoặc tạo form + version + sheet/cột từ file.

| # | Công việc | Ai làm | Làm như thế nào | Chức năng (FE / API) |
|---|-----------|--------|------------------|----------------------|
| B1 | **Tạo biểu mẫu mới (trống)** | SystemAdmin, FormAdmin | Vào **Biểu mẫu** → **Thêm** → Nhập Mã, Tên, Mô tả, Loại (Input), Tần suất (nếu có), Hạn nộp offset, Cho phép nộp trễ, Yêu cầu duyệt, v.v. → Lưu. Hệ thống tạo FormDefinition + FormVersion (version 1). | FE: `/forms` (FormsPage) → Modal “Thêm”. API: POST `/api/v1/forms` (FormDefinitionsController). |
| B2 | **Tạo biểu mẫu từ file Excel (template)** | SystemAdmin, FormAdmin | Vào **Biểu mẫu** → **Tạo từ template** (hoặc tương đương) → Chọn file .xlsx + Nhập Tên (và Mã nếu có) → Gửi. Backend parse file, tạo FormDefinition + FormVersion + (có thể) FormSheet/FormColumn theo cấu trúc Excel. | FE: `/forms` (FormsPage) → Modal “Tạo từ template”, upload file. API: POST `/api/v1/forms/from-template` (multipart, file + name/code). |
| B3 | **Upload / cập nhật file template cho form có sẵn** | SystemAdmin, FormAdmin | Trên form đã tạo: (nếu có chức năng) **Upload template** hoặc **Tải template** để xem file mẫu. Có thể dùng template để hiển thị hoặc đồng bộ cấu trúc. | FE: `/forms`, form chi tiết. API: GET `/api/v1/forms/{id}/template` (tải file), POST upload template (nếu có endpoint tương ứng). |

**Kết quả B:** Có FormDefinition (Code, Name, Status Draft/Published), FormVersion (version 1). Cấu trúc sheet/cột có thể rỗng (tạo trống) hoặc đã có sẵn (từ template).

---

## 5. Giai đoạn C – Cấu hình chi tiết biểu mẫu

**Mục đích:** Định nghĩa **đầy đủ** cấu trúc và hành vi biểu mẫu: sheet, cột, hàng, data binding, mapping cột → dữ liệu, (tuỳ chọn) vùng chỉ tiêu động, lọc động/placeholder, và **gắn quy trình phê duyệt**.

| # | Công việc | Ai làm | Làm như thế nào | Chức năng (FE / API) |
|---|-----------|--------|------------------|----------------------|
| C1 | **Mở cấu hình biểu mẫu** | SystemAdmin, FormAdmin | Từ **Biểu mẫu** → Chọn form → **Cấu hình** (hoặc nút Cấu hình). Vào trang cấu hình theo formId. | FE: `/forms/:formId/config` (FormConfigPage). |
| C2 | **Quản lý Sheet** | SystemAdmin, FormAdmin | Trong Cấu hình: tab/block **Sheet** → Thêm/sửa/xóa sheet (SheetIndex, SheetName, DisplayName, IsDataSheet, …). Một form có thể nhiều sheet. | API: `/api/v1/forms/{formId}/sheets` (FormSheetsController). |
| C3 | **Quản lý Cột (FormColumn)** | SystemAdmin, FormAdmin | Block **Cột** → Thêm cột (ColumnCode, ColumnName, ExcelColumn, DataType, ParentId nếu phân cấp, IndicatorId nếu lấy từ danh mục chỉ tiêu). Có thể “Tạo cột mới” hoặc “Thêm từ danh mục chỉ tiêu”. | API: `/api/v1/forms/{formId}/sheets/{sheetId}/columns` (FormColumnsController). Danh mục: `/api/v1/indicator-catalogs`, `/api/v1/indicators` (by-code _SPECIAL_GENERIC). |
| C4 | **Quản lý Hàng (FormRow)** | SystemAdmin, FormAdmin | Block **Hàng** → Thêm hàng (RowType, ParentId, FormDynamicRegionId nếu thuộc vùng động). Cột/hàng có thể hiển thị dạng cây. | API: `/api/v1/forms/{formId}/sheets/{sheetId}/rows` (FormRowsController). |
| C5 | **Cấu hình Data binding (7 loại)** | SystemAdmin, FormAdmin | Với từng cột: chọn **Data binding** → Loại (Static, Database, API, Formula, Reference, Organization, System) và tham số (config JSON). Ô sẽ được **điền sẵn** khi build workbook (vd. tên đơn vị, ngày hiện tại). | API: `/api/v1/forms/{formId}/sheets/{sheetId}/columns/{colId}/data-binding` (FormColumnDataBindingController). |
| C6 | **Cấu hình Mapping cột → lưu dữ liệu** | SystemAdmin, FormAdmin | Map mỗi FormColumn → cột lưu trong ReportDataRow: TextValue1/2, NumericValue1–20, … (TargetColumnName, TargetColumnIndex). Khi nhập liệu, giá trị ô sẽ ghi vào đúng cột DB. | API: `/api/v1/forms/{formId}/sheets/{sheetId}/column-mapping` (FormColumnMappingController). |
| C7 | **(Tuỳ chọn) Vùng chỉ tiêu động (B12)** | SystemAdmin, FormAdmin | Block **Vùng chỉ tiêu động** → Thêm FormDynamicRegion (SheetId, IndicatorCatalogId, …) → Trên submission, đơn vị sẽ chọn chỉ tiêu từ danh mục và nhập giá trị (ReportDynamicIndicator). | API: `/api/v1/forms/{formId}/sheets/{sheetId}/dynamic-regions` (FormDynamicRegionsController). Submission: PUT `/api/v1/submissions/{id}/dynamic-indicators`. |
| C8 | **(Tuỳ chọn) Lọc động & placeholder dòng/cột (P8)** | SystemAdmin, FormAdmin | Tạo **DataSource** → **FilterDefinition** + FilterCondition → Trên form: **FormPlaceholderOccurrence** (dòng động), **FormDynamicColumnRegion** + **FormPlaceholderColumnOccurrence** (cột động). Khi mở workbook, số hàng/cột động được resolve từ nguồn + bộ lọc. | API: DataSourcesController, FilterDefinitionsController; FormPlaceholderOccurrencesController, FormDynamicColumnRegionsController, FormPlaceholderColumnOccurrencesController. |
| C9 | **Gắn quy trình phê duyệt cho form** | SystemAdmin, FormAdmin | Trong cấu hình form: chọn **WorkflowDefinition** (đã tạo ở A6) → Lưu FormWorkflowConfig. Submission của form này khi **Gửi duyệt** sẽ chạy quy trình đã chọn. | API: `/api/v1/forms/{formId}/workflow-config` (FormWorkflowConfigController). |
| C10 | **Xuất bản form (Published)** | SystemAdmin, FormAdmin | (Tuỳ nghiệp vụ) Đổi trạng thái form từ Draft → Published để đơn vị có thể dùng form này tạo submission. | API: PUT `/api/v1/forms/{id}` (status: Published) hoặc endpoint riêng nếu có. |

**Kết quả C:** Form có đầy đủ Sheet, Column, Row, DataBinding, ColumnMapping; (tuỳ chọn) B12, P8; FormWorkflowConfig; form có thể Published.

---

## 6. Giai đoạn D – Mở kỳ báo cáo & tạo submission (báo cáo) cho đơn vị

**Mục đích:** Có **kỳ báo cáo** đang mở và (tùy cách vận hành) **submission** (bản ghi báo cáo) cho từng cặp (Form, Đơn vị, Kỳ). Đơn vị có thể **tự tạo submission** (nếu có quyền) hoặc **admin tạo sẵn** (bulk) cho nhiều đơn vị.

| # | Công việc | Ai làm | Làm như thế nào | Chức năng (FE / API) |
|---|-----------|--------|------------------|----------------------|
| D1 | **Đảm bảo đã có kỳ báo cáo** | SystemAdmin, FormAdmin | (Nếu chưa tạo ở A5) Vào **Kỳ báo cáo** → Thêm kỳ với trạng thái Open/Active, có Deadline. | FE: `/reporting-periods`. API: `/api/v1/reporting-periods`. |
| D2 | **Tạo submission (một báo cáo) – đơn vị tự tạo** | UnitAdmin, DataEntry (trong phạm vi đơn vị) | Vào **Báo cáo** (Submissions) → **Tạo báo cáo** → Chọn **Biểu mẫu**, **Kỳ báo cáo**, **Đơn vị** (thường chỉ chọn được đơn vị mình thuộc do RLS). Hệ thống tạo 1 ReportSubmission (FormDefinitionId, OrganizationId, ReportingPeriodId), trạng thái **Draft**. | FE: `/submissions` (SubmissionsPage) → Modal “Tạo báo cáo”, form chọn Form + Period + Organization. API: POST `/api/v1/submissions` (body: formDefinitionId, organizationId, reportingPeriodId). |
| D3 | **Tạo submission hàng loạt (bulk) – admin** | SystemAdmin, FormAdmin | Trên trang **Báo cáo**: chọn Form, Version, Kỳ → Chọn **nhiều đơn vị** → **Tạo hàng loạt**. Hệ thống tạo nhiều ReportSubmission (mỗi cặp form–org–period một bản Draft). | FE: `/submissions` (SubmissionsPage), flow bulk create. API: POST `/api/v1/submissions` (có thể gọi nhiều lần hoặc endpoint bulk nếu có). |

**Kết quả D:** Có ít nhất một ReportSubmission trạng thái **Draft** cho (Form, Organization, ReportingPeriod). Submission này sẽ được **mở để nhập liệu** ở giai đoạn E.

---

## 7. Giai đoạn E – Đơn vị nhập liệu

**Mục đích:** Đơn vị (user có vai trò UnitAdmin hoặc DataEntry trong đơn vị đó) **mở báo cáo Draft** (hoặc Revision), **nhập/sửa số liệu** trên giao diện giống Excel, **lưu**, sau đó **Gửi duyệt**.

| # | Công việc | Ai làm | Làm như thế nào | Chức năng (FE / API) |
|---|-----------|--------|------------------|----------------------|
| E1 | **Xem danh sách báo cáo** | UnitAdmin, DataEntry, Viewer | Vào **Báo cáo** → Danh sách submission (lọc theo Form, Kỳ, Trạng thái). RLS chỉ trả submission thuộc đơn vị user. | FE: `/submissions` (SubmissionsPage). API: GET `/api/v1/submissions` (query: formDefinitionId, reportingPeriodId, status). |
| E2 | **Mở màn nhập liệu** | UnitAdmin, DataEntry | Từ danh sách: bấm **Nhập liệu** (hoặc mở submission Draft/Revision) → Chuyển đến trang nhập liệu theo submissionId. | FE: Navigate `/submissions/:submissionId/entry` (SubmissionDataEntryPage). |
| E3 | **Load workbook (cấu trúc + dữ liệu)** | Hệ thống (backend) | Khi vào trang entry, FE gọi **workbook-data**: backend build workbook từ FormDefinition (sheet, cột, hàng, binding, B12, P8) + ReportDataRow + ReportPresentation + ReportDynamicIndicator. Trả JSON workbook (sheet, cells, merge, style). Nếu có placeholder (P8), số hàng/cột động đã được resolve. | API: GET `/api/v1/submissions/{id}/workbook-data` (SubmissionsController). Service: BuildWorkbookFromSubmissionService. |
| E4 | **Hiển thị lưới Excel & nhập/sửa ô** | UnitAdmin, DataEntry | FE dùng component **Fortune-sheet** (hoặc tương đương) render workbook; user chỉnh sửa ô (chỉ ô được phép sửa theo FormColumn IsEditable). Có thể có block **Chỉ tiêu động** (B12): bảng Tên chỉ tiêu / Giá trị, Thêm dòng, Lưu chỉ tiêu động. | FE: SubmissionDataEntryPage (Fortune-sheet, state cells); block “Chỉ tiêu động” → PUT dynamic-indicators. |
| E5 | **Lưu nháp** | UnitAdmin, DataEntry | User bấm **Lưu** → FE gửi dữ liệu ô lên server. Backend: **sync-from-presentation** (từ workbook JSON → cập nhật ReportDataRow); hoặc PUT **presentation** (lưu WorkbookJson); (nếu có) PUT **dynamic-indicators**. Submission vẫn **Draft** (hoặc **Revision**). | API: PUT `/api/v1/submissions/{id}/presentation` (ReportPresentationsController); POST `/api/v1/submissions/{id}/sync-from-presentation`; PUT `/api/v1/submissions/{id}/dynamic-indicators`. |
| E6 | **(Tuỳ chọn) Upload file Excel thay thế** | UnitAdmin, DataEntry | Trên submission: **Upload Excel** (file .xlsx) → Backend parse và ghi ReportDataRow + ReportPresentation. Dùng khi đơn vị có sẵn file điền ngoài hệ thống. | FE: SubmissionsPage hoặc SubmissionDataEntryPage, nút Upload. API: POST `/api/v1/submissions/{id}/upload-excel` (multipart). |
| E7 | **Gửi duyệt** | UnitAdmin, DataEntry | Khi đã nhập xong: bấm **Gửi duyệt**. Backend: đổi trạng thái submission **Draft/Revision → Submitted**, tạo **WorkflowInstance** (Pending), (tuỳ chọn) gửi thông báo cho người duyệt. | FE: SubmissionsPage (hoặc trong entry), nút “Gửi duyệt”. API: POST `/api/v1/submissions/{id}/submit`. |
| E8 | **Xuất file Excel (đã nhập)** | UnitAdmin, DataEntry, Viewer | Trong màn nhập liệu hoặc danh sách: **Xuất Excel** → tải file .xlsx phản ánh dữ liệu hiện tại. | FE: Nút “Xuất Excel”. API: (có thể dùng workbook-data hoặc endpoint export .xlsx). |

**Kết quả E:** Submission đã được nhập liệu và chuyển sang **Submitted**. Bước tiếp theo (ngoài phạm vi “nhập liệu”) là **người duyệt** (Workflow.Approve) thực hiện Approve / Reject / RequestRevision trên WorkflowInstance.

---

## 8. Bảng tương ứng công việc ↔ Chức năng (tóm tắt)

| Giai đoạn | Công việc điển hình | Vai trò | Trang FE | API chính |
|-----------|----------------------|---------|----------|-----------|
| A | Đơn vị, User, Kỳ, Quy trình | SystemAdmin, FormAdmin, UnitAdmin* | /organizations, /users, /reporting-periods, /workflow-definitions | organization-types, organizations, users, reporting-frequencies, reporting-periods, workflow-definitions, workflow-steps |
| B | Tạo form (trống / từ template) | SystemAdmin, FormAdmin | /forms | POST /forms, POST /forms/from-template |
| C | Sheet, Cột, Hàng, Binding, Mapping, B12, P8, Workflow config | SystemAdmin, FormAdmin | /forms/:id/config | form-sheets, form-columns, form-rows, data-binding, column-mapping, dynamic-regions, placeholder-*, data-sources, filter-definitions, workflow-config |
| D | Tạo submission (1 hoặc bulk) | FormAdmin, UnitAdmin, DataEntry | /submissions | POST /submissions |
| E | Xem list, Mở entry, Load workbook, Nhập, Lưu, Gửi duyệt | UnitAdmin, DataEntry | /submissions, /submissions/:id/entry | GET /submissions, GET workbook-data, PUT presentation, sync-from-presentation, PUT dynamic-indicators, POST submit |

---

## 9. Sơ đồ luồng (theo vai trò)

```
[SystemAdmin / FormAdmin]
    → A: Tạo đơn vị, user, kỳ, quy trình
    → B: Tạo form (trống hoặc từ template)
    → C: Cấu hình sheet/cột/binding/mapping/B12/P8, gắn workflow
    → D (tuỳ chọn): Tạo submission bulk cho nhiều đơn vị

[UnitAdmin / DataEntry] (đăng nhập, chọn vai trò + đơn vị)
    → D: Tạo báo cáo (1 submission) hoặc nhận báo cáo đã tạo sẵn
    → E: Vào Báo cáo → Mở submission Draft/Revision
    → E: Nhập liệu (workbook) → Lưu → Gửi duyệt
```

---

## 10. Tài liệu tham chiếu

- Yêu cầu nghiệp vụ: [01.YEU_CAU_HE_THONG.md](script_core/01.YEU_CAU_HE_THONG.md).
- Permission & schema: [03.DATABASE_SCHEMA.md](script_core/03.DATABASE_SCHEMA.md).
- Demo từng bước: [DEMO_SCRIPT.md](DEMO_SCRIPT.md).
- Rà soát tổng hợp: [RA_SOAT_NGHIEP_VU_TONG_HOP.md](RA_SOAT_NGHIEP_VU_TONG_HOP.md).
