# Giải pháp: Cấu trúc biểu mẫu – Chỉ tiêu cố định & Chỉ tiêu động (Placeholder)

**Yêu cầu bắt buộc.** Tài liệu này phân tích, đánh giá và đưa ra giải pháp đầy đủ, chuyên nghiệp, hiệu năng tốt cho:

1. Khởi tạo cấu trúc biểu mẫu do **System Admin** (thông tin biểu mẫu, sheet, cột, hàng, công thức, khóa, format, style, bộ lọc, ánh xạ).
2. Hai thành phần chỉ tiêu: **cố định (cứng)** và **placeholder cho chỉ tiêu động** (đơn vị tự nhập).
3. Kết hợp hai thành phần → **biểu mẫu nhập liệu đầy đủ** của đơn vị.

**Tham chiếu:** [LUU_Y_CAU_TRUC_BIEU_MAU_VA_CHI_TIEU.md](../LUU_Y_CAU_TRUC_BIEU_MAU_VA_CHI_TIEU.md), [B7_FORM_DEFINITION.md](B7_FORM_DEFINITION.md), [B8_FORM_SHEET_COLUMN_DATA_BINDING.md](B8_FORM_SHEET_COLUMN_DATA_BINDING.md), [04.form_definition.sql](../script_core/sql/v2/04.form_definition.sql), [05.data_storage.sql](../script_core/sql/v2/05.data_storage.sql).

---

## 1. Phân tích yêu cầu

| Yêu cầu | Mô tả | Bắt buộc |
|--------|--------|----------|
| **R1 – Người khởi tạo** | Cấu trúc biểu mẫu do **System Admin** khởi tạo và quản lý; không để đơn vị/Form Admin tùy tiện tạo/sửa cấu trúc. | ✅ |
| **R2 – Nội dung cấu trúc** | Thông tin biểu mẫu + định nghĩa sheet, cột, hàng, công thức, khóa, format, style, bộ lọc (data binding), ánh xạ (column mapping). | ✅ |
| **R3 – Chỉ tiêu cố định** | Cột/hàng được định nghĩa sẵn; đơn vị chỉ nhập **giá trị** vào ô tương ứng. | ✅ |
| **R4 – Placeholder chỉ tiêu động** | Một hoặc nhiều vị trí giữ chỗ (placeholder) cho **chỉ tiêu do đơn vị tự định nghĩa và nhập** (tên chỉ tiêu + giá trị). | ✅ |
| **R5 – Biểu mẫu đầy đủ** | Biểu mẫu nhập liệu đầy đủ = **phần cố định** + **phần động** (tại placeholder). | ✅ |
| **R6 – Tái sử dụng chỉ tiêu** | Khi xây dựng biểu mẫu Excel, **tái sử dụng** các chỉ tiêu đã có trong **danh mục chỉ tiêu** (chọn từ catalog thay vì định nghĩa lại mỗi lần). Cùng một chỉ tiêu có thể được gắn vào nhiều biểu mẫu. | ✅ |
| **R7 – Chỉ tiêu cố định áp dụng tất cả** | Chỉ tiêu cố định do **chỉ System Admin** nhập và áp dụng cho **tất cả** đơn vị (global). | ✅ |
| **R8 – Chỉ tiêu động theo danh mục, dữ liệu theo đơn vị** | Chỉ tiêu động theo **danh mục** (catalog): định nghĩa chỉ tiêu nằm trong danh mục; **dữ liệu** (giá trị) tương ứng **theo từng đơn vị** (mỗi submission/đơn vị nhập giá trị cho các chỉ tiêu trong danh mục). | ✅ |
| **R9 – Danh mục chỉ tiêu động phát sinh & khởi tạo động** | Các **danh mục chỉ tiêu động có thể phát sinh** (tạo mới, mở rộng theo nhu cầu). Phải có **giải pháp khởi tạo động** cho danh mục chỉ tiêu động: tạo danh mục mới, thêm/sửa chỉ tiêu trong danh mục qua hệ thống (API/UI) mà **không cần thay đổi code** hay deploy. | ✅ |
| **R10 – Phân cấp cha-con nhiều tầng** | **Chỉ tiêu cố định** và **chỉ tiêu động** đều có **phân cấp cha-con nhiều tầng** (một chỉ tiêu có thể có cha, và có nhiều con; cây nhiều cấp). Hiển thị và chọn chỉ tiêu theo cây (tree); quản lý danh mục hỗ trợ kéo thả / chọn cha khi tạo con. | ✅ |
| **R11 – Phân cấp cột/hàng trong biểu mẫu** | Khi cấu hình **cột** hoặc **hàng** cho biểu mẫu cũng có **phân cấp cha-con** (độc lập với phân cấp chỉ tiêu). **Cột:** nếu một cột có con thì **header** của cột đó **merge** số cột = số con, cháu (colspan = tổng cột lá dưới nó). **Hàng:** phân cấp cha-con; với hàng là **placeholder chỉ tiêu động** có cấu hình **độ sâu đệ quy** để lấy chỉ tiêu con, cháu… Khi tạo Excel nhập liệu: **ưu tiên (1)** thứ tự và cha-con trong **cấu hình biểu mẫu**, **(2)** thứ tự và cha-con trong **chỉ tiêu động**. | ✅ |

### 1.1. Phân loại chỉ tiêu (tóm tắt nghiệp vụ)

| Loại | Ai nhập định nghĩa? | Áp dụng / Dữ liệu | Danh mục |
|------|----------------------|-------------------|----------|
| **Chỉ tiêu cố định** | Chỉ **System Admin** | Áp dụng cho **tất cả** đơn vị; mọi đơn vị nhập giá trị vào cùng tập cột đã định nghĩa. | Không (hoặc dùng một danh mục “cố định” cho form). |
| **Chỉ tiêu động theo danh mục** | System Admin định nghĩa **danh mục** và các chỉ tiêu trong danh mục. | **Dữ liệu tương ứng theo đơn vị:** mỗi đơn vị chọn chỉ tiêu từ danh mục và nhập giá trị (lưu theo submission). | **Có.** Danh mục có thể **phát sinh** (tạo mới, bổ sung chỉ tiêu) và phải **khởi tạo động** (CRUD qua API/UI). |

---

## 2. Đánh giá hiện trạng (Gap Analysis)

### 2.1. Đã có

| Thành phần | Hiện trạng | Ghi chú |
|------------|------------|---------|
| **Thông tin biểu mẫu** | BCDT_FormDefinition, API CRUD, FE FormsPage | ✅ |
| **Sheet** | BCDT_FormSheet, API, FE FormConfigPage | ✅ |
| **Cột (chỉ tiêu cố định)** | BCDT_FormColumn, API, FE FormConfigPage | ✅ |
| **Data binding & Column mapping** | BCDT_FormDataBinding, BCDT_FormColumnMapping, API, FE | ✅ |
| **Hàng (schema)** | BCDT_FormRow (RowType: Header, Data, Total, Static), BCDT_FormCell | ⚠️ Có bảng, chưa API/UI |
| **Lưu trữ dữ liệu cố định** | BCDT_ReportDataRow (NumericValue1–10, TextValue1–3, DateValue1–2), ReportPresentation (WorkbookJson) | ✅ |
| **Phân quyền** | JWT + [Authorize]; B2 RBAC có 5 role (SYSTEM_ADMIN, FORM_ADMIN, …) | ⚠️ Chưa ràng buộc form structure cho System Admin |

### 2.2. Chưa có / Cần bổ sung

