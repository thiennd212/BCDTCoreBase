# Rà soát nghiệp vụ – Biểu mẫu động (Excel)

Đối chiếu **yêu cầu nghiệp vụ Biểu mẫu động (Excel)** với hiện trạng codebase và tài liệu (GIAI_PHAP, B12, P8).  
**Ngày:** 2026-02-26

---

## 1. Yêu cầu nghiệp vụ (nguồn)

| # | Yêu cầu | Chi tiết |
|---|---------|----------|
| 1 | Có SHEET, CỘT, HÀNG, CÔNG THỨC | Cấu trúc đầy đủ 4 thành phần. |
| 2 | SHEET bao gồm cột và hàng | Sheet chứa cột và hàng. |
| 3 | CỘT và HÀNG có phân cấp cha con, style, format | Phân cấp; style; format. |
| 4 | CỘT và HÀNG giao nhau tạo CELL | Giao cột–hàng = ô (cell). |
| 5 | CỘT cha merge = số cột lá; tên merge ở giữa | Merge header; căn giữa tên cột đã merge. |
| 6 | Chỉ tiêu CỘT quản lý tập trung để tái sử dụng | Danh mục chỉ tiêu dùng chung. |
| 7 | Template chưa mapping Excel (A,B,C) | Số cột chưa biết lúc tạo template (cột 3+ từ danh mục/đơn vị). |
| 8 | HÀNG: tiêu chí cụ thể hoặc danh mục theo đơn vị; chọn dữ liệu hiển thị từng cột cho hàng | Mỗi hàng: cột 1 = tên, cột 2 = đơn vị, cột 3/4 = nhập… |
| 9 | CỘT và HÀNG cấu hình được nhập hay không | Cấu hình ô được nhập / không nhập. |
| 10 | CÔNG THỨC: áp dụng cho cả HÀNG, cả CỘT, hoặc từng CELL | Công thức theo phạm vi: hàng / cột / cell. |
| 11 | Khi ra biểu nhập liệu theo đơn vị | Mapping Excel (A,B,C), số hàng chính xác, công thức từng CELL được xác định khi build. |

---

## 2. Đối chiếu từng yêu cầu

### 2.1. SHEET, CỘT, HÀNG, CÔNG THỨC (1–2)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| SHEET | BCDT_FormSheet, API CRUD, FE FormConfig | ✅ Đạt |
| CỘT | BCDT_FormColumn (ParentId, IndicatorId, ExcelColumn, DataType, Formula, Format, IsEditable…), API, FE | ✅ Đạt |
| HÀNG | BCDT_FormRow (ParentRowId, FormDynamicRegionId, RowType, ExcelRowStart/End…), API GET/POST/PUT/DELETE rows, FE cây | ✅ Đạt |
| CÔNG THỨC | FormColumn.Formula, FormDataBinding.Formula, Indicator.FormulaTemplate; DataType = "Formula" | ✅ Đạt (ở cấp cột/binding) |

**Kết luận:** Cấu trúc SHEET → CỘT, HÀNG có đủ; công thức có ở cột và binding.

---

### 2.2. CỘT và HÀNG phân cấp, style, format (3)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| Phân cấp CỘT | FormColumn.ParentId (self-FK); API columns?tree=true; FE FormConfig cột dạng cây | ✅ Đạt |
| Phân cấp HÀNG | FormRow.ParentRowId; API rows?tree=true; FE FormConfig hàng dạng cây | ✅ Đạt |
| Style/format CỘT | FormColumn: Format, Width; ColumnGroupName/Level2/3/4 (header nhóm) | ✅ Đạt (cột) |
| Style/format HÀNG | FormRow: Height | ⚠️ Một phần (chỉ height; style chi tiết chưa đủ) |
| Style/format CELL | BCDT_FormCell (DB): IsLocked, IsEditable, BackgroundColor, FontColor, FontBold, BorderStyle, HorizontalAlign, VerticalAlign. **Chưa có Entity/API/FE** cho FormCell | ⚠️ Gap: bảng có, ứng dụng chưa dùng |

**Kết luận:** Phân cấp cột/hàng đạt; style/format cột có; style ô (FormCell) có trong DB nhưng chưa đưa vào ứng dụng.

---

### 2.3. CỘT và HÀNG giao nhau tạo CELL (4)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| Khái niệm CELL | BCDT_FormCell (FormColumnId, FormRowId, CellAddress) tồn tại trong DB | ✅ Schema có |
| Ứng dụng CELL | Không có Entity FormCell trong Domain; không có API/FE CRUD FormCell; Build workbook không đọc FormCell | ⚠️ Gap: CELL chỉ tồn tại ngầm (cột × hàng); cấu hình từng ô qua FormCell chưa dùng |

**Kết luận:** Giao cột–hàng về mặt dữ liệu là có (workbook-data trả rows keyed by ExcelColumn); **cấu hình từng cell (FormCell)** chưa được triển khai trong ứng dụng.

