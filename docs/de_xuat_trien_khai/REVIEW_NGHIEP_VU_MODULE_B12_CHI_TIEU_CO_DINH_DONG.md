# Báo cáo Review nghiệp vụ – Module B12 (Chỉ tiêu cố định & động)

**Ngày:** 2026-02-24  
**Agent:** bcdt-business-reviewer  
**Phạm vi:** R1–R11 (cấu trúc biểu mẫu – chỉ tiêu cố định & động); FormDynamicRegion, ReportDynamicIndicator, IndicatorCatalog, Indicator; FormColumn/FormRow phân cấp; build workbook; FE FormConfig, SubmissionDataEntry.

---

## 1. Phạm vi review

- **Yêu cầu nguồn:** YEU_CAU_HE_THONG_TONG_HOP (R1–R11), B12_CHI_TIEU_CO_DINH_DONG.md, GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md.
- **Implementation:** FormStructureAdmin policy; FormDefinitionsController, FormSheetsController, FormColumnsController, FormRowsController, FormDynamicRegionsController, FormColumnDataBindingController, FormColumnMappingController; IndicatorCatalogsController, IndicatorsController; SubmissionsController (GET/PUT dynamic-indicators); BuildWorkbookFromSubmissionService; bảng BCDT_FormDynamicRegion, BCDT_ReportDynamicIndicator, BCDT_IndicatorCatalog, BCDT_Indicator; FormColumn.ParentId/IndicatorId, FormRow.ParentId/FormDynamicRegionId; FE FormConfigPage (cây cột/hàng, vùng chỉ tiêu động), SubmissionDataEntryPage (chỉ tiêu động).

---

## 2. Bảng đối chiếu (Yêu cầu R1–R11 ↔ Implementation)

