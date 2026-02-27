# P8 – Lọc động theo trường & Placeholder (P8a–P8f)

**Tham chiếu:** [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md), [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md) mục 4.4–4.9.

---

## P8a – DB + API (DataSource, FilterDefinition, FormPlaceholderOccurrence)

### Đã triển khai

- **SQL:** `docs/script_core/sql/v2/21.p8_filter_placeholder.sql` – BCDT_DataSource, BCDT_FilterDefinition, BCDT_FilterCondition, BCDT_FormPlaceholderOccurrence.
- **BE:** Entity + DbContext; CRUD API:
  - `GET/POST /api/v1/data-sources`, `GET/PUT/DELETE /api/v1/data-sources/{id}`, `GET /api/v1/data-sources/{id}/columns`
  - `GET/POST /api/v1/filter-definitions`, `GET/PUT/DELETE /api/v1/filter-definitions/{id}` (kèm conditions trong body)
  - `GET/POST /api/v1/forms/{formId}/sheets/{sheetId}/placeholder-occurrences`, `GET/PUT/DELETE .../{occurrenceId}`

### Kiểm tra cho AI (P8a)

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 1 | Script | Chạy `21.p8_filter_placeholder.sql` (sau 01–20). | 4 bảng tạo; không lỗi. |
| 2 | Query bảng | `SELECT name FROM sys.tables WHERE name IN ('BCDT_DataSource','BCDT_FilterDefinition','BCDT_FilterCondition','BCDT_FormPlaceholderOccurrence')` | 4 dòng. |
| 3 | Build BE | Hủy process BCDT.Api (RUNBOOK 6.1). `dotnet build src/BCDT.Api/BCDT.Api.csproj` | Build succeeded. |
| 4 | GET data-sources | GET /api/v1/data-sources, Bearer token | 200, [ ]. |
| 5 | POST data-source | POST /api/v1/data-sources (FormStructureAdmin), body { Code, Name, SourceType: "Table", SourceRef: "BCDT_Organization" } | 201, id. |
| 6 | GET data-sources/{id}/columns | GET /api/v1/data-sources/{id}/columns (id từ bước 5) | 200, danh sách cột (Name, DataType). |
| 7 | GET filter-definitions | GET /api/v1/filter-definitions | 200, [ ]. |
| 8 | POST filter-definition | POST /api/v1/filter-definitions, body { Code, Name, LogicalOperator: "AND", Conditions: [{ ConditionOrder: 0, Field: "Id", Operator: "Gt", ValueType: "Literal", Value: "0" }] } | 201, id. |
| 9 | GET placeholder-occurrences | GET /api/v1/forms/{formId}/sheets/{sheetId}/placeholder-occurrences (formId, sheetId hợp lệ) | 200, [ ]. |
| 10 | POST placeholder-occurrence | POST .../placeholder-occurrences (FormStructureAdmin), body { FormDynamicRegionId, ExcelRowStart, FilterDefinitionId, DisplayOrder } | 201, id. |