---

### 2.4. CỘT cha merge = số cột lá; tên ở giữa (5)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| Merge header cột cha | BuildWorkbookFromSubmissionService.BuildColumnHeaders: Colspan = số cột lá (GetLeafCount); columnHeaders trả Colspan, ExcelColumn, ColumnName | ✅ Đạt |
| Tên cột merge hiển thị ở giữa | columnHeaders đưa ra FE/Excel; căn giữa (center) có thể do FE/Excel áp dụng khi render merge. Chưa xác nhận field align riêng cho header merge trong BE | ⚠️ Một phần: merge đúng; "mặc định ở giữa" cần kiểm tra FE/export Excel |

**Kết luận:** Merge theo số cột lá đạt; căn giữa tên cột merge cần xác nhận ở FE/export.

---

### 2.5. Chỉ tiêu CỘT quản lý tập trung, tái sử dụng (6)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| Danh mục chỉ tiêu | BCDT_IndicatorCatalog, BCDT_Indicator (ParentId, IndicatorCatalogId); API CRUD indicator-catalogs, indicators; FE Danh mục chỉ tiêu, TreeSelect | ✅ Đạt |
| FormColumn gắn chỉ tiêu | FormColumn.IndicatorId (FK Indicator); "Thêm cột từ danh mục" → chọn Indicator, copy metadata | ✅ Đạt (GIAI_PHAP 4.6, B12, DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU) |

**Kết luận:** Đạt.

---

### 2.6. Template chưa mapping Excel (A,B,C) – cột/hàng động (7–8)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| Cột từ danh mục/nguồn, số cột chưa biết lúc tạo template | FormDynamicColumnRegion + FormPlaceholderColumnOccurrence (P8e, P8f); DataSource + Filter → N cột khi build; template chỉ định "vùng cột động", không fix A,B,C | ✅ Đạt |
| Hàng từ danh mục/đơn vị, số hàng chưa biết | FormPlaceholderOccurrence (P8b, P8d) + FormDynamicRegion; DataSource/Filter hoặc IndicatorCatalog + IndicatorExpandDepth → N hàng khi build theo đơn vị | ✅ Đạt |
| Hàng: chọn dữ liệu hiển thị từng cột (tên cột 1, đơn vị cột 2, cột 3/4 nhập) | Hiện tại: vùng chỉ tiêu động có ExcelColName (tên), ExcelColValue (giá trị); chưa có cấu hình "theo từng cột của hàng" (vd cột 1 = tên, cột 2 = đơn vị, cột 3 = nhập). Binding/binding type theo **cột** (FormDataBinding), không theo (hàng, cột) | ⚠️ Gap: "dữ liệu hiển thị từng cột tương ứng với hàng" (label vs input từng cột cho từng hàng) chưa mô hình hóa rõ; có thể cần mở rộng FormDataBinding/FormCell hoặc quy ước theo vùng. |

**Kết luận:** Template không fix Excel (A,B,C) cho cột/hàng động đạt (P8). Cấu hình "theo hàng, từng cột hiển thị gì" chưa đủ rõ.

---

### 2.7. CỘT và HÀNG cấu hình nhập / không nhập (9)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| Cột: được nhập hay không | FormColumn.IsEditable (bool) | ✅ Đạt |
| Hàng/ô: được nhập hay không | FormCell.IsEditable trong DB; ứng dụng chưa dùng FormCell. Hiện chỉ cấu hình theo cột (IsEditable) | ⚠️ Một phần: cột có; ô (cell) có trong DB nhưng chưa dùng trong build/API |

**Kết luận:** Cấu hình nhập theo cột đạt; theo từng ô (cell) chưa dùng trong ứng dụng.

---

### 2.8. CÔNG THỨC: cả HÀNG, cả CỘT, hoặc từng CELL (10)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| Công thức theo CỘT | FormColumn.Formula, FormDataBinding.Formula (binding type Formula) | ✅ Đạt |
| Công thức theo HÀNG | Không có FormRow.Formula hay cấu hình công thức theo hàng | ❌ Chưa có |
| Công thức theo CELL | BCDT_FormCell không có cột Formula; không có API/Entity FormCell | ❌ Chưa có |

**Kết luận:** Chỉ đạt công thức **theo cột**; công thức theo hàng và theo từng cell chưa triển khai.

---

### 2.9. Khi ra biểu nhập liệu theo đơn vị (11)

