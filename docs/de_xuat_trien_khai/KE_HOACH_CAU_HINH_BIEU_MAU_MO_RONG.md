# Kế hoạch Cấu hình biểu mẫu mở rộng (B12 + P8) – Một nguồn tiến độ & công việc

**Mục đích:** Một tài liệu duy nhất cho **tiến độ**, **trạng thái**, **kế hoạch chi tiết** và **phần cần làm** của mở rộng cấu hình biểu mẫu (B12 P2a, P4 mở rộng, P7, P8a–P8f). Tránh chồng chéo với TONG_HOP (TONG_HOP giữ vai trò tổng thể dự án + **Cách giao AI** tại mục 3.3, 3.5, 3.7).

**Ngày:** 2026-02-06.  
**Tham chiếu thiết kế:** [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) (R1–R11), [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md) (P8).  
**Cách giao AI:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) **mục 3.3, 3.5 hoặc 3.7** (block B12 P2a, P4 mở rộng, P7, P8).

---

## 1. Tổng quan và ý nghĩa vùng chỉ tiêu động

- **Vùng chỉ tiêu động (đã có):** FormDynamicRegion – vị trí placeholder trên sheet: **ExcelRowStart** (và **ExcelRowEnd** hoặc **MaxRows**); **ExcelColName** (cột "Tên chỉ tiêu"), **ExcelColValue** (cột "Giá trị") – cấu trúc cố định 2 cột; **số hàng không cố định** lúc khởi tạo template, mỗi submission lưu trong BCDT_ReportDynamicIndicator. Build workbook điền vùng; Sync đọc 2 cột → ReportDynamicIndicator.
- **Mở rộng cần làm:** (1) Phân cấp hàng + API tree cột/hàng (P2a). (2) Sinh dòng từ cây chỉ tiêu theo IndicatorExpandDepth khi build (P4 mở rộng). (3) Lọc động theo trường + vị trí placeholder dòng (P8a–P8d). (4) Placeholder cột + điều kiện lọc (P8e–P8f). (5) E2E và tài liệu (P7).

---

## 2. Trạng thái đã làm / chưa làm (cập nhật tại đây)

| Phase | Trạng thái | Ghi chú ngắn |
|-------|------------|--------------|
| **B12 P1–P4** | ✅ Đã xong | FormStructureAdmin, DB (script 20), API dynamic-regions/dynamic-indicators, Build workbook ColumnHeaders + DynamicRegions, Sync. |
| **B12 P5–P6** | ✅ Đã xong | FE FormConfig "Vùng chỉ tiêu động", SubmissionDataEntry "Chỉ tiêu động" (PUT dynamic-indicators, TreeSelect catalog). |
| **B12 P2a** | ✅ Đã xong (2026-02-06) | FormRow.ParentId, API columns/rows?tree=true, FE cây cột/hàng, index DB. Checklist 5b–5h. |
| **B12 P4 mở rộng** | ✅ Đã xong (2026-02-09) | Sinh dòng từ cây Indicator theo IndicatorExpandDepth khi build workbook; BuildWorkbookFromSubmissionService: 1 query indicators theo catalog, FlattenIndicatorTreeByDepth, pre-fill/merge ReportDynamicIndicator. |
| **B12 P7** | ✅ Đã xong (2026-02-09) | E2E FormConfig + SubmissionDataEntry (e2e/b12-p7-formconfig-submission.spec.ts 2/2 Pass); B12 checklist bước 13; TONG_HOP cập nhật. |
| **P8a–P8d** | ✅ Đã xong (2026-02-10) | P8a: script 21, CRUD API. P8b: ParameterContext, IDataSourceQueryService, BuildWorkbook mở rộng N hàng. P8c–P8d: FE 3 card P8, test checklist. |
| **P8e–P8f** | ✅ Đã xong (2026-02-06) | Script 22; FormDynamicColumnRegion, FormPlaceholderColumnOccurrence; CRUD API; Build workbook dynamicColumnRegions; FE 2 card Vùng cột động, Vị trí placeholder cột. |

### 2.1. B12 – Chi tiết đã / chưa

