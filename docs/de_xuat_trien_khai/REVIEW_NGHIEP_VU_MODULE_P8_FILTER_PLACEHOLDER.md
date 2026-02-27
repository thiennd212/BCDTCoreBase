# Báo cáo Review nghiệp vụ – Module P8 (Lọc động, placeholder)

**Ngày:** 2026-02-24  
**Agent:** bcdt-business-reviewer  
**Phạm vi:** P8a–P8f – DataSource, FilterDefinition, FormPlaceholderOccurrence (dòng), FormDynamicColumnRegion, FormPlaceholderColumnOccurrence (cột); build workbook N hàng/N cột; FE FormConfig P8.

---

## 1. Phạm vi review

- **Yêu cầu nguồn:** P8_FILTER_PLACEHOLDER.md, GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md, KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md (mục 4.4–4.9).
- **Implementation:** DataSourcesController, FilterDefinitionsController, FormPlaceholderOccurrencesController, FormDynamicColumnRegionsController, FormPlaceholderColumnOccurrencesController; IDataSourceQueryService (QueryWithFilterAsync); BuildWorkbookFromSubmissionService (load occurrence, resolve filter, N hàng/N cột); bảng BCDT_DataSource, BCDT_FilterDefinition, BCDT_FilterCondition, BCDT_FormPlaceholderOccurrence, BCDT_FormDynamicColumnRegion, BCDT_FormPlaceholderColumnOccurrence; FE FormConfig (card Nguồn dữ liệu, Bộ lọc, Vị trí placeholder; Vùng cột động, Vị trí placeholder cột).

---

## 2. Bảng đối chiếu (P8a–P8f ↔ Implementation)

| # | Yêu cầu | Nguồn | Implementation | Trạng thái |
|---|---------|-------|----------------|------------|
| 1 | P8a – DB: DataSource, FilterDefinition, FilterCondition, FormPlaceholderOccurrence | P8, 21.p8_filter_placeholder.sql | 4 bảng; script 21; Entity + DbSet | **Đạt** |
| 2 | P8a – API: CRUD data-sources, data-sources/{id}/columns | P8a | DataSourcesController: GET/POST, GET/PUT/DELETE/{id}, GET/{id}/columns; FormStructureAdmin trên POST/PUT/DELETE | **Đạt** |
| 3 | P8a – API: CRUD filter-definitions (kèm conditions) | P8a | FilterDefinitionsController: GET/POST, GET/PUT/DELETE/{id}; conditions trong body | **Đạt** |
| 4 | P8a – API: CRUD placeholder-occurrences (dòng) | P8a | FormPlaceholderOccurrencesController: GET/POST, GET/PUT/DELETE/{occurrenceId}; formId/sheetId trong route | **Đạt** |
| 5 | P8b – Resolve filter + Build workbook N hàng | P8b, GIAI_PHAP | ParameterContext (ReportDate, OrganizationId, …); IDataSourceQueryService.QueryWithFilterAsync; BuildWorkbookFromSubmissionService load FormPlaceholderOccurrence, QueryWithFilterAsync → N hàng; dynamicRegions với rows (indicatorName, indicatorValue) | **Đạt** |
| 6 | P8c – FE: Nguồn dữ liệu, Bộ lọc, Vị trí placeholder | P8c | FormConfig: 3 card P8; CRUD qua formDataSourceFilterApi; modal Mã/Tên, điều kiện, FormDynamicRegionId, ExcelRowStart, FilterDefinitionId, DataSourceId | **Đạt** |
| 7 | P8e – DB: FormDynamicColumnRegion, FormPlaceholderColumnOccurrence | P8e, 22.p8_column_placeholder.sql | 2 bảng; script 22; Entity | **Đạt** |
| 8 | P8e – API: CRUD dynamic-column-regions, placeholder-column-occurrences | P8e | FormDynamicColumnRegionsController, FormPlaceholderColumnOccurrencesController; GET/POST, GET/PUT/DELETE | **Đạt** |
| 9 | P8e – Build workbook N cột (dynamicColumnRegions) | P8e | Build workbook: resolve FormPlaceholderColumnOccurrence (ByReportingPeriod, ByDataSource, ByCatalog, Fixed) + FilterDefinition → columnLabels; sheets[].dynamicColumnRegions (excelColStart, columnLabels) | **Đạt** |
| 10 | P8f – FE: Vùng cột động, Vị trí placeholder cột | P8f | FormConfig: card "P8 – Vùng cột động", "P8 – Vị trí placeholder cột"; CRUD FormDynamicColumnRegion, FormPlaceholderColumnOccurrence | **Đạt** |
| 11 | Điều kiện lọc theo trường (Field, Operator, ValueType, Value); tham số (Parameter Context) | GIAI_PHAP | FilterCondition; ParameterContext; resolve khi build; whitelist cột, WHERE parameterized | **Đạt** |
| 12 | Một placeholder nhiều vị trí (occurrence), mỗi vị trí một FilterDefinition | GIAI_PHAP | FormPlaceholderOccurrence (FormDynamicRegionId, ExcelRowStart, FilterDefinitionId); FormPlaceholderColumnOccurrence (FormDynamicColumnRegionId, ExcelColStart, FilterDefinitionId) | **Đạt** |

---

## 3. Gap

| Mức độ | Mô tả |
|--------|--------|
| **Không có** | P8a–P8f đã triển khai đủ theo P8_FILTER_PLACEHOLDER.md và GIAI_PHAP: DB (21, 22), API CRUD 5 nhóm, ParameterContext + DataSourceQueryService, Build workbook N hàng + N cột, FE 5 card FormConfig. |

Không có gap **Critical**, **Major** hay **Minor** trong phạm vi P8 so với tài liệu P8 và GIAI_PHAP.

---

## 4. Mâu thuẫn / Rủi ro

- **Không phát hiện mâu thuẫn** giữa P8_FILTER_PLACEHOLDER, GIAI_PHAP_LOC_DONG và code (API, service, build workbook).
- **Rủi ro nhỏ:** Build workbook phụ thuộc thứ tự occurrence (ExcelRowStart) và merge với ReportDynamicIndicator; test với nhiều occurrence và nhiều sheet giúp tránh lỗi biên.

---

## 5. Khuyến nghị

| Ưu tiên | Khuyến nghị |
|---------|-------------|
| **P3** | Giữ checklist P8a (4–10), P8b, P8c, P8e, P8f trong P8_FILTER_PLACEHOLDER.md; khi sửa P8 (filter, placeholder, build) chạy test-p8-checklist-4-10.ps1 và kiểm tra workbook-data dynamicRegions/dynamicColumnRegions; báo Pass/Fail từng bước. |

**Kết luận:** Module P8 (Lọc động, placeholder dòng + cột) **đạt đủ yêu cầu** P8a–P8f. Không có gap so với đặc tả; có thể đánh dấu review P8 hoàn tất. **Toàn bộ 8 module review nghiệp vụ đã xong** (Auth, Org/User, Form B7–B8, Submission & Workbook, Workflow B9, Reporting & Dashboard B10, B12, P8).