| Gap | Mô tả | Ưu tiên |
|-----|--------|---------|
| **G1 – Ràng buộc quyền khởi tạo cấu trúc** | Chỉ System Admin (hoặc Form Admin theo chính sách) được tạo/sửa/xóa FormDefinition, FormSheet, FormColumn, DataBinding, ColumnMapping. Hiện mọi user đã đăng nhập đều có thể gọi API. | Cao |
| **G2 – Phân biệt chỉ tiêu cố định vs placeholder** | Trong schema/cấu hình chưa có khái niệm "cột/hàng là cố định" hay "vùng placeholder cho chỉ tiêu động". | Cao |
| **G3 – Định nghĩa vùng placeholder** | Cần mô hình: tại sheet X, vùng (hàng A–B, cột C–D) là placeholder; đơn vị được thêm dòng (Tên chỉ tiêu, Giá trị) trong vùng đó. | Cao |
| **G4 – Lưu trữ chỉ tiêu động** | Chưa có bảng/cột lưu chỉ tiêu động do đơn vị nhập (tên + giá trị) theo submission. | Cao |
| **G5 – API & UI cho placeholder** | Chưa có API CRUD cấu hình placeholder ở form; chưa có API lưu/đọc chỉ tiêu động theo submission; FE chưa có UI đánh dấu placeholder và nhập chỉ tiêu động. | Cao |
| **G6 – FormRow / FormCell** | FormRow, FormCell có trong DB nhưng chưa có API/UI (hàng động, merge, lock, style). Có thể tận dụng FormRow.RowType + IsRepeating cho placeholder. | Trung bình |
| **G7 – Tái sử dụng chỉ tiêu** | Chưa có **danh mục chỉ tiêu** (Indicator catalog): không có bảng master chỉ tiêu dùng chung; FormColumn hiện định nghĩa từng cột riêng lẻ cho từng form, không tham chiếu đến chỉ tiêu dùng chung → không đáp ứng nghiệp vụ "tái sử dụng chỉ tiêu khi xây dựng biểu mẫu". | Cao |
| **G8 – Danh mục chỉ tiêu động phát sinh & khởi tạo động** | Chưa có mô hình **nhiều danh mục** (catalog) chỉ tiêu động; chưa có cơ chế **khởi tạo động** (tạo danh mục mới, thêm chỉ tiêu vào danh mục) qua API/UI mà không deploy code. | Cao |
| **G9 – Phân cấp cha-con nhiều tầng** | Chưa có mô hình **phân cấp** (ParentId) cho chỉ tiêu cố định và chỉ tiêu động; API/FE chưa hỗ trợ trả cây (tree), chọn cha khi tạo con, hiển thị TreeSelect/tree table. | Cao |
| **G10 – Phân cấp cột/hàng trong form** | FormColumn/FormRow chưa có **ParentId** (phân cấp độc lập với chỉ tiêu); chưa có quy tắc **merge header cột** theo số con/cháu; vùng placeholder chưa có cấu hình **độ sâu đệ quy** chỉ tiêu động; Build workbook chưa áp dụng thứ tự ưu tiên (cấu hình → chỉ tiêu động). | Cao |

---

## 3. Giải pháp tổng thể

### 3.1. Kiến trúc luồng

```
┌─────────────────────────────────────────────────────────────────────────────┐
│  SYSTEM ADMIN                                                                │
│  • Quản lý Danh mục chỉ tiêu (Indicator catalog) – tái sử dụng               │
│  • Tạo/sửa Form Definition, Sheet, Column (chọn từ catalog hoặc tạo mới)    │
│  • Định nghĩa vùng Placeholder (sheet + range)                                 │
│  • Cấu hình binding, mapping, format, lock                                   │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  CẤU TRÚC BIỂU MẪU (Form + Sheet + Column + Placeholder config)              │
│  • Danh mục chỉ tiêu: BCDT_Indicator (master) ← FormColumn.IndicatorId (tái sử dụng) │
│  • Phần cố định: FormColumn (có thể tham chiếu Indicator) + DataBinding + Mapping │
│  • Phần placeholder: FormDynamicRegion                                       │
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  ĐƠN VỊ (Data Entry)                                                         │
│  • Nhập giá trị vào ô chỉ tiêu cố định (sync → ReportDataRow)               │
│  • Thêm/sửa/xóa chỉ tiêu động trong vùng placeholder (→ ReportDynamicIndicator)│
└─────────────────────────────────────────────────────────────────────────────┘
                                        │
                                        ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│  LƯU TRỮ                                                                     │
│  • ReportDataRow + ReportPresentation (cố định + workbook đầy đủ)             │
│  • ReportDynamicIndicator (chỉ tiêu động theo submission)                    │
└─────────────────────────────────────────────────────────────────────────────┘
```

### 3.2. Thành phần giải pháp (tóm tắt)

| # | Thành phần | Giải pháp |
|---|------------|-----------|
| 1 | **Authorization** | Ràng buộc POST/PUT/DELETE form structure (forms, sheets, columns, data-binding, column-mapping) cho role SYSTEM_ADMIN (và có thể FORM_ADMIN). GET có thể cho role đọc báo cáo. |
| 2 | **Phân biệt Fixed / Placeholder** | Thêm cột `IndicatorKind` ('Fixed', 'Placeholder') vào BCDT_FormColumn; hoặc bảng mới BCDT_FormDynamicRegion (FormSheetId, ExcelRowStart, ExcelRowEnd, ExcelColStart, ExcelColEnd, MaxRows, …). Ưu tiên: **bảng FormDynamicRegion** để mỗi sheet có thể có một vùng placeholder (block hàng), không phụ thuộc từng cột. |
| 3 | **Lưu trữ chỉ tiêu động** | Bảng mới **BCDT_ReportDynamicIndicator** (SubmissionId, SheetIndex, RowOrder, IndicatorName, IndicatorValue, DataType). Index (SubmissionId, SheetIndex). |
| 4 | **API** | (a) API cấu hình: CRUD FormDynamicRegion theo form/sheet. (b) API dữ liệu: GET/PUT /api/v1/submissions/{id}/dynamic-indicators (trả về/cập nhật danh sách chỉ tiêu động). |
| 5 | **Build workbook & Sync** | Khi build workbook từ submission: merge dữ liệu cố định (ReportDataRow) + chỉ tiêu động (ReportDynamicIndicator) vào vùng placeholder trong sheet. Khi sync từ Excel về: đọc vùng placeholder trong WorkbookJson → ghi ReportDynamicIndicator. |
| 6 | **FE** | FormConfigPage: chỉ hiển thị/sửa form structure khi user có role System Admin (hoặc Form Admin); thêm màn/block cấu hình "Vùng chỉ tiêu động" (Dynamic Region). SubmissionDataEntryPage: trong vùng placeholder, hiển thị bảng/bảng nhập (Tên chỉ tiêu, Giá trị), lưu qua API dynamic-indicators. |
| 7 | **Tái sử dụng chỉ tiêu** | **Danh mục chỉ tiêu (Indicator catalog):** Bảng BCDT_Indicator (master); FormColumn.IndicatorId (nullable FK) để gắn cột với chỉ tiêu dùng chung. Khi xây dựng biểu mẫu: "Thêm cột từ danh mục" → chọn Indicator → tạo FormColumn + copy metadata (có thể override tại form). API CRUD /api/v1/indicators (System Admin). | ✅ |
| 8 | **Chỉ tiêu cố định (global)** | Chỉ tiêu cố định: System Admin tạo FormColumn (hoặc Indicator trong danh mục “cố định”); áp dụng cho tất cả đơn vị. Ràng buộc quyền (P1) đảm bảo chỉ System Admin sửa cấu trúc. | ✅ |
| 9 | **Chỉ tiêu động theo danh mục, dữ liệu theo đơn vị** | Vùng placeholder gắn với **một danh mục** (FormDynamicRegion.IndicatorCatalogId). Đơn vị tại vùng đó **chọn chỉ tiêu từ danh mục** (dropdown) và **nhập giá trị**; lưu ReportDynamicIndicator(SubmissionId, **IndicatorId**, IndicatorValue) → dữ liệu theo đơn vị (submission). | ✅ |
| 10 | **Danh mục phát sinh & khởi tạo động** | **BCDT_IndicatorCatalog** (nhiều danh mục); BCDT_Indicator.IndicatorCatalogId. API CRUD **/api/v1/indicator-catalogs** và CRUD **/api/v1/indicators** (filter by catalogId). System Admin qua UI tạo danh mục mới, thêm/sửa chỉ tiêu → **khởi tạo động**, không cần deploy. | ✅ |
| 11 | **Phân cấp cha-con nhiều tầng (R10)** | **BCDT_Indicator.ParentId** (self-FK): chỉ tiêu **cố định** và **động** đều có cây nhiều tầng. API GET indicators hỗ trợ **tree=true**; POST/PUT nhận **parentId**. FE: TreeSelect / tree table khi chọn chỉ tiêu (FormConfig, SubmissionDataEntry); trang quản lý danh mục hỗ trợ "Thêm chỉ tiêu con", hiển thị cây. | ✅ |
| 12 | **Phân cấp cột/hàng trong biểu mẫu (R11)** | **FormColumn.ParentId**, **FormRow.ParentId** (self-FK): cấu hình cột/hàng theo cây, **độc lập** với cây chỉ tiêu. **Cột:** khi build Excel, header cột cha **merge** (colspan) = số cột con + cháu (tổng lá). **FormDynamicRegion.IndicatorExpandDepth:** độ sâu đệ quy lấy chỉ tiêu con/cháu khi sinh hàng placeholder. **Build workbook:** ưu tiên (1) thứ tự + cha-con cấu hình, (2) thứ tự + cha-con chỉ tiêu động (theo depth). | ✅ |