| Hạng mục | Đã triển khai | Chưa |
|----------|----------------|------|
| P1 | FormStructureAdmin; POST/PUT/DELETE Form (definition, sheet, column, data-binding, column-mapping). | — |
| P2 | BCDT_FormDynamicRegion, ReportDynamicIndicator, IndicatorCatalog, Indicator; FormColumn.ParentId, IndicatorId; FormRow.FormDynamicRegionId. | FormRow.ParentId (kiểm tra script 20). |
| P2a | ✅ FormRow CRUD + GET rows?tree=true; FormColumn GET columns?tree=true, ParentId/IndicatorId; index DB; FE cây cột/hàng. | — |
| P3 | CRUD FormDynamicRegion; GET/PUT dynamic-indicators. | (P1b) indicator-catalogs, indicators tree – rà lại. |
| P4 | ColumnHeaders (colspan), DynamicRegions từ ReportDynamicIndicator; Sync. | Sinh dòng từ cây Indicator theo depth; duyệt hàng theo FormRow. |
| P5–P6 | FE FormConfig block vùng chỉ tiêu động; SubmissionDataEntry block chỉ tiêu động. | FE cây cột/hàng (sau P2a). |
| P7 | E2E (b12-p7-formconfig-submission.spec.ts), checklist bước 13; B12, TONG_HOP cập nhật. | — |

---

## 3. Thứ tự triển khai và bảng kế hoạch

### 3.1. Thứ tự (nhìn tổng thể)

| Bước | Phase | Tên ngắn | Ước lượng |
|------|--------|----------|-----------|
| 1 | B12 P2a | Phân cấp hàng + API tree columns/rows + FE cây cột/hàng | 1–1.5 ngày |
| 2 | B12 P4 mở rộng | Sinh dòng theo IndicatorExpandDepth khi build workbook | 1–1.5 ngày |
| 3 | B12 P7 | Test E2E + cập nhật tài liệu | 0.5–1 ngày |
| 4 | P8a | DB + API DataSource, FilterDefinition, FormPlaceholderOccurrence | 2–3 ngày |
| 5 | P8b | Engine resolve filter + Build workbook mở rộng N hàng | 2–3 ngày |
| 6 | P8c | FE DataSource, FilterDefinition, Vị trí placeholder (dòng) | 2–3 ngày |
| 7 | P8d | Test P8 placeholder dòng + bộ lọc | 1 ngày |
| 8 | P8e | DB + API + Build workbook placeholder cột | 2–3 ngày |
| 9 | P8f | FE Vùng cột động + Test placeholder cột | 2–3 ngày |

**Tổng ước lượng:** khoảng **14–20 ngày**.

### 3.2. Phụ thuộc

```
B12 P2a ──► B12 P4 mở rộng ──► B12 P7
P8a ──► P8b ──► P8c ──► P8d
P8a ──► P8e ──► P8f
```

### 3.3. Bảng kế hoạch chi tiết (phase ↔ nội dung ↔ tiêu chí)

| Phase | Nội dung chính | Tiêu chí nghiệm thu |
|-------|----------------|----------------------|
| **B12 P2a** | DB FormRow.ParentId; API columns/rows?tree=true, POST/PUT parentId; FE cây cột/hàng, độ sâu đệ quy. | GET tree trả cây; FE cây đúng; index (FormSheetId, ParentId, DisplayOrder). |
| **B12 P4 mở rộng** | Build workbook: vùng có IndicatorCatalogId → query cây Indicator → cắt IndicatorExpandDepth → pre-fill/merge ReportDynamicIndicator. | dynamicRegions đúng số dòng và thứ tự theo depth; sync đúng; 1 query indicators. |
| **B12 P7** | E2E FormConfig + SubmissionDataEntry; cập nhật B12, TONG_HOP. | E2E Pass; tài liệu đồng bộ. |
| **P8a** | DB DataSource, FilterDefinition, FilterCondition, FormPlaceholderOccurrence; API CRUD. | CRUD đủ; mỗi occurrence = ExcelRowStart + FormDynamicRegionId + FilterDefinitionId. |
| **P8b** | Parameter Context; resolve filter (whitelist, parameterized); query DataSource; build workbook mở rộng N hàng từ mỗi occurrence. | 2 vị trí 2 bộ lọc → đúng số hàng; sync đúng. |
| **P8c** | FE Nguồn dữ liệu, Bộ lọc; FormConfig block "Vị trí placeholder". | Cấu hình + build workbook đúng. |
| **P8d** | Test P8 (DataSource → FilterDefinition → 2 occurrence → build → sync). | Checklist Pass/Fail. |
| **P8e** | DB FormDynamicColumnRegion, FormPlaceholderColumnOccurrence; API; build workbook sinh N cột. | CRUD; build workbook cột động đúng. |
| **P8f** | FE Vùng cột động, Vị trí placeholder cột; test. | Cấu hình + build cột động đúng. |

---

## 4. Chi tiết từng phần cần làm (DB/BE/FE/Test)

### 4.1. B12 P2a