| Yêu cầu | Hiện trạng | Đánh giá |
|---------|------------|----------|
| Xác định mapping Excel (A,B,C) khi build | Build workbook (workbook-data) duyệt cột (cố định + động P8), gán ExcelColumn; dynamicColumnRegions có columnLabels; rows keyed by ExcelColumn | ✅ Đạt |
| Số hàng chính xác khi build | FormPlaceholderOccurrence + DataSource/Filter hoặc ReportDynamicIndicator/catalog → N hàng; dynamicRegions[].rows | ✅ Đạt |
| Tạo công thức tương ứng từng CELL | Công thức đang áp dụng ở cấp cột (FormColumn.Formula, binding Formula); chưa có bước "sinh công thức từng cell theo vị trí Excel" khi build (vd tham chiếu ô A1, B2…) | ⚠️ Một phần: công thức cột có; công thức theo cell/vị trí khi build chưa mô tả rõ trong code |

**Kết luận:** Mapping Excel và số hàng khi build đạt; công thức từng cell (theo vị trí) khi build cần bổ sung nếu nghiệp vụ yêu cầu.

---

## 3. Tổng hợp gap và đề xuất chỉnh sửa

### 3.1. Đã đáp ứng (không cần chỉnh)

- SHEET, CỘT, HÀNG, CÔNG THỨC (cấp cột/binding).
- Phân cấp CỘT/HÀNG (ParentId, ParentRowId), API tree, FE cây.
- Merge header cột cha = số cột lá (colspan).
- Chỉ tiêu CỘT tập trung (Indicator catalog), tái sử dụng (FormColumn.IndicatorId).
- Template không mapping Excel cho cột/hàng động (P8: placeholder dòng + cột, DataSource, Filter, catalog).
- Khi ra biểu nhập liệu: xác định mapping Excel và số hàng (workbook-data).
- Cấu hình nhập theo cột (FormColumn.IsEditable).

### 3.2. Cần bổ sung hoặc làm rõ

| # | Gap | Mức | Đề xuất |
|---|-----|-----|---------|
| 1 | **CÔNG THỨC theo HÀNG và theo CELL** | Cao (nếu nghiệp vụ bắt buộc) | Thiết kế: FormRow.Formula (công thức áp dụng cả hàng) hoặc BCDT_FormCell thêm cột Formula; Build workbook áp dụng khi render. Nếu chỉ cần công thức theo cột thì giữ hiện trạng. |
| 2 | **FormCell chưa dùng trong ứng dụng** | Trung bình | BCDT_FormCell có trong DB (style, IsEditable, FormColumnId, FormRowId) nhưng chưa Entity/API/FE. Cần dùng FormCell khi: cấu hình từng ô (khóa, style, công thức từng cell). Ưu tiên sau khi làm rõ nhu cầu "cấu hình theo ô". |
| 3 | **Cấu hình "dữ liệu hiển thị từng cột cho hàng"** | Trung bình | Yêu cầu: với mỗi hàng, cột 1 = tên, cột 2 = đơn vị, cột 3/4 = nhập. Hiện binding theo cột; có thể mở rộng FormDataBinding/FormCell hoặc quy ước theo vùng (vd vùng chỉ tiêu động đã có ExcelColName/ExcelColValue). Làm rõ nghiệp vụ rồi thiết kế. |
| 4 | **Tên cột merge mặc định ở giữa** | Thấp | Kiểm tra FE và export Excel: khi render header merge đã căn giữa chưa; nếu chưa thì thêm align (HorizontalAlign) cho column header hoặc cấu hình trong FormCell khi đưa FormCell vào dùng. |
| 5 | **Công thức từng CELL khi build** | Trung bình | Nếu cần "tạo công thức tương ứng từng CELL" (vd =A1+B1) khi build: mô hình Formula tại FormCell hoặc rule sinh từ FormColumn/FormRow; BuildWorkbookFromSubmissionService áp dụng khi ghi ô. |

### 3.3. Không chỉnh (đã đúng)

- Cấu trúc Sheet/Column/Row, phân cấp, merge header, danh mục chỉ tiêu, placeholder cột/hàng (P8), workbook-data theo đơn vị.

---

## 4. Kết luận

| Tiêu chí | Kết luận |
|----------|----------|
| **Đáp ứng phần lớn** | Cấu trúc SHEET/CỘT/HÀNG, phân cấp, style/format cột, merge header, chỉ tiêu tập trung, không mapping Excel lúc tạo template (P8), build theo đơn vị đều đã có. |
| **Cần chỉnh / bổ sung** | (1) Công thức theo HÀNG và theo CELL nếu nghiệp vụ bắt buộc; (2) Đưa FormCell vào ứng dụng nếu cần cấu hình từng ô; (3) Cấu hình "dữ liệu hiển thị từng cột cho hàng"; (4) Công thức từng cell khi build; (5) Căn giữa tên cột merge (kiểm tra FE/Excel). |
| **Tham chiếu** | [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md), [B12_CHI_TIEU_CO_DINH_DONG.md](de_xuat_trien_khai/B12_CHI_TIEU_CO_DINH_DONG.md), [P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md), [DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md](de_xuat_trien_khai/DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md). |

---

**Version:** 1.0  
**Last Updated:** 2026-02-26
