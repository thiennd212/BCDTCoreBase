# Báo cáo Review nghiệp vụ – Module Form Definition (B7–B8)

**Ngày:** 2026-02-24  
**Agent:** bcdt-business-reviewer  
**Phạm vi:** Form Definition CRUD, Sheet, Column, Data Binding, Column Mapping (B7, B8); yêu cầu BM-*, FR-BM-* liên quan.

---

## 1. Phạm vi review

- **Yêu cầu nguồn:** 01.YEU_CAU_HE_THONG (BM-01–BM-06, FR-BM-01–FR-BM-06), YEU_CAU_HE_THONG_TONG_HOP, B7_FORM_DEFINITION.md, B8_FORM_SHEET_COLUMN_DATA_BINDING.md.
- **Implementation:** FormDefinitionsController, FormSheetsController, FormColumnsController, FormColumnDataBindingController, FormColumnMappingController; FormDynamicRegionsController (B12); IFormDefinitionService, IFormSheetService, IFormColumnService, IFormDataBindingService, IFormColumnMappingService, IFormTemplateService; BCDT_FormDefinition, FormVersion, FormSheet, FormColumn, FormDataBinding, FormColumnMapping; FE FormsPage, FormConfigPage.

---

## 2. Bảng đối chiếu (Yêu cầu ↔ Implementation)

| # | Yêu cầu | Nguồn | Implementation | Trạng thái |
|---|---------|-------|----------------|------------|
| 1 | CRUD biểu mẫu (tạo, sửa, xóa) | FR-BM-01, B7 | GET/POST /api/v1/forms, GET/PUT/DELETE /{id}; CreateFromTemplate (upload Excel + tên); FormDefinitionService | **Đạt** |
| 2 | Nhân bản biểu mẫu | FR-BM-01 | Không có endpoint clone/copy form riêng; có thể tạo mới từ template của form cũ | **Một phần** (gap Minor) |
| 3 | Định nghĩa cấu trúc (cột, hàng, tiêu chí, format) | FR-BM-02, BM-03 | FormSheet (SheetIndex, SheetName, IsDataSheet); FormColumn (ColumnCode, ExcelColumn, DataType, IsRequired, IsEditable, ValidationRule); FormRow/FormCell (B12 mở rộng); B8 API sheets/columns CRUD | **Đạt** |
| 4 | Cấu hình data binding (7 loại nguồn) | FR-BM-03, BM-04, B8 | FormDataBinding: Static, Database, API, Formula, Reference, Organization, System; IFormDataBindingService; API .../columns/{id}/data-binding | **Đạt** |
| 5 | Template Excel – Upload/Download | FR-BM-04 | GET /forms/{id}/template (fillBinding, organizationId, reportingPeriodId); POST /forms/from-template; POST /forms/{id}/template (upload); GET /forms/{id}/template-display (Fortune-sheet JSON) | **Đạt** |
| 6 | Preview (xem trước biểu mẫu) | FR-BM-05 | template-display JSON + FE nhập liệu (Fortune-sheet); có thể coi là preview khi mở form nhập liệu | **Một phần** (preview riêng màn hình chưa có) |
| 7 | Versioning (quản lý phiên bản) | FR-BM-06, B7 | GET /forms/{id}/versions; BCDT_FormVersion, CurrentVersion; không tạo/sửa version qua API trong B7 (đúng spec B7) | **Đạt** |
| 8 | Multi-sheet support | BM-05 | FormSheet nhiều bản ghi theo FormDefinitionId; template Excel nhiều worksheet | **Đạt** |
| 9 | Nguồn dữ liệu đa dạng (DB, API, công thức, danh mục) | BM-04 | 7 BindingType; DataBindingResolver, ResolveContext; fillBinding khi GetTemplate | **Đạt** |
| 10 | Column mapping (Excel → lưu trữ) | B8 | FormColumnMapping (TargetColumnName, TargetColumnIndex, AggregateFunction); API .../columns/{id}/column-mapping | **Đạt** |
| 11 | FE FormsPage (list, versions) | B7, TONG_HOP 4 | FormsPage (list biểu mẫu, versions); formsApi | **Đạt** |
| 12 | FE FormConfigPage (sheet, column, binding, cây cột/hàng) | B8, TONG_HOP 4 | FormConfigPage (cấu hình sheet, cột, data binding, mapping; B12 vùng chỉ tiêu động, P8) | **Đạt** |

---

## 3. Gap

| Mức độ | Mô tả |
|--------|--------|
| **Minor** | **FR-BM-01 Nhân bản biểu mẫu:** Chưa có API clone/copy form (vd POST /forms/{id}/clone). Hiện có thể tạo form mới từ template của form gốc (download template → from-template) nhưng không một lệnh "nhân bản". |
| **Minor** | **FR-BM-05 Preview:** "Xem trước biểu mẫu" chưa có màn preview riêng (chỉ xem khi vào nhập liệu hoặc tải template). Có thể bổ sung route preview chỉ đọc (template-display đã hỗ trợ). |

Không có gap **Critical** hoặc **Major** đối với B7, B8 và FR-BM/BM trong MVP.

---

## 4. Mâu thuẫn / Rủi ro

- **Không phát hiện mâu thuẫn** giữa tài liệu B7/B8 và code (endpoint, entity, binding types, API structure).
- **Rủi ro nhỏ:** FormConfigPage tích hợp B12 + P8 (động, placeholder) – phạm vi review B7–B8 là cấu trúc cố định + binding/mapping; B12/P8 đã có báo cáo riêng trong kế hoạch mở rộng.

---

## 5. Khuyến nghị

| Ưu tiên | Khuyến nghị |
|---------|-------------|
| **P2** | (Tùy chọn) Thêm API nhân bản biểu mẫu: POST /api/v1/forms/{id}/clone (hoặc copy) trả FormDefinitionDto mới (copy FormDefinition + FormSheets + FormColumns + FormDataBinding + FormColumnMapping, đổi Code/Name). |
| **P2** | (Tùy chọn) Màn preview biểu mẫu: route /forms/{id}/preview dùng template-display hoặc template fillBinding=false, chỉ đọc. |
| **P3** | Giữ checklist "Kiểm tra cho AI" trong B7, B8; khi sửa Form/Sheet/Column tiếp tục chạy đủ bước và báo Pass/Fail. |

**Kết luận:** Module Form Definition (B7–B8) **đạt đủ yêu cầu MVP** cho FR-BM-02, FR-BM-03, FR-BM-04, FR-BM-06 và BM-03–BM-06. Gap ở mức Minor (nhân bản, preview riêng); không ảnh hưởng nghiệm thu Phase 2.