---

## 4. Thiết kế chi tiết

### 4.1. Authorization (G1)

- **Backend:** Thêm policy (vd `FormStructureAdmin`) yêu cầu role `SYSTEM_ADMIN` hoặc `FORM_ADMIN`. Áp dụng cho:
  - FormDefinitionsController: POST, PUT, DELETE
  - FormSheetsController: POST, PUT, DELETE
  - FormColumnsController: POST, PUT, DELETE
  - FormColumnDataBindingController: POST, PUT, DELETE
  - FormColumnMappingController: POST, PUT, DELETE
- **GET** (form, sheets, columns, binding, mapping): giữ [Authorize] (đã đăng nhập) nếu mọi role được xem cấu trúc; hoặc giới hạn theo permission tùy nghiệp vụ.
- **Frontend:** Ẩn menu "Biểu mẫu" / nút "Cấu hình" cho user không có role System Admin / Form Admin (kiểm tra role từ /me hoặc claim).

### 4.2. Mô hình dữ liệu: Vùng placeholder (G2, G3)

**Phương án A – Bảng FormDynamicRegion (đề xuất)**

- Một sheet có tối đa một vùng "chỉ tiêu động" (một block liên tục).
- Bảng mới: **BCDT_FormDynamicRegion**

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| FormSheetId | INT NOT NULL | FK → BCDT_FormSheet |
| ExcelRowStart | INT NOT NULL | Hàng bắt đầu vùng placeholder (1-based) |
| ExcelRowEnd | INT NULL | Hàng kết thúc (NULL = không giới hạn, hoặc dùng MaxRows) |
| ExcelColName | NVARCHAR(10) NOT NULL | Cột "Tên chỉ tiêu" (vd 'A', 'B') |
| ExcelColValue | NVARCHAR(10) NOT NULL | Cột "Giá trị" |
| MaxRows | INT NOT NULL DEFAULT 100 | Số dòng tối đa đơn vị được thêm |
| **IndicatorExpandDepth** | **INT NOT NULL DEFAULT 1** | **Độ sâu đệ quy** khi vùng là placeholder chỉ tiêu động (gắn catalog): 1 = chỉ gốc, 2 = gốc + con, 3 = gốc + con + cháu; 0 = không giới hạn. Dùng khi build hàng/sinh dòng theo cây chỉ tiêu. |
| DisplayOrder | INT | Thứ tự (nếu nhiều vùng sau này) |
| CreatedAt, CreatedBy | | Audit |

- **Lưu trữ chỉ tiêu động:** Bảng **BCDT_ReportDynamicIndicator**

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | BIGINT IDENTITY | PK |
| SubmissionId | BIGINT NOT NULL | FK → BCDT_ReportSubmission |
| FormDynamicRegionId | INT NOT NULL | FK → BCDT_FormDynamicRegion (để biết sheet + vùng) |
| RowOrder | INT NOT NULL | Thứ tự dòng trong vùng (0-based) |
| IndicatorName | NVARCHAR(500) NOT NULL | Tên chỉ tiêu do đơn vị nhập |
| IndicatorValue | NVARCHAR(MAX) NULL | Giá trị (text; số/ngày lưu dạng string hoặc thêm cột NumericValue/DateValue) |
| DataType | NVARCHAR(20) NULL | Text, Number, Date (optional) |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | | Audit |

- Unique: (SubmissionId, FormDynamicRegionId, RowOrder). Index: (SubmissionId, FormDynamicRegionId).

**Phương án B – Dùng FormColumn.IndicatorKind**

- Thêm cột **IndicatorKind** ('Fixed', 'Placeholder') vào BCDT_FormColumn. Hai cột đặc biệt: một "Tên chỉ tiêu", một "Giá trị", cả hai có IndicatorKind = 'Placeholder'; cùng một "region" (vd cùng FormRowId hoặc cùng một group). Đơn vị thêm hàng trong vùng đó.
- Ưu: không thêm bảng FormDynamicRegion. Nhược: logic vùng placeholder nằm rải trên cột/hàng, khó mô tả "một block" rõ ràng.

**Đề xuất:** Dùng **Phương án A** (FormDynamicRegion + ReportDynamicIndicator) để tách bạch cấu hình vùng và dữ liệu, dễ mở rộng (nhiều vùng, validation, MaxRows).

### 4.3. API

| Method | Route | Mô tả | Quyền |
|--------|--------|--------|--------|
| GET / POST | /api/v1/forms/{formId}/sheets/{sheetId}/dynamic-regions | Danh sách / Tạo vùng placeholder | GET: Authorize; POST: SystemAdmin |
| GET / PUT / DELETE | .../dynamic-regions/{regionId} | Chi tiết / Cập nhật / Xóa | SystemAdmin |
| GET | /api/v1/submissions/{id}/dynamic-indicators | Lấy danh sách chỉ tiêu động của submission | Authorize (RLS) |
| PUT | /api/v1/submissions/{id}/dynamic-indicators | Ghi đè danh sách chỉ tiêu động (mảng { regionId, rowOrder, indicatorName, indicatorValue }) | Authorize (RLS) |