| Loại | Nội dung |
|------|----------|
| DB | FormRow.ParentId (nếu chưa có script 20). Index (FormSheetId, ParentId, DisplayOrder) FormColumn, FormRow. |
| BE | GET columns?tree=true, GET rows?tree=true; POST/PUT column/row nhận parentId. |
| FE | FormConfig: Cột/Hàng dạng cây (Tree/nested), Thêm cột/hàng con; FormRow gắn FormDynamicRegionId (dropdown). |
| Test | GET tree đúng cấu trúc; FE expand/collapse, thêm con; merge header vẫn đúng. |

### 4.2. B12 P4 mở rộng

| Loại | Nội dung |
|------|----------|
| BE | Với FormDynamicRegion có IndicatorCatalogId: query BCDT_Indicator (catalog) 1 lần → build cây → cắt depth (1/2/3/0) → danh sách flat. Pre-fill hoặc merge với ReportDynamicIndicator. Duyệt hàng theo FormRow khi có (sau P2a). |
| Test | Form 1 vùng + catalog + depth=2 → build workbook có số dòng = số chỉ tiêu đến depth 2; sync đúng. |

### 4.3. B12 P7

| Loại | Nội dung |
|------|----------|
| Test E2E | FormStructureAdmin → CRUD vùng chỉ tiêu động; user → submission → block Chỉ tiêu động → Lưu → GET dynamic-indicators đúng. (P2a: thêm cấu hình cây cột/hàng.) |
| Tài liệu | Cập nhật B12, TONG_HOP mục 2/4/8 khi phase xong. |

### 4.4. P8a

| Loại | Nội dung |
|------|----------|
| DB | BCDT_DataSource, BCDT_FilterDefinition, BCDT_FilterCondition, BCDT_FormPlaceholderOccurrence. Index FilterCondition(FilterDefinitionId), FormPlaceholderOccurrence(FormSheetId, DisplayOrder). |
| BE | Entity + CRUD data-sources, filter-definitions (kèm conditions), placeholder-occurrences; GET data-sources/{id}/columns. |
| Test | Tạo DataSource, FilterDefinition (2 conditions), 2 FormPlaceholderOccurrence; GET placeholder-occurrences đúng. |

### 4.5. P8b

| Loại | Nội dung |
|------|----------|
| BE | Parameter Context từ submission; resolve FilterDefinition → WHERE (whitelist cột, parameterized); query DataSource; build workbook: mỗi FormPlaceholderOccurrence → resolve → query → N hàng từ ExcelRowStart; merge ReportDynamicIndicator. MaxRows. |
| Test | 2 vị trí placeholder, 2 bộ lọc → số hàng N, M đúng; sync đúng. |

### 4.6. P8c

| Loại | Nội dung |
|------|----------|
| FE | Trang/modal Nguồn dữ liệu (CRUD DataSource); Trang/modal Bộ lọc (FilterDefinition + điều kiện); FormConfig block "Vị trí placeholder" (ExcelRowStart, Định nghĩa, Bộ lọc, MaxRows). Optional: GET prefill. |
| Test | Cấu hình 2 vị trí + 2 bộ lọc; build workbook đúng. |

### 4.7. P8d

| Loại | Nội dung |
|------|----------|
| Test | Checklist P8: DataSource → 2 FilterDefinition → 2 occurrence → build → sync; Pass/Fail; Postman. |

### 4.8. P8e

| Loại | Nội dung |
|------|----------|
| DB | BCDT_FormDynamicColumnRegion, BCDT_FormPlaceholderColumnOccurrence. Index (FormSheetId, DisplayOrder). |
| BE | Entity + CRUD dynamic-column-regions, placeholder-column-occurrences; resolve nguồn cột (ByReportingPeriod/ByCatalog/ByDataSource + filter); build workbook sinh N cột tại ExcelColStart. MaxColumns. |
| Test | 1 định nghĩa cột động + 1 vị trí → build workbook cột động đúng. |

### 4.9. P8f

| Loại | Nội dung |
|------|----------|
| FE | FormConfig block "Vùng cột động" (định nghĩa), block "Vị trí placeholder cột" (ExcelColStart, Định nghĩa, Bộ lọc). |
| Test | Cấu hình + build workbook cột động đúng. |

---

## 5. Rủi ro hiệu năng và biện pháp