| # | Yêu cầu | Nguồn | Implementation | Trạng thái |
|---|---------|-------|----------------|------------|
| 1 | R1 – Người khởi tạo: cấu trúc do System Admin | R1 | Policy FormStructureAdmin (SYSTEM_ADMIN, FORM_ADMIN); [Authorize(Policy = "FormStructureAdmin")] trên POST/PUT/DELETE FormDefinitions, FormSheets, FormColumns, FormRows, FormDynamicRegions, FormColumnDataBinding, FormColumnMapping, IndicatorCatalogs, Indicators | **Đạt** |
| 2 | R2 – Nội dung cấu trúc: form, sheet, cột, hàng, binding, mapping | R2 | FormDefinition, FormSheet, FormColumn, FormRow; FormDataBinding, FormColumnMapping; API CRUD đầy đủ | **Đạt** |
| 3 | R3 – Chỉ tiêu cố định: cột/hàng định nghĩa sẵn, đơn vị nhập giá trị | R3 | FormColumn, FormRow (RowType); workbook-data với ô cố định; đơn vị nhập qua SubmissionDataEntry | **Đạt** |
| 4 | R4 – Placeholder chỉ tiêu động (vùng tên + giá trị) | R4 | FormDynamicRegion (ExcelRowStart, cột tên/giá trị, MaxRows, IndicatorExpandDepth, IndicatorCatalogId); CRUD /forms/{id}/sheets/{id}/dynamic-regions | **Đạt** |
| 5 | R5 – Biểu mẫu đầy đủ = cố định + động | R5 | Build workbook: cấu hình (cột/hàng tree) + vùng động (ReportDynamicIndicator); workbook-data trả sheets với columnHeaders + dynamicRegions | **Đạt** |
| 6 | R6 – Tái sử dụng chỉ tiêu từ danh mục | R6 | BCDT_IndicatorCatalog, BCDT_Indicator; FormColumn.IndicatorId; FormDynamicRegion.IndicatorCatalogId; CRUD indicator-catalogs, indicators (tree) | **Đạt** |
| 7 | R7 – Chỉ tiêu cố định do System Admin, áp dụng tất cả đơn vị | R7 | FormStructureAdmin trên form structure; cột/hàng cấu hình dùng chung cho mọi submission | **Đạt** |
| 8 | R8 – Chỉ tiêu động theo danh mục, dữ liệu theo đơn vị | R8 | ReportDynamicIndicator (theo submission); GET/PUT /submissions/{id}/dynamic-indicators; dữ liệu theo submission (đơn vị) | **Đạt** |
| 9 | R9 – Danh mục phát sinh, khởi tạo động (API/UI, không deploy) | R9 | CRUD IndicatorCatalog, CRUD Indicator (theo catalogId); FE IndicatorCatalogsPage; tạo/sửa danh mục và chỉ tiêu qua UI | **Đạt** |
| 10 | R10 – Phân cấp cha-con chỉ tiêu (nhiều tầng, tree) | R10 | BCDT_Indicator.ParentId; GET indicators?tree=true; FE TreeSelect, cây chỉ tiêu trong danh mục | **Đạt** |
| 11 | R11 – Phân cấp cột/hàng; merge header; độ sâu đệ quy; ưu tiên build | R11 | FormColumn.ParentId, FormRow.ParentId/FormDynamicRegionId; GET rows?tree=true, columns?tree=true; FormDynamicRegion.IndicatorExpandDepth; build workbook: thứ tự cấu hình → chỉ tiêu động; merge header (colspan) trong workbook-data | **Đạt** |
| 12 | FE FormConfig: cây cột/hàng, vùng chỉ tiêu động | B12 P5 | FormConfigPage: block Cột (dạng cây), Hàng (dạng cây), Vùng chỉ tiêu động; TreeSelect cha; Thêm/Sửa/Xóa vùng (IndicatorCatalogId, IndicatorExpandDepth) | **Đạt** |
| 13 | FE SubmissionDataEntry: chỉ tiêu động, lưu PUT dynamic-indicators | B12 P6 | SubmissionDataEntryPage: block Chỉ tiêu động, bảng Tên/Giá trị, Lưu chỉ tiêu động; PUT dynamic-indicators; GET dynamic-indicators | **Đạt** |
| 14 | Sync presentation → ReportDynamicIndicator | B12 P4 | Sync từ WorkbookJson (vùng placeholder) ghi ReportDynamicIndicator | **Đạt** |

---

## 3. Gap

| Mức độ | Mô tả |
|--------|--------|
| **Không có** | Trong phạm vi R1–R11 và B12 P1–P7, implementation đã phủ đủ: policy, DB, API dynamic-regions/dynamic-indicators/indicator-catalogs/indicators, rows/columns tree, build workbook (merge, depth, pre-fill/merge), sync, FE FormConfig + SubmissionDataEntry. |

Không có gap **Critical**, **Major** hay **Minor** cần ghi nhận cho module B12 so với yêu cầu R1–R11 và tài liệu B12/GIAI_PHAP.

---

## 4. Mâu thuẫn / Rủi ro

- **Không phát hiện mâu thuẫn** giữa GIAI_PHAP, B12 và code (API, entity, service, FE).
- **Rủi ro nhỏ:** FormCell (BCDT_FormCell) có trong schema nhưng chưa có API/UI riêng; B12 không phụ thuộc FormCell (dùng FormRow + FormDynamicRegion). Có thể xem là ngoài phạm vi B12 hoặc mở rộng sau.

---

## 5. Khuyến nghị

| Ưu tiên | Khuyến nghị |
|---------|-------------|
| **P3** | Giữ checklist "Kiểm tra cho AI" B12 mục 4 (7.1) và test cases; khi sửa cấu trúc chỉ tiêu/placeholder tiếp tục chạy đủ bước (build, P2a script, P4 workbook-dynamic, P7 E2E) và báo Pass/Fail. |

**Kết luận:** Module B12 (Chỉ tiêu cố định & động) **đạt đủ yêu cầu** R1–R11 và deliverable P1–P7. Không có gap so với đặc tả; có thể đánh dấu review B12 hoàn tất.