- Khi PUT dynamic-indicators: validate RowOrder, MaxRows theo FormDynamicRegion; merge vào ReportDynamicIndicator (xóa cũ trong region, insert mới).

### 4.4. Luồng dữ liệu (Build workbook & Sync)

- **Build workbook (GET workbook-data / export Excel):**
  - **Thứ tự ưu tiên (R11):** (1) Áp dụng **thứ tự và phân cấp cha-con trong cấu hình biểu mẫu** (FormColumn, FormRow) trước; (2) sau đó áp dụng **thứ tự và phân cấp chỉ tiêu động** (theo FormDynamicRegion.IndicatorExpandDepth và cây BCDT_Indicator).
  - **Cột:** Duyệt cột theo cây FormColumn (DisplayOrder, ParentId); với mỗi cột có con: header merge (colspan) = số cột lá dưới nó; cột lá mỗi cột 1 ô.
  - **Hàng:** Duyệt hàng theo cây FormRow; với hàng thuộc vùng placeholder: sinh dòng theo cây chỉ tiêu (catalog) với độ sâu **IndicatorExpandDepth** (gốc → con → cháu…), rồi điền ReportDynamicIndicator theo thứ tự đó.
  - Dữ liệu cố định: như hiện tại (ReportDataRow + FormColumnMapping).
  - Vùng placeholder: đọc ReportDynamicIndicator theo SubmissionId + FormDynamicRegionId; điền theo thứ tự (đã sắp theo cấu hình + cây chỉ tiêu).
- **Sync từ presentation (save Excel):**
  - Phần cố định: như hiện tại (SyncFromPresentationService → ReportDataRow).
  - Vùng placeholder: đọc ô trong WorkbookJson từ (ExcelRowStart..ExcelRowEnd, ExcelColName, ExcelColValue); so sánh với FormDynamicRegion; ghi vào ReportDynamicIndicator (insert/update/delete theo RowOrder).

### 4.5. Hiệu năng

| Khía cạnh | Giải pháp |
|-----------|-----------|
| **Đọc cấu trúc form** | Cache form definition (sheet + column + dynamic regions) theo FormId, TTL ngắn (vd 1–5 phút), khi có thay đổi cấu trúc invalidation. |
| **Đọc chỉ tiêu động** | Index (SubmissionId, FormDynamicRegionId); một submission thường vài chục đến vài trăm dòng chỉ tiêu động → không cần phân trang. |
| **Ghi chỉ tiêu động** | PUT một lần (batch): DELETE theo (SubmissionId, FormDynamicRegionId) + INSERT nhiều dòng; trong transaction. |
| **Build workbook** | Chỉ query ReportDynamicIndicator theo SubmissionId; merge trong memory (số dòng nhỏ). |
| **RLS** | ReportDynamicIndicator không cần cột OrganizationId nếu luôn truy vấn qua SubmissionId (đã có RLS trên ReportSubmission). |

### 4.6. Tái sử dụng chỉ tiêu – Danh mục chỉ tiêu (Indicator catalog)

Nghiệp vụ yêu cầu **tái sử dụng các chỉ tiêu** khi xây dựng biểu mẫu Excel: định nghĩa chỉ tiêu một lần trong **danh mục chỉ tiêu**, sau đó khi tạo/sửa từng biểu mẫu, System Admin **chọn từ danh mục** và gắn vào sheet (cùng chỉ tiêu có thể xuất hiện ở nhiều form).

#### 4.6.1. Bảng master: BCDT_Indicator

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| **ParentId** | **INT NULL** | **FK → BCDT_Indicator (self). Phân cấp cha-con nhiều tầng: NULL = gốc; có giá trị = chỉ tiêu con (cha cùng catalog hoặc cùng nhóm “cố định”).** |
| Code | NVARCHAR(50) NOT NULL | Mã chỉ tiêu (unique trong cùng catalog/scope), vd CT_001, DOANH_THU |
| Name | NVARCHAR(200) NOT NULL | Tên hiển thị |
| Description | NVARCHAR(500) NULL | Mô tả |
| DataType | NVARCHAR(20) NOT NULL | Text, Number, Date, Formula, Reference, Boolean (khớp FormColumn) |
| Unit | NVARCHAR(50) NULL | Đơn vị tính (vd %, triệu đồng) |
| FormulaTemplate | NVARCHAR(1000) NULL | Công thức mẫu (nếu có) |
| ValidationRule | NVARCHAR(500) NULL | Rule validation dùng chung |
| DefaultValue | NVARCHAR(500) NULL | Giá trị mặc định |
| DisplayOrder | INT NOT NULL DEFAULT 0 | Thứ tự (trong cùng cấp hoặc toàn danh mục) |
| IsActive | BIT NOT NULL DEFAULT 1 | Ẩn/hiện trong catalog |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | | Audit |

- Constraint: UQ (IndicatorCatalogId, Code) – mã unique trong từng catalog; với chỉ tiêu “cố định” (IndicatorCatalogId NULL) dùng UQ_Indicator_Code trên Code. Index: (ParentId, DisplayOrder), (IndicatorCatalogId, IsActive), Code.
- **Phân cấp:** Cùng bảng dùng cho cả chỉ tiêu cố định và chỉ tiêu động; **ParentId** tạo cây nhiều tầng. Khi IndicatorCatalogId NULL (chỉ tiêu cố định): cha-con trong nhóm “cố định”. Khi thuộc catalog (chỉ tiêu động): ParentId phải NULL hoặc trỏ tới Indicator cùng IndicatorCatalogId.

#### 4.6.2. FormColumn tham chiếu Indicator

- Thêm cột **IndicatorId INT NULL** (FK → BCDT_Indicator) vào **BCDT_FormColumn**.
- **Khi IndicatorId = NULL:** cột được định nghĩa "nội bộ" form (như hiện tại).
- **Khi IndicatorId có giá trị:** cột **tái sử dụng** chỉ tiêu từ danh mục; khi tạo FormColumn từ catalog, copy Code, Name, DataType, Unit, FormulaTemplate, ValidationRule, DefaultValue từ Indicator vào FormColumn (có thể override tại form: ExcelColumn, DisplayOrder, Binding, Mapping vẫn cấu hình theo từng form).
- Lợi ích: thống nhất tên/kiểu/đơn vị giữa các biểu mẫu; cập nhật master (vd đổi tên chỉ tiêu) có thể áp dụng cho form mới (form cũ giữ snapshot trong FormColumn nếu không sync ngược).

#### 4.6.3. API

| Method | Route | Mô tả | Quyền |
|--------|--------|--------|--------|
| GET | /api/v1/indicators | Danh sách chỉ tiêu (filter, sort, paging) | Authorize |
| GET | /api/v1/indicators/{id} | Chi tiết một chỉ tiêu | Authorize |
| POST | /api/v1/indicators | Tạo chỉ tiêu mới | SystemAdmin |
| PUT | /api/v1/indicators/{id} | Cập nhật chỉ tiêu | SystemAdmin |
| DELETE | /api/v1/indicators/{id} | Soft delete / ẩn chỉ tiêu | SystemAdmin |

- Khi **thêm cột vào sheet:** API POST /api/v1/forms/{formId}/sheets/{sheetId}/columns nhận thêm body **indicatorId** (optional). Nếu gửi indicatorId: service lấy Indicator, tạo FormColumn với IndicatorId + copy Code, Name, DataType, Unit, FormulaTemplate, ValidationRule, DefaultValue; client có thể override ExcelColumn, DisplayOrder. Nếu không gửi: tạo cột như hiện tại (IndicatorId = NULL).

