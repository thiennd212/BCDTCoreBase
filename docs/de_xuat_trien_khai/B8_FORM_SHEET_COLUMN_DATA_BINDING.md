# B8 – Form Sheet, Form Column, Data Binding, Column Mapping

**Phase 2 – Week 5–6** (tiếp B7).  
**Mục tiêu:** API CRUD cho Sheet, Column; CRUD cấu hình Data Binding và Column Mapping; đặc tả Data Binding Engine; đề xuất Excel Generator.

---

## 1. Tham chiếu

| Tài liệu | Nội dung |
|----------|----------|
| [04.form_definition.sql](../script_core/sql/v2/04.form_definition.sql) | BCDT_FormSheet, BCDT_FormColumn, BCDT_FormDataBinding, BCDT_FormColumnMapping |
| [B7_FORM_DEFINITION.md](B7_FORM_DEFINITION.md) | FormDefinition, FormVersion CRUD |
| [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md) | Phase 2: Form structure, Data Binding Engine, Excel Generator |
| [LUU_Y_CAU_TRUC_BIEU_MAU_VA_CHI_TIEU.md](../LUU_Y_CAU_TRUC_BIEU_MAU_VA_CHI_TIEU.md) | Lưu ý nghiệp vụ: System Admin khởi tạo cấu trúc; chỉ tiêu cố định vs placeholder chỉ tiêu động |

---

## 2. Đã triển khai (Backend)

### 2.1. Domain entities

- **FormSheet** – BCDT_FormSheet (FormDefinitionId, SheetIndex, SheetName, DisplayName, IsDataSheet, IsVisible, DisplayOrder).
- **FormColumn** – BCDT_FormColumn (FormSheetId, ColumnCode, ColumnName, ExcelColumn, DataType, IsRequired, IsEditable, ValidationRule, …).
- **FormDataBinding** – BCDT_FormDataBinding (FormColumnId, BindingType, SourceTable/SourceColumn, ApiEndpoint, Formula, DefaultValue, …).
- **FormColumnMapping** – BCDT_FormColumnMapping (FormColumnId, TargetColumnName, TargetColumnIndex, AggregateFunction).

### 2.2. API REST

| Method | Route | Mô tả |
|--------|-------|--------|
| GET / POST | /api/v1/forms/{formId}/sheets | Danh sách / Tạo sheet |
| GET / PUT / DELETE | /api/v1/forms/{formId}/sheets/{sheetId} | Chi tiết / Cập nhật / Xóa sheet |
| GET / POST | /api/v1/forms/{formId}/sheets/{sheetId}/columns | Danh sách / Tạo cột |
| GET / PUT / DELETE | /api/v1/forms/{formId}/sheets/{sheetId}/columns/{columnId} | Chi tiết / Cập nhật / Xóa cột |
| GET / POST / PUT / DELETE | .../columns/{columnId}/data-binding | Cấu hình data binding (một cột một binding) |
| GET / POST / PUT / DELETE | .../columns/{columnId}/column-mapping | Cấu hình column mapping (một cột một mapping) |

Response chuẩn: `{ "success": true, "data": ... }` hoặc `ApiErrorResponse`.

### 2.3. Services

- **IFormSheetService** / FormSheetService – GetByFormId, GetById, Create, Update, Delete. Kiểm tra FormDefinitionId, unique SheetIndex theo form.
- **IFormColumnService** / FormColumnService – GetBySheetId, GetById, Create, Update, Delete. Kiểm tra sheet thuộc form, DataType trong (Text, Number, Date, Formula, Reference, Boolean), unique ColumnCode trong sheet.
- **IFormDataBindingService** / FormDataBindingService – GetByColumnId, Create, Update, Delete. BindingType: Static, Database, API, Formula, Reference, Organization, System. Mỗi cột tối đa một binding.
- **IFormColumnMappingService** / FormColumnMappingService – GetByColumnId, Create, Update, Delete. Mỗi cột tối đa một mapping.

---

## 3. Đặc tả Data Binding Engine

**Data Binding Engine** là bộ xử lý dùng cấu hình trong **BCDT_FormDataBinding** để lấy/ghi giá trị cho từng cột (ví dụ khi mở form, export Excel, hoặc khi lưu dữ liệu).

### 3.1. Các loại BindingType

| BindingType | Mô tả | Nguồn dữ liệu |
|-------------|--------|----------------|
| **Static** | Giá trị tĩnh | DefaultValue hoặc giá trị mặc định theo DataType |
| **Database** | Truy vấn DB | SourceTable, SourceColumn, SourceCondition (WHERE) |
| **API** | Gọi API ngoài | ApiEndpoint, ApiMethod, ApiResponsePath (JSON path) |
| **Formula** | Công thức | Formula (biểu thức hoặc tham chiếu cột khác) |
| **Reference** | Tham chiếu bảng mã | ReferenceEntityTypeId, ReferenceDisplayColumn |
| **Organization** | Đơn vị (cây tổ chức) | Dùng session / RLS để lọc theo OrganizationId |
| **System** | Hệ thống (ngày, user, …) | Giá trị từ context: CurrentDate, CurrentUserId, … |