**Script tự chạy bước 4–10:** [test-p8-checklist-4-10.ps1](../script_core/test-p8-checklist-4-10.ps1). Yêu cầu: API chạy (http://localhost:5080), user admin/Admin@123 có quyền FormStructureAdmin. Form/sheet mẫu: formId=4, sheetId=6, FormDynamicRegionId=1.

---

## P8b – Engine resolve filter + Build workbook N hàng (đã triển khai)

- **ParameterContext:** ReportDate, OrganizationId, SubmissionId, ReportingPeriodId, CurrentDate, UserId, CatalogId (Application/Services/Form/ParameterContext.cs).
- **IDataSourceQueryService / DataSourceQueryService:** QueryWithFilterAsync(dataSourceId, filterDefinitionId, context, maxRows) — resolve FilterCondition (Parameter → context, Literal → ép kiểu), whitelist cột từ GetColumns, WHERE parameterized, SELECT * FROM [SourceRef] (Table/View).
- **BuildWorkbookFromSubmissionService:** Load FormPlaceholderOccurrence theo sheet; với mỗi occurrence có DataSourceId: gọi QueryWithFilterAsync → map DisplayColumn/ValueColumn → N hàng; không có DataSourceId: giữ logic catalog + ReportDynamicIndicator. Mỗi occurrence = một block (ExcelRowStart từ occurrence, ExcelColName/ExcelColValue từ region). Legacy: vùng không có occurrence vẫn build như cũ.

**Kiểm tra P8b:** Tạo submission có form/sheet có ít nhất 1 FormPlaceholderOccurrence (DataSourceId + FilterDefinitionId trỏ tới bảng có dữ liệu); GET /api/v1/submissions/{id}/workbook-data; response.sheets[].dynamicRegions chứa block tương ứng với số hàng từ query.

---

## P8c – FE Nguồn dữ liệu, Bộ lọc, Vị trí placeholder (đã triển khai)

- **FE:** Trang Cấu hình biểu mẫu (`/forms/:formId/config`):
  - Card **P8 – Nguồn dữ liệu:** bảng + modal CRUD (Code, Name, SourceType, SourceRef, DisplayColumn, ValueColumn, …). API: `formDataSourceFilterApi.dataSourcesApi`.
  - Card **P8 – Bộ lọc:** bảng + modal CRUD (Code, Name, LogicalOperator, DataSourceId, danh sách điều kiện Field/Operator/ValueType/Value). API: `formDataSourceFilterApi.filterDefinitionsApi`.
  - Card **P8 – Vị trí placeholder:** (khi đã chọn sheet) bảng + modal (FormDynamicRegionId, ExcelRowStart, FilterDefinitionId, DataSourceId, DisplayOrder, MaxRows). API: `formDataSourceFilterApi.formPlaceholderOccurrencesApi`.
- **Types:** `form.types.ts` (DataSourceDto, FilterDefinitionDto, FormPlaceholderOccurrenceDto, Create/Update request). **API client:** `api/formDataSourceFilterApi.ts` (nguồn dữ liệu + bộ lọc + vị trí placeholder).

### Kiểm tra cho AI (P8c)

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 1 | Build FE | `npm run build` trong `src/bcdt-web` | Build thành công (tsc + vite). |
| 2 | Mở FormConfig | Đăng nhập, vào Biểu mẫu → chọn 1 form → Cấu hình (hoặc `/forms/{id}/config`). | Thấy 3 card: P8 – Nguồn dữ liệu, P8 – Bộ lọc, Sheet (Hàng). |
| 3 | Nguồn dữ liệu | Bấm "Thêm nguồn dữ liệu", điền Mã/Tên, Loại Table, SourceRef (vd BCDT_Organization), Lưu. | Modal đóng, bảng có 1 dòng mới. |
| 4 | Bộ lọc | Bấm "Thêm bộ lọc", điền Mã/Tên, thêm 1 điều kiện (Field, Operator, Value), Lưu. | Modal đóng, bảng Bộ lọc có 1 dòng mới. |
| 5 | Vị trí placeholder | Chọn 1 sheet có "Vùng chỉ tiêu động"; kéo xuống "P8 – Vị trí placeholder". Bấm "Thêm vị trí placeholder", chọn Vùng chỉ tiêu, Hàng Excel, (tùy chọn Bộ lọc/Nguồn), Lưu. | Bảng Vị trí placeholder có 1 dòng mới. |

---

## P8d – Test E2E/checklist P8 (đã thực hiện 2026-02-10)

- **Mục tiêu:** Chạy đủ checklist P8a (4–10), P8b (workbook-data dynamicRegions), P8c (FE build + FormConfig 3 card); báo Pass/Fail từng bước.

### Kiểm tra cho AI (P8d)

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 1 | P8a bước 4–10 | Chạy `docs/script_core/test-p8-checklist-4-10.ps1` (API chạy localhost:5080, admin/Admin@123). | 7/7 Pass. |
| 2 | P8b workbook-data | Có submission form có sheet chứa FormPlaceholderOccurrence (DataSourceId + FilterDefinitionId). GET /api/v1/submissions/{id}/workbook-data. | 200; response.sheets[].dynamicRegions có ít nhất 1 block, mỗi block có rows (indicatorName, indicatorValue). |
| 3 | P8c bước 1 | `npm run build` trong `src/bcdt-web`. | Build thành công (tsc + vite). |
| 4 | P8c bước 2–5 | (Thủ công hoặc E2E) Mở FormConfig, thử CRUD Nguồn dữ liệu, Bộ lọc, Vị trí placeholder. | Thấy 3 card P8; thêm/sửa/xóa thành công. |

**Kết quả lần chạy 2026-02-10:** P8a 4–10: 7/7 Pass. P8b: Pass (submission 23, workbook-data có dynamicRegions với blocks có rows). P8c-1 (Build FE): Pass. P8c-2–5: Cần kiểm tra thủ công khi chạy FE.

---

## P8e – DB + API + Build workbook N cột (đã triển khai)

- **SQL:** `docs/script_core/sql/v2/22.p8_column_placeholder.sql` – BCDT_FormDynamicColumnRegion, BCDT_FormPlaceholderColumnOccurrence.
- **BE:** Entity FormDynamicColumnRegion, FormPlaceholderColumnOccurrence; CRUD API:
  - `GET/POST /api/v1/forms/{formId}/sheets/{sheetId}/dynamic-column-regions`, `GET/PUT/DELETE .../dynamic-column-regions/{regionId}`
  - `GET/POST /api/v1/forms/{formId}/sheets/{sheetId}/placeholder-column-occurrences`, `GET/PUT/DELETE .../placeholder-column-occurrences/{occurrenceId}`
- **Build workbook:** Với mỗi FormPlaceholderColumnOccurrence (cột), resolve nguồn cột (ByReportingPeriod, ByDataSource, ByCatalog, Fixed) + FilterDefinition → danh sách nhãn cột; trả trong `sheets[].dynamicColumnRegions` (ExcelColStart, columnLabels).

### Kiểm tra cho AI (P8e)

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 1 | Script | Chạy `22.p8_column_placeholder.sql` (sau 01–21). | 2 bảng tạo; không lỗi. |
| 2 | Query bảng | `SELECT name FROM sys.tables WHERE name IN ('BCDT_FormDynamicColumnRegion','BCDT_FormPlaceholderColumnOccurrence')` | 2 dòng. |
| 3 | Build BE | Hủy process BCDT.Api. `dotnet build src/BCDT.Api/BCDT.Api.csproj` | Build succeeded. |
| 4 | GET dynamic-column-regions | GET /api/v1/forms/{formId}/sheets/{sheetId}/dynamic-column-regions, Bearer | 200, [ ]. |
| 5 | POST dynamic-column-region | POST .../dynamic-column-regions (FormStructureAdmin), body { code, name, columnSourceType: "ByReportingPeriod", displayOrder } | 201, id. |
| 6 | GET placeholder-column-occurrences | GET .../placeholder-column-occurrences | 200, [ ]. |
| 7 | POST placeholder-column-occurrence | POST .../placeholder-column-occurrences, body { formDynamicColumnRegionId, excelColStart, displayOrder } | 201, id. |
| 8 | Workbook-data | Có submission + sheet có FormPlaceholderColumnOccurrence. GET /api/v1/submissions/{id}/workbook-data. | 200; sheets[].dynamicColumnRegions có block (excelColStart, columnLabels). |

---

## P8f – FE Vùng cột động + Vị trí placeholder cột (đã triển khai)

- **FE:** FormConfig: card **P8 – Vùng cột động** (bảng + modal CRUD FormDynamicColumnRegion: Code, Name, ColumnSourceType, ColumnSourceRef, LabelColumn). Card **P8 – Vị trí placeholder cột** (bảng + modal FormPlaceholderColumnOccurrence: Vùng cột động, Cột Excel, Bộ lọc, Max cột). API: `formDataSourceFilterApi.formDynamicColumnRegionsApi`, `formPlaceholderColumnOccurrencesApi`.

### Kiểm tra cho AI (P8f)

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 1 | Build FE | `npm run build` trong `src/bcdt-web` | Build thành công. |
| 2 | FormConfig | Đăng nhập, vào Biểu mẫu → Cấu hình → chọn sheet. | Thấy card "P8 – Vùng cột động", "P8 – Vị trí placeholder cột (mở rộng N cột)". |
| 3 | CRUD vùng cột | Thêm vùng cột động (Mã, Tên, Nguồn cột ByReportingPeriod), Lưu. | Bảng có 1 dòng mới. |
| 4 | CRUD vị trí cột | Thêm vị trí placeholder cột (chọn Vùng cột động, Cột Excel 1), Lưu. | Bảng có 1 dòng mới. |

**Version:** 1.4 · **Last updated:** 2026-02-06 (P8e, P8f triển khai: DB, API, Build workbook N cột, FE 2 card)