#### 4.6.4. FE (FormConfigPage)

- Khi "Thêm cột": có hai chế độ **(1) Tạo mới** (form nhập Code, Name, DataType, … như hiện tại) và **(2) Chọn từ danh mục chỉ tiêu** (dropdown hoặc modal danh sách Indicator, tìm theo Code/Name; chọn một chỉ tiêu → gọi POST columns với indicatorId → cột được tạo với metadata từ catalog, user chỉ cần chọn vị trí cột Excel và cấu hình binding/mapping nếu cần).
- Menu/quản lý **Danh mục chỉ tiêu** (trang IndicatorsPage hoặc mục trong Cấu hình): CRUD Indicator (chỉ System Admin); danh sách có filter, sort.

#### 4.6.5. Hiệu năng & rủi ro

- **Đọc catalog:** GET indicators có paging; cache danh sách active indicators (TTL ngắn) cho dropdown khi mở FormConfig.
- **Rủi ro:** Sửa Indicator (vd đổi tên) không tự cập nhật FormColumn đã gắn → giữ snapshot tại FormColumn; nếu nghiệp vụ cần "cập nhật tất cả form khi đổi tên chỉ tiêu" thì cần thêm luồng sync (update FormColumn.ColumnName where IndicatorId = @id).

#### 4.6.6. Phân cấp cha-con nhiều tầng (R10)

- **Mô hình:** BCDT_Indicator có **ParentId** (self-reference). **Chỉ tiêu cố định** (IndicatorCatalogId NULL) và **chỉ tiêu động** (thuộc catalog) đều hỗ trợ cây nhiều tầng.
- **Ràng buộc:** (1) ParentId = NULL → nút gốc. (2) Khi có catalog: ParentId phải NULL hoặc trỏ tới Indicator cùng **IndicatorCatalogId**. (3) Tránh vòng (không cho ParentId trỏ tới chính nó hoặc con cháu); khi đổi cha cần kiểm tra.
- **API:** GET /api/v1/indicators hỗ trợ query **tree=true** (hoặc **flat=false**): trả danh sách dạng cây (children lồng). Query **parentId=** (optional): lấy chỉ tiêu gốc khi null, lấy con một nút khi có. Khi tạo/sửa: POST/PUT body có **parentId** (nullable).
- **FE – FormConfig "Thêm cột từ danh mục":** Hiển thị chỉ tiêu dạng **cây** (TreeSelect hoặc tree table): expand/collapse theo ParentId; chọn một nút lá hoặc nút cha (tùy nghiệp vụ: chỉ chọn lá hay cho phép chọn cả nhóm).
- **FE – Trang quản lý Danh mục chỉ tiêu (cố định / theo catalog):** Danh sách chỉ tiêu dạng **tree** (bảng có cột cha, indent theo cấp, hoặc TreeSelect khi "Thêm chỉ tiêu con"); khi tạo mới có chọn **Chỉ tiêu cha** (dropdown cây hoặc parentId).

### 4.7. Chỉ tiêu động theo danh mục – Nhiều danh mục & Khởi tạo động

Nghiệp vụ: **(1)** Chỉ tiêu động theo **danh mục**, **(2)** dữ liệu tương ứng **theo đơn vị**; **(3)** các danh mục chỉ tiêu động **có thể phát sinh**; **(4)** phải **khởi tạo động** danh mục (tạo danh mục mới, thêm chỉ tiêu) qua hệ thống, không cần deploy code.

#### 4.7.1. Bảng BCDT_IndicatorCatalog (danh mục chỉ tiêu động)

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| Code | NVARCHAR(50) NOT NULL | Mã danh mục (unique), vd DM_NGANH, DM_BOSUNG |
| Name | NVARCHAR(200) NOT NULL | Tên hiển thị danh mục |
| Description | NVARCHAR(500) NULL | Mô tả |
| Scope | NVARCHAR(20) NOT NULL DEFAULT 'Global' | Global, PerOrganization (tùy mở rộng) |
| DisplayOrder | INT NOT NULL DEFAULT 0 | Thứ tự hiển thị |
| IsActive | BIT NOT NULL DEFAULT 1 | Ẩn/hiện |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | | Audit |

- **Khởi tạo động:** System Admin tạo danh mục mới bất kỳ lúc nào qua API POST /api/v1/indicator-catalogs (và PUT/DELETE). Không cần script SQL hay deploy.

#### 4.7.2. BCDT_Indicator thuộc danh mục

- Thêm cột **IndicatorCatalogId INT NULL** (FK → BCDT_IndicatorCatalog) vào **BCDT_Indicator**.
  - **NULL:** chỉ tiêu “dùng chung” không gắn danh mục (dùng cho chỉ tiêu cố định tái sử dụng hoặc danh mục mặc định).
  - **Có giá trị:** chỉ tiêu thuộc **một danh mục chỉ tiêu động**; danh mục có thể phát sinh (tạo mới catalog rồi thêm indicator vào catalog).
- Unique: (IndicatorCatalogId, Code) – trong cùng một catalog mã chỉ tiêu không trùng.
- **Phân cấp trong danh mục:** Chỉ tiêu động trong cùng catalog cũng dùng **ParentId** (4.6.1, 4.6.6): ParentId NULL = gốc trong catalog; ParentId = Id của chỉ tiêu cùng catalog = con. Cây nhiều tầng áp dụng đồng nhất cho chỉ tiêu cố định và chỉ tiêu động.

#### 4.7.3. FormDynamicRegion gắn với danh mục

- Thêm cột **IndicatorCatalogId INT NULL** (FK → BCDT_IndicatorCatalog) vào **BCDT_FormDynamicRegion**.
- **Khi có giá trị:** vùng placeholder này dùng **chỉ tiêu động theo danh mục**: đơn vị khi nhập chọn chỉ tiêu từ danh mục đó và nhập giá trị (dữ liệu theo đơn vị).
- **Khi NULL:** vùng placeholder “tự do” (đơn vị nhập tên + giá trị tùy ý, như thiết kế cũ).

#### 4.7.4. ReportDynamicIndicator – dữ liệu theo đơn vị, tham chiếu chỉ tiêu trong danh mục

- Thêm cột **IndicatorId INT NULL** (FK → BCDT_Indicator) vào **BCDT_ReportDynamicIndicator**.
- **Khi FormDynamicRegion có IndicatorCatalogId:** đơn vị chọn chỉ tiêu từ catalog → lưu **IndicatorId** + **IndicatorValue**; **IndicatorName** có thể copy từ Indicator.Name để hiển thị (redundant) hoặc lấy khi đọc.
- **Khi vùng placeholder không gắn catalog:** giữ lưu IndicatorName (text) + IndicatorValue như hiện tại; IndicatorId = NULL.
- Dữ liệu luôn theo đơn vị vì bảng gắn **SubmissionId** (mỗi submission = một đơn vị + form + kỳ).

#### 4.7.5. API khởi tạo động danh mục chỉ tiêu động