### 3.2. Luồng xử lý đề xuất

1. **Khi load form (đọc):**
   - Với mỗi FormColumn có FormDataBinding:
     - Nếu BindingType = Static → trả về DefaultValue.
     - Nếu Database → thực thi query (parameterized), map SourceColumn → giá trị ô.
     - Nếu API → gọi HTTP, parse JSON theo ApiResponsePath.
     - Nếu Reference → query bảng reference tương ứng ReferenceEntityTypeId.
     - Nếu Organization → lấy danh sách đơn vị (theo RLS/session).
     - Nếu System → resolve CurrentDate, CurrentUserId, v.v.
   - Áp dụng TransformExpression nếu có (bước sau cùng).
   - Cache: nếu CacheMinutes > 0, cache kết quả theo key (formId, columnId, context).

2. **Khi lưu dữ liệu (ghi):**
   - FormColumnMapping chỉ ra cột Excel → TargetColumnName, TargetColumnIndex (bảng lưu trữ).
   - Engine ghi giá trị ô vào đúng cột trong ReportDataRow / ReportPresentation (theo đặc tả Data Storage).

### 3.3. Triển khai gợi ý

- **IDataBindingResolver** (Application): interface với method `ResolveValueAsync(FormDataBinding binding, ResolveContext context, CancellationToken)`.
- **DataBindingResolver** (Infrastructure): implement từng nhánh theo BindingType; inject IDbContext hoặc IHttpClientFactory cho Database/API.
- Gọi resolver từ service Excel Generator hoặc service “Load form template” khi cần điền giá trị mặc định.

---

## 4. Đề xuất Excel Generator

**Mục tiêu:** Sinh file Excel từ Form Definition (sheets, columns, binding) để người dùng tải template hoặc điền sẵn dữ liệu.

### 4.1. Cách tiếp cận

1. **Thư viện:** ClosedXML hoặc EPPlus (open source, .NET). Ví dụ: ClosedXML tạo workbook, thêm sheet theo FormSheet, tạo header/cột theo FormColumn (ExcelColumn = A, B, C…).
2. **Input:** FormDefinitionId (hoặc FormVersionId). Lấy FormDefinition → FormSheets (theo DisplayOrder/SheetIndex) → FormColumns (theo DisplayOrder).
3. **Cấu trúc file:**
   - Mỗi FormSheet → một Worksheet (tên SheetName).
   - Mỗi FormColumn → cột Excel tại ExcelColumn (A, B, …); hàng 1 có thể là header (ColumnName).
   - Ô có thể set Format theo FormColumn.Format (số, ngày).
   - Lock/protect ô theo FormColumn.IsEditable (nếu false thì khóa ô).
4. **Điền giá trị mặc định:**
   - Gọi Data Binding Engine cho từng cột (BindingType Static, Database, Reference, System, …) để lấy giá trị.
   - Ghi vào ô tương ứng (ví dụ row 2 cho dữ liệu mẫu).
5. **Output:** byte[] (file Excel). API endpoint ví dụ: `GET /api/v1/forms/{id}/template` hoặc `GET /api/v1/forms/{id}/versions/{versionId}/template` trả về file.

### 4.2. API đề xuất

| Method | Route | Mô tả |
|--------|-------|--------|
| GET | /api/v1/forms/{id}/template | Sinh Excel từ FormDefinition hiện tại (sheets + columns). Optional query: fillBinding=true để điền giá trị từ Data Binding. Trả về file (application/vnd.openxmlformats-officedocument.spreadsheetml.sheet). |

### 4.3. Lưu ý

- TemplateFile trong BCDT_FormDefinition (VARBINARY) có thể dùng làm “gốc” thay vì sinh từ đầu; nếu có thì merge cấu trúc (sheet/column) với file gốc.
- FormRow, FormCell (04.form_definition.sql) dùng cho layout chi tiết (hàng động, merge ô) – có thể triển khai ở giai đoạn sau.

---

## 5. Điều kiện cần và đủ để hoàn thành công việc

### 5.1. Điều kiện cần (bắt buộc)