| Rủi ro | Biện pháp |
|--------|-----------|
| Build workbook chậm | Cache cấu trúc form theo FormId, TTL ngắn; invalidation khi PUT form. |
| Query nguồn trả quá nhiều bản ghi | MaxRows/MaxColumns; pagination nội bộ. |
| N+1 indicators | Một query theo catalog; build cây trong memory; cắt depth trong code. |
| Filter WHERE không an toàn | Whitelist cột từ DataSource; parameterized; không nối chuỗi SQL từ user. |
| Sync nhiều vùng | Đọc WorkbookJson một lần; batch insert/update/delete ReportDynamicIndicator trong transaction. |

---

## 6. Checklist nghiệm thu (đúng đủ nghiệp vụ + hiệu năng)

### 6.1. Nghiệp vụ

- [ ] B12: Phân cấp cột (colspan) đã dùng; phân cấp hàng (FormRow.ParentId) + API tree + FE cây (P2a).
- [ ] B12: IndicatorExpandDepth → build workbook sinh dòng theo cây chỉ tiêu cắt đúng depth (P4 mở rộng).
- [ ] P8: Mỗi vị trí placeholder dòng = ExcelRowStart + FormDynamicRegionId + FilterDefinitionId; build → N hàng (P8b).
- [ ] P8: Mỗi vị trí placeholder cột = ExcelColStart + FormDynamicColumnRegionId + FilterDefinitionId; build → N cột (P8e).
- [ ] Sync: Sau build có placeholder mở rộng, sync vẫn map đúng ReportDynamicIndicator và dữ liệu ô cột động.

### 6.2. Hiệu năng

- [ ] Index: FormColumn, FormRow (FormSheetId, ParentId, DisplayOrder); ReportDynamicIndicator (SubmissionId, FormDynamicRegionId); FormPlaceholderOccurrence, FormPlaceholderColumnOccurrence (FormSheetId, DisplayOrder); FilterCondition (FilterDefinitionId).
- [ ] Build workbook: không N+1; filter parameterized + whitelist cột; MaxRows/MaxColumns.

---

## 7. Tham chiếu và Cách giao AI

| Mục | Nội dung |
|-----|----------|
| **Thiết kế** | [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md), [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md). |
| **Checklist 7.1 B12** | [B12_CHI_TIEU_CO_DINH_DONG.md](B12_CHI_TIEU_CO_DINH_DONG.md) (giữ checklist và test cases tại đó). |
| **Tiến độ tổng thể dự án** | [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md). |
| **Cách giao AI** | **Chỉ tại** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) **mục 3.3, 3.5 hoặc 3.7**: block "B12 P2a", "B12 P4 mở rộng", "P8". Agent: bcdt-form-structure-indicators. Skill: bcdt-form-structure, bcdt-entity-crud, bcdt-hierarchical-tree. |

---

## 8. Đối chiếu nguồn (đã gộp 2026-02-06)

| Nội dung trong KE_HOACH_ | Nguồn gốc (file đã chuyển thành redirect) |
|--------------------------|-------------------------------------------|
| Mục 1 – Tổng quan, ý nghĩa vùng chỉ tiêu động | RÀ_SOÁT_VÙNG_CHỈ_TIÊU_ĐỘNG_VÀ_CỘT_HÀNG_ĐỘNG (định nghĩa, đã/chưa). |
| Mục 2 – Trạng thái đã/chưa làm | RA_SOAT_DANH_GIA_VA_KE_HOACH_CHI_TIET (1.1, 1.2), B12 bảng phase. |
| Mục 3 – Thứ tự triển khai, phụ thuộc, bảng kế hoạch | DE_XUAT_TRIEN_KHAI_MO_RONG_CAU_HINH_BIEU_MAU (bảng thứ tự, chi tiết 2.1–2.9), RA_SOAT (phụ thuộc, tiêu chí nghiệm thu). |
| Mục 4 – Chi tiết từng phần (4.1–4.9) | DE_XUAT (DB/BE/FE/Test từng phase). |
| Mục 5 – Rủi ro hiệu năng | RA_SOAT (phần hiệu năng). |
| Mục 6 – Checklist nghiệm thu | RA_SOAT, DE_XUAT (tiêu chí nghiệm thu). |

Các file RA_SOAT_DANH_GIA_VA_KE_HOACH_CHI_TIET, DE_XUAT_TRIEN_KHAI_MO_RONG_CAU_HINH_BIEU_MAU, RÀ_SOÁT_VÙNG_CHỈ_TIÊU_ĐỘNG_VÀ_CỘT_HÀNG_ĐỘNG hiện chỉ còn đoạn redirect tới file này.

**Version:** 1.1 · **Last updated:** 2026-02-06 · Thêm mục 8 đối chiếu nguồn; mục 1 bổ sung ExcelColName, ExcelColValue, MaxRows.