| Method | Route | Mô tả | Quyền |
|--------|--------|--------|--------|
| GET | /api/v1/indicator-catalogs | Danh sách danh mục (filter, sort) | Authorize |
| GET | /api/v1/indicator-catalogs/{id} | Chi tiết + danh sách chỉ tiêu trong danh mục | Authorize |
| POST | /api/v1/indicator-catalogs | **Tạo danh mục mới** (khởi tạo động) | SystemAdmin |
| PUT | /api/v1/indicator-catalogs/{id} | Cập nhật danh mục | SystemAdmin |
| DELETE | /api/v1/indicator-catalogs/{id} | Soft delete / ẩn danh mục | SystemAdmin |
| GET | /api/v1/indicators | Danh sách chỉ tiêu (filter **catalogId**, sort, paging) | Authorize |
| POST | /api/v1/indicators | Tạo chỉ tiêu (body có **indicatorCatalogId**); **thêm chỉ tiêu vào danh mục** → khởi tạo động | SystemAdmin |
| PUT | /api/v1/indicators/{id} | Cập nhật chỉ tiêu | SystemAdmin |
| DELETE | /api/v1/indicators/{id} | Soft delete / ẩn chỉ tiêu | SystemAdmin |

- **Khởi tạo động:** Tạo danh mục mới (POST indicator-catalogs) → tạo/sửa chỉ tiêu trong danh mục (POST/PUT indicators với indicatorCatalogId). Toàn bộ qua API/UI, không deploy.

#### 4.7.6. FE – Khởi tạo động danh mục chỉ tiêu động

- **Trang Danh mục chỉ tiêu động (Indicator Catalogs):** Danh sách danh mục (card hoặc bảng); nút **Tạo danh mục mới** → modal/form (Code, Name, Description) → POST indicator-catalogs. Vào từng danh mục → **danh sách chỉ tiêu dạng cây** (phân cấp cha-con, expand/collapse); nút **Thêm chỉ tiêu** / **Thêm chỉ tiêu con** → POST indicators (indicatorCatalogId, **parentId** tùy chọn). Chỉ System Admin.
- **FormConfig – Vùng chỉ tiêu động:** Khi cấu hình FormDynamicRegion, chọn **Danh mục** (dropdown indicator-catalogs) → gắn IndicatorCatalogId. Đơn vị sau này tại vùng này chọn chỉ tiêu từ danh mục đã chọn (dạng cây).
- **SubmissionDataEntryPage – Nhập chỉ tiêu động theo danh mục:** Nếu vùng gắn catalog: **TreeSelect** (hoặc dropdown cây) chỉ tiêu từ GET /api/v1/indicators?catalogId=…&**tree=true**; đơn vị chọn Indicator (có thể chỉ chọn lá hoặc cả nhóm tùy nghiệp vụ) + nhập giá trị → PUT dynamic-indicators với mảng { indicatorId, value }. Dữ liệu lưu theo submission (đơn vị).

#### 4.7.7. Tóm tắt luồng

1. **Chỉ tiêu cố định (áp dụng tất cả):** System Admin tạo FormColumn (có thể IndicatorId từ danh mục “cố định” hoặc không). Chỉ System Admin sửa; áp dụng cho mọi đơn vị.
2. **Chỉ tiêu động theo danh mục (dữ liệu theo đơn vị):** System Admin tạo **IndicatorCatalog** (khởi tạo động), thêm **Indicator** vào catalog. FormDynamicRegion gắn **IndicatorCatalogId**. Đơn vị tại vùng placeholder chọn chỉ tiêu từ catalog, nhập giá trị → ReportDynamicIndicator(SubmissionId, IndicatorId, IndicatorValue).
3. **Danh mục phát sinh & khởi tạo động:** Danh mục mới và chỉ tiêu mới được tạo/sửa hoàn toàn qua API/UI (CRUD indicator-catalogs, CRUD indicators), không cần thay đổi code hay deploy.

### 4.8. Phân cấp cột và hàng trong biểu mẫu (R11)

Cấu hình **cột** và **hàng** của biểu mẫu có **phân cấp cha-con** riêng, **độc lập** với phân cấp chỉ tiêu (BCDT_Indicator). Khi tạo Excel nhập liệu: ưu tiên thứ tự và cha-con trong cấu hình, sau đó thứ tự và cha-con trong chỉ tiêu động.

#### 4.8.1. FormColumn – phân cấp và merge header

- Thêm cột **ParentId INT NULL** (FK → BCDT_FormColumn, self) vào **BCDT_FormColumn**.
  - **NULL:** cột gốc (cấp 1). **Có giá trị:** cột con (cùng FormSheetId; cha phải cùng sheet).
  - Ràng buộc: tránh vòng (ParentId ≠ Id; khi đổi cha kiểm tra không tạo chu trình).
- **Merge header khi build Excel:** Với mỗi cột **có con** (có ít nhất một FormColumn.ParentId = Id): ô header của cột cha **merge** (colspan) = **số cột lá** dưới nó (đếm tất cả con, cháu,… đến lá). Cột **lá** (không có con) = 1 ô, không merge.
- **Thứ tự:** Sắp xếp cột theo cây (pre-order hoặc theo DisplayOrder trong từng cấp): cha → con → cháu. API GET columns hỗ trợ **tree=true** để trả cây; FE FormConfig hiển thị cột dạng cây, hỗ trợ "Thêm cột con", kéo thả thứ tự.

#### 4.8.2. FormRow – phân cấp

- Thêm cột **ParentId INT NULL** (FK → BCDT_FormRow, self) vào **BCDT_FormRow**.
  - **NULL:** hàng gốc. **Có giá trị:** hàng con (cùng FormSheetId). Tránh vòng.
- **Liên kết với vùng placeholder:** FormRow có thể gắn với FormDynamicRegion (vd FormRow.FormDynamicRegionId INT NULL, FK → BCDT_FormDynamicRegion). Khi hàng thuộc vùng placeholder (có FormDynamicRegionId), áp dụng cấu hình **độ sâu đệ quy** của vùng đó (xem 4.8.3).
- **Thứ tự:** Sắp xếp hàng theo cây (DisplayOrder, ParentId). API GET rows hỗ trợ **tree=true**.

#### 4.8.3. FormDynamicRegion – độ sâu đệ quy chỉ tiêu động

- Cột **IndicatorExpandDepth** (đã thêm trong 4.2): khi vùng placeholder gắn **IndicatorCatalogId**, giá trị này quy định **độ sâu** lấy cây chỉ tiêu khi sinh hàng/dòng cho đơn vị:
  - **1:** chỉ chỉ tiêu gốc (ParentId NULL trong catalog).
  - **2:** gốc + con (1 cấp).
  - **3:** gốc + con + cháu (2 cấp).
  - **0** (hoặc giá trị lớn): không giới hạn, lấy toàn bộ cây.
- Khi **build workbook** hoặc **hiển thị danh sách dòng nhập** tại vùng placeholder: lấy danh sách chỉ tiêu từ catalog theo cây (ParentId, DisplayOrder), cắt đến độ sâu **IndicatorExpandDepth**, rồi điền/sinh dòng theo thứ tự đó (ưu tiên sau cấu hình hàng).

#### 4.8.4. Thứ tự ưu tiên khi tạo Excel nhập liệu

1. **Cột:** Thứ tự và cha-con **trong cấu hình biểu mẫu** (FormColumn tree). Header merge theo 4.8.1.
2. **Hàng:** Thứ tự và cha-con **trong cấu hình biểu mẫu** (FormRow tree) trước.
3. **Trong vùng placeholder (hàng chỉ tiêu động):** Thứ tự và cha-con **trong chỉ tiêu động** (cây BCDT_Indicator theo catalog), với độ sâu **IndicatorExpandDepth**; sau đó điền ReportDynamicIndicator theo thứ tự này.

API GET columns/rows có tham số **tree=true**; POST/PUT column/row nhận **parentId**. FE FormConfig: cấu hình cột/hàng dạng cây, chọn "Thêm cột con" / "Thêm hàng con"; với FormDynamicRegion có thêm field **Độ sâu đệ quy** (IndicatorExpandDepth).