| # | Điều kiện | Cách kiểm tra | Trạng thái |
|---|-----------|----------------|------------|
| 1 | **Database** đã chạy script 01→14 (trong đó 04.form_definition.sql tạo 8 bảng Form) | Xem [VERIFY_TABLES.md](../script_core/sql/v2/VERIFY_TABLES.md). DB phải có: BCDT_FormSheet, BCDT_FormColumn, BCDT_FormDataBinding, BCDT_FormColumnMapping. | Cần xác nhận DB đã chạy 04 |
| 2 | **Build** solution thành công | Tắt process BCDT.Api (RUNBOOK 6.1), chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj` → Build succeeded. | Chặn bởi: API đang chạy khóa file → **tắt API rồi build** |
| 3 | **DI** đăng ký đủ 4 service | Program.cs: AddScoped IFormSheetService, IFormColumnService, IFormDataBindingService, IFormColumnMappingService. | ✅ Đã đăng ký |
| 4 | **API route** đúng chuẩn REST | FormSheetsController, FormColumnsController, FormColumnDataBindingController, FormColumnMappingController; response { success, data } / ApiErrorResponse. | ✅ Đã triển khai |
| 5 | **appsettings** có ConnectionStrings | API khởi động được, kết nối DB không lỗi. | Cần chạy API để xác nhận |

### 5.2. Điều kiện đủ (để coi là hoàn thành)

| # | Điều kiện | Ghi chú |
|---|-----------|--------|
| 1 | Gọi được GET/POST /api/v1/forms/{id}/sheets (sau khi login) | Có formId từ GET /api/v1/forms. |
| 2 | Gọi được GET/POST .../sheets/{sheetId}/columns | Có sheetId từ bước trên. |
| 3 | Gọi được GET/POST .../columns/{columnId}/data-binding và .../column-mapping | Có columnId từ bước trên. |
| 4 | Không có lỗi biên dịch (C#) | Domain, Application, Infrastructure build OK (chỉ BCDT.Api bị lock khi process đang chạy). |
| 5 | Tài liệu đặc tả Data Binding Engine và đề xuất Excel Generator | B8 mục 3 và 4. |

### 5.3. Hành động trước khi báo hoàn thành

1. **Tắt BCDT.Api** (nếu đang chạy): Task Manager hoặc `Stop-Process -Id 27344 -Force` (thay 27344 bằng PID thực tế).
2. **Build:** `dotnet build src/BCDT.Api/BCDT.Api.csproj` → phải báo Build succeeded.
3. **Chạy API**, đăng nhập, gọi lần lượt các endpoint trong mục 5.2 (hoặc checklist mục 6 bên dưới).

---

## 6. Kiểm tra nhanh (sau khi tắt BCDT.Api)

1. **Build:** `dotnet build src/BCDT.Api/BCDT.Api.csproj` → Build succeeded.
2. Chạy API, login, lấy token.
3. GET /api/v1/forms → chọn một formId.
4. POST /api/v1/forms/{formId}/sheets → body `{ "sheetIndex": 0, "sheetName": "Sheet1", "displayOrder": 0 }` → 200, data có Id.
5. GET /api/v1/forms/{formId}/sheets → 200, mảng có 1 sheet.
6. POST /api/v1/forms/{formId}/sheets/{sheetId}/columns → body `{ "columnCode": "A1", "columnName": "Mã", "excelColumn": "A", "dataType": "Text", "displayOrder": 0 }` → 200.
7. GET .../columns/{columnId}/data-binding → 404 (chưa cấu hình). POST .../data-binding → body `{ "bindingType": "Static", "defaultValue": "N/A" }` → 200.
8. GET .../column-mapping → 404. POST .../column-mapping → body `{ "targetColumnName": "TextValue1", "targetColumnIndex": 0 }` → 200.

---

## 7. Chạy tự test đầy đủ (25 case)

Script: **[docs/script_core/test-b8-checklist.ps1](../script_core/test-b8-checklist.ps1)**. Kết quả ghi vào `docs/script_core/b8-checklist-result.txt`.

**Điều kiện:** API đang chạy tại http://localhost:5080 và **đã build bản có B8** (FormSheetsController, FormColumnsController, …). Nếu API cũ (chưa build sau khi thêm B8), bước 3–4 sẽ 404.

**Cách chạy:**

1. Tắt process BCDT.Api (nếu đang chạy).
2. `dotnet build src/BCDT.Api/BCDT.Api.csproj` → Build succeeded.
3. Chạy API: `dotnet run --project src/BCDT.Api` (hoặc F5 trong IDE).
4. Trong PowerShell: `.\docs\script_core\test-b8-checklist.ps1`
5. Mở `docs\script_core\b8-checklist-result.txt` — kỳ vọng 25 dòng Pass.

**Các case được test:**

| # | Case | Kỳ vọng |
|---|------|--------|
| 1 | Login | Pass |
| 2 | GET forms / POST form (nếu chưa có) | Pass |
| 3–6 | GET/POST/GET by id/PUT sheet | Pass |
| 7–10 | GET/POST/GET by id/PUT column | Pass |
| 11–14 | GET (404) / POST / GET / PUT data-binding | Pass |
| 15–18 | GET (404) / POST / GET / PUT column-mapping | Pass |
| 19 | POST sheet trùng SheetIndex | 409 Conflict |
| 20 | POST column trùng ColumnCode | 409 Conflict |
| 21–22 | DELETE data-binding, DELETE column-mapping | Pass |
| 23–24 | DELETE column, DELETE sheet | Pass |
| 25 | GET sheet sau khi xóa | 404 |

---

**Version:** 1.0  
**Ngày:** 2026-02-03