---

## 5. Kế hoạch triển khai gợi ý

| Phase | Nội dung | Ước lượng |
|-------|----------|-----------|
| **P1** | Authorization: policy FormStructureAdmin, áp dụng lên Form* controllers; FE ẩn Form/Cấu hình theo role | 0.5–1 ngày |
| **P1b** | **Tái sử dụng + Danh mục chỉ tiêu động + Phân cấp:** DB thêm BCDT_IndicatorCatalog, BCDT_Indicator (IndicatorCatalogId, **ParentId**), FormColumn.IndicatorId; FormDynamicRegion.IndicatorCatalogId; ReportDynamicIndicator.IndicatorId. API CRUD indicator-catalogs + indicators (filter catalogId, **tree=true**, **parentId**); FE Danh mục chỉ tiêu (catalogs + **cây chỉ tiêu**, Thêm chỉ tiêu con), FormConfig "Thêm cột từ danh mục" (**TreeSelect**); SubmissionDataEntry **TreeSelect** chỉ tiêu từ catalog, lưu theo đơn vị. **Khởi tạo động** + **phân cấp cha-con nhiều tầng** cho cả chỉ tiêu cố định và chỉ tiêu động. | 2.5–3 ngày |
| **P2** | DB: script thêm BCDT_FormDynamicRegion (có **IndicatorExpandDepth**), BCDT_ReportDynamicIndicator; migration hoặc script SQL | 0.5 ngày |
| **P2a** | **Phân cấp cột/hàng (R11):** DB thêm FormColumn.ParentId, FormRow.ParentId (self-FK); FormRow.FormDynamicRegionId (nullable, FK FormDynamicRegion). API GET columns/rows **tree=true**, POST/PUT parentId; FormDynamicRegion CRUD có IndicatorExpandDepth. FE FormConfig: cấu hình cột/hàng dạng cây, merge header (colspan), cấu hình độ sâu đệ quy cho vùng placeholder. | 1–1.5 ngày |
| **P3** | BE: Entity, Repository/Service, API CRUD FormDynamicRegion; API GET/PUT submissions/{id}/dynamic-indicators | 1–2 ngày |
| **P4** | BE: Tích hợp Build workbook (thứ tự ưu tiên cấu hình → chỉ tiêu động; merge header cột; hàng placeholder theo IndicatorExpandDepth); Sync từ presentation → ReportDynamicIndicator | 1–1.5 ngày |
| **P5** | FE: FormConfigPage – block cấu hình "Vùng chỉ tiêu động" (chỉ khi role phù hợp); gọi API dynamic-regions | 1 ngày |
| **P6** | FE: SubmissionDataEntryPage – hiển thị/sửa chỉ tiêu động trong vùng placeholder (bảng + gọi PUT dynamic-indicators); load khi mở submission | 1 ngày |
| **P7** | Test E2E, kiểm tra hiệu năng, tài liệu RUNBOOK / B8 | 0.5–1 ngày |

**Tổng ước lượng:** 8–12 ngày (bao gồm P1b, P2a phân cấp cột/hàng + merge header + độ sâu đệ quy; tùy chi tiết FormRow/FormCell).

---

## 6. Rủi ro và giảm thiểu

| Rủi ro | Giảm thiểu |
|--------|------------|
| Thay đổi schema ảnh hưởng migration | Dùng script SQL tách, chạy trên môi trường dev/staging trước; backup. |
| Performance khi submission nhiều chỉ tiêu động | Giới hạn MaxRows (vd 100–200); index đúng; batch insert. |
| Đồng bộ Excel ↔ ReportDynamicIndicator lệch | Quy ước rõ: vùng placeholder chỉ chỉnh trên web hoặc chỉ trong Excel; hoặc sync hai chiều với rule ưu tiên "last write wins". |

---

## 7. Tài liệu tham chiếu

- [LUU_Y_CAU_TRUC_BIEU_MAU_VA_CHI_TIEU.md](../LUU_Y_CAU_TRUC_BIEU_MAU_VA_CHI_TIEU.md) – Lưu ý nghiệp vụ
- [B7_FORM_DEFINITION.md](B7_FORM_DEFINITION.md), [B8_FORM_SHEET_COLUMN_DATA_BINDING.md](B8_FORM_SHEET_COLUMN_DATA_BINDING.md) – Form, Sheet, Column, Binding, Mapping
- [04.form_definition.sql](../script_core/sql/v2/04.form_definition.sql), [05.data_storage.sql](../script_core/sql/v2/05.data_storage.sql) – Schema
- [B2_RBAC.md](B2_RBAC.md) – Role, policy

---

## 8. Tổng hợp yêu cầu và đối chiếu giải pháp (kiểm tra đủ đúng & đáp ứng)

Phần này tổng hợp lại **yêu cầu** và **giải pháp** để rà soát: đã hiểu đủ đúng và giải pháp đã đáp ứng chưa.

### 8.1. Tóm tắt yêu cầu (11 yêu cầu)

| # | Yêu cầu | Tóm tắt |
|---|---------|--------|
| **R1** | Người khởi tạo | Cấu trúc biểu mẫu do **System Admin** khởi tạo và quản lý. |
| **R2** | Nội dung cấu trúc | Form + sheet, cột, hàng, công thức, khóa, format, style, data binding, column mapping. |
| **R3** | Chỉ tiêu cố định | Cột/hàng định nghĩa sẵn; đơn vị chỉ nhập **giá trị** vào ô. |
| **R4** | Placeholder chỉ tiêu động | Có vị trí giữ chỗ (placeholder) cho **chỉ tiêu do đơn vị tự nhập** (tên + giá trị). |
| **R5** | Biểu mẫu đầy đủ | Biểu mẫu = **phần cố định** + **phần động** (tại placeholder). |
| **R6** | Tái sử dụng chỉ tiêu | Xây dựng biểu mẫu bằng cách **chọn chỉ tiêu từ danh mục** (catalog), không định nghĩa lại. |
| **R7** | Chỉ tiêu cố định áp dụng tất cả | Chỉ **System Admin** nhập chỉ tiêu cố định; áp dụng cho **tất cả** đơn vị (global). |
| **R8** | Chỉ tiêu động theo danh mục, dữ liệu theo đơn vị | Chỉ tiêu động theo **danh mục**; **dữ liệu** (giá trị) **theo từng đơn vị** (mỗi submission). |
| **R9** | Danh mục phát sinh & khởi tạo động | Danh mục chỉ tiêu động **có thể phát sinh**; **khởi tạo động** qua hệ thống (API/UI), **không cần deploy**. |
| **R10** | Phân cấp cha-con (chỉ tiêu) | **Chỉ tiêu cố định** và **chỉ tiêu động** đều có **phân cấp cha-con nhiều tầng**; hiển thị/chọn theo cây. |
| **R11** | Phân cấp cột/hàng trong biểu mẫu | **Cột/hàng** cũng phân cấp cha-con (độc lập với chỉ tiêu). **Cột:** header merge = số con, cháu. **Hàng placeholder:** cấu hình **độ sâu đệ quy** chỉ tiêu con/cháu. **Tạo Excel:** ưu tiên (1) thứ tự + cha-con **cấu hình**, (2) thứ tự + cha-con **chỉ tiêu động**. |

### 8.2. Tóm tắt giải pháp theo nhóm

| Nhóm | Giải pháp tóm tắt |
|------|-------------------|
| **Quyền & người dùng** | Chỉ System Admin (hoặc Form Admin) được tạo/sửa/xóa cấu trúc form (policy FormStructureAdmin); FE ẩn Form/Cấu hình theo role. |
| **Chỉ tiêu cố định** | FormColumn (có thể FormColumn.IndicatorId từ danh mục); áp dụng cho mọi đơn vị; dữ liệu → ReportDataRow. |
| **Chỉ tiêu động & vùng placeholder** | BCDT_FormDynamicRegion (sheet, ExcelRowStart/End, ExcelColName/Value, MaxRows, **IndicatorExpandDepth**, IndicatorCatalogId). BCDT_ReportDynamicIndicator (SubmissionId, FormDynamicRegionId, RowOrder, IndicatorName/Value, **IndicatorId** khi gắn catalog). API CRUD dynamic-regions; GET/PUT submissions/{id}/dynamic-indicators. |
| **Danh mục chỉ tiêu (tái sử dụng + động)** | BCDT_IndicatorCatalog (nhiều danh mục). BCDT_Indicator (ParentId, **IndicatorCatalogId**, Code, Name, …). FormColumn.IndicatorId; FormDynamicRegion.IndicatorCatalogId. API CRUD /indicator-catalogs, /indicators (filter catalogId, **tree=true**, parentId). Khởi tạo động: tạo danh mục + chỉ tiêu hoàn toàn qua API/UI. |
| **Phân cấp chỉ tiêu (R10)** | BCDT_Indicator.ParentId (self); cây nhiều tầng cho cố định và động. API tree=true; FE TreeSelect/tree khi chọn chỉ tiêu (FormConfig, SubmissionDataEntry, trang quản lý danh mục). |
| **Phân cấp cột/hàng (R11)** | FormColumn.ParentId, FormRow.ParentId (self). **Cột:** khi build Excel, header merge (colspan) = số cột lá dưới cột cha. FormDynamicRegion.**IndicatorExpandDepth** (1/2/3/0 = gốc, gốc+con, gốc+con+cháu, không giới hạn). FormRow.FormDynamicRegionId (hàng thuộc vùng placeholder). **Build workbook:** (1) thứ tự + cha-con cấu hình (FormColumn, FormRow), (2) thứ tự + cha-con chỉ tiêu động (theo depth). API GET columns/rows **tree=true**; FE cấu hình cột/hàng dạng cây, độ sâu đệ quy. |

### 8.3. Bảng đối chiếu: Yêu cầu ↔ Giải pháp ↔ Đáp ứng

| Yêu cầu | Thành phần giải pháp | Đáp ứng |
|---------|----------------------|--------|
| **R1** | 4.1 Authorization: policy FormStructureAdmin; FE ẩn Form/Cấu hình theo role | ✅ |
| **R2** | FormDefinition, FormSheet, FormColumn, FormRow, DataBinding, ColumnMapping (đã có + mở rộng ParentId, IndicatorId) | ✅ |
| **R3** | FormColumn (cố định) + ReportDataRow; đơn vị chỉ nhập giá trị | ✅ |
| **R4** | FormDynamicRegion (vùng placeholder); ReportDynamicIndicator (tên + giá trị); API dynamic-regions, dynamic-indicators; FE block "Vùng chỉ tiêu động", SubmissionDataEntry nhập | ✅ |
| **R5** | Build workbook: merge cố định (ReportDataRow) + động (ReportDynamicIndicator) vào sheet | ✅ |
| **R6** | BCDT_Indicator (master); FormColumn.IndicatorId; API /indicators; FE "Thêm cột từ danh mục" | ✅ |
| **R7** | Chỉ System Admin sửa cấu trúc (R1); FormColumn/Indicator áp dụng cho tất cả đơn vị | ✅ |
| **R8** | FormDynamicRegion.IndicatorCatalogId; đơn vị chọn chỉ tiêu từ catalog + nhập giá trị → ReportDynamicIndicator(SubmissionId, IndicatorId, Value) | ✅ |
| **R9** | BCDT_IndicatorCatalog; API CRUD /indicator-catalogs, /indicators; tạo danh mục + chỉ tiêu qua UI, không deploy | ✅ |
| **R10** | BCDT_Indicator.ParentId; API tree=true, parentId; FE TreeSelect/tree, "Thêm chỉ tiêu con" | ✅ |
| **R11** | FormColumn.ParentId, FormRow.ParentId; merge header cột (colspan = số lá); IndicatorExpandDepth; FormRow.FormDynamicRegionId; Build workbook ưu tiên cấu hình → chỉ tiêu động; API tree=true columns/rows; FE cây cột/hàng, cấu hình độ sâu | ✅ |

### 8.4. Ba loại phân cấp (tránh nhầm lẫn)

| Loại | Bảng / Cấu hình | Mục đích | Độc lập? |
|------|------------------|----------|----------|
| **Phân cấp chỉ tiêu** | BCDT_Indicator (ParentId, IndicatorCatalogId) | Cây chỉ tiêu cố định / trong từng danh mục chỉ tiêu động | — |
| **Phân cấp cột trong form** | BCDT_FormColumn (ParentId) | Cấu trúc cột của sheet (header merge = số con/cháu) | Có, độc lập với cây chỉ tiêu |
| **Phân cấp hàng trong form** | BCDT_FormRow (ParentId, FormDynamicRegionId) | Cấu trúc hàng của sheet; hàng placeholder gắn vùng + độ sâu đệ quy | Có, độc lập với cây chỉ tiêu |

### 8.5. Checklist kiểm tra nhanh

- [ ] **R1–R2:** Chỉ System Admin tạo/sửa cấu trúc; cấu trúc đủ: form, sheet, cột, hàng, binding, mapping.
- [ ] **R3–R5:** Có chỉ tiêu cố định (nhập giá trị) + vùng placeholder chỉ tiêu động; biểu mẫu đầy đủ = cố định + động.
- [ ] **R6–R7:** Có danh mục chỉ tiêu; FormColumn có thể chọn từ danh mục; chỉ tiêu cố định áp dụng tất cả đơn vị.
- [ ] **R8–R9:** Chỉ tiêu động theo danh mục; dữ liệu theo đơn vị (submission); danh mục phát sinh & khởi tạo động qua API/UI.
- [ ] **R10:** Chỉ tiêu (cố định + động) có phân cấp cha-con; API tree; FE TreeSelect/tree.
- [ ] **R11:** Cột/hàng có phân cấp (FormColumn/FormRow.ParentId); header cột merge theo số con/cháu; vùng placeholder có độ sâu đệ quy (IndicatorExpandDepth); tạo Excel ưu tiên cấu hình rồi chỉ tiêu động.

Nếu tất cả ô trên đều khớp với mong muốn nghiệp vụ thì giải pháp được xem là **đã hiểu đủ đúng và đáp ứng**. Nếu có điểm chưa khớp, ghi rõ yêu cầu/điều chỉnh để cập nhật tài liệu.

---

**Version:** 1.4 · **Last updated:** 2026-02-06 · Bổ sung R11 (phân cấp cột/hàng trong biểu mẫu, merge header cột, độ sâu đệ quy placeholder, thứ tự ưu tiên build), G10, mục 4.8 (FormColumn/FormRow.ParentId, IndicatorExpandDepth, thứ tự ưu tiên), thành phần #12, P2a, cập nhật 4.2/4.4; thêm mục 8 Tổng hợp yêu cầu và đối chiếu giải pháp.
