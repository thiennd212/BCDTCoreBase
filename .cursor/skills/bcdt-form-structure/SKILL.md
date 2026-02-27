---
name: bcdt-form-structure
description: Implement form structure extensions – FormDynamicRegion, ReportDynamicIndicator, FormColumn/FormRow hierarchy (ParentId), header merge, IndicatorExpandDepth, build order; lọc động (DataSource, FilterDefinition, FormPlaceholderOccurrence); placeholder cột (FormDynamicColumnRegion, FormPlaceholderColumnOccurrence). Use when user says "vùng chỉ tiêu động", "placeholder", "merge header cột", "độ sâu đệ quy", "điều kiện lọc", "placeholder cột", or implements R1–R11, B12 P2a/P4/P8.
---

# BCDT Form Structure (Chỉ tiêu cố định & động, phân cấp cột/hàng)

Implement and extend form structure for **fixed indicators**, **dynamic indicators (placeholder)**, and **column/row hierarchy** per solution doc.

## When to Use

- Adding **BCDT_FormDynamicRegion** (placeholder region: ExcelRowStart/End, ExcelColName/Value, MaxRows, **IndicatorCatalogId**, **IndicatorExpandDepth**).
- Adding **BCDT_ReportDynamicIndicator** (SubmissionId, FormDynamicRegionId, RowOrder, IndicatorName/Value, **IndicatorId**).
- Adding **FormColumn.ParentId**, **FormRow.ParentId** (self-FK); **FormRow.FormDynamicRegionId** (optional).
- Implementing **merge header** for columns: when building Excel, parent column header colspan = number of leaf columns under it.
- Implementing **IndicatorExpandDepth**: when building placeholder rows, expand indicator tree from catalog up to depth (1=root only, 2=root+children, 3=root+children+grandchildren, 0=unlimited).
- **Build workbook order:** (1) Apply form structure column/row tree and merge; (2) Apply dynamic indicators by catalog tree and depth.

## Reference

- **Full solution:** docs/de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md (sections 4.2, 4.4, 4.8; phases P2, P2a, P4).
- **Lọc động + placeholder cột:** docs/de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md (DataSource, FilterDefinition, FormPlaceholderOccurrence, FormDynamicColumnRegion, FormPlaceholderColumnOccurrence; P8a–P8f).
- **Kế hoạch chi tiết (P2a, P4 mở rộng, P7, P8):** docs/de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md (trạng thái, thứ tự, chi tiết, checklist).
- **Requirements:** R4, R5, R11; G2, G3, G4, G5, G10.

## Inputs / Outputs

| Input | Output |
|-------|--------|
| FormSheetId, region bounds, catalog, depth | BCDT_FormDynamicRegion rows; API CRUD dynamic-regions |
| SubmissionId, list of { regionId, rowOrder, indicatorId/Name, value } | BCDT_ReportDynamicIndicator; API GET/PUT submissions/{id}/dynamic-indicators |
| FormColumn/FormRow with ParentId | Tree API (GET columns/rows?tree=true); build Excel with merge and row order |
| FormDynamicRegion.IndicatorExpandDepth + catalog Id | Flat list of indicators (tree cut at depth) for placeholder rows |

## Conventions

- Tables: `BCDT_` prefix. API: `/api/v1/forms/{id}/sheets/{sheetId}/dynamic-regions`, `/api/v1/submissions/{id}/dynamic-indicators`.
- Use **bcdt-hierarchical-tree** for building tree (buildTree, tree=true) and TreeSelect when selecting indicators or columns/rows.
- Use **bcdt-entity-crud** for CRUD entities; **bcdt-sql-migration** for new tables/columns.

## Implemented (B12 P5–P6, 2026-02-06)

- **FormConfigPage:** Card "Vùng chỉ tiêu động" when a sheet is selected; list/create/update/delete dynamic-regions; Modal: ExcelRowStart, ExcelRowEnd, ExcelColName, ExcelColValue, MaxRows, IndicatorExpandDepth, IndicatorCatalogId, DisplayOrder.
- **SubmissionDataEntryPage:** Card "Chỉ tiêu động" with table (Tên chỉ tiêu / Giá trị) per region; PUT submissions/{id}/dynamic-indicators; TreeSelect khi vùng gắn catalog.

## Pending (B12 P2a, P4 mở rộng, P8)

- **P2a:** API GET columns/rows?tree=true, POST/PUT parentId; FE cây cột/hàng; FormRow.ParentId, FormRow.FormDynamicRegionId.
- **P4 mở rộng:** Build workbook – sinh dòng từ cây BCDT_Indicator (catalog) theo IndicatorExpandDepth khi chưa có ReportDynamicIndicator.
- **P8:** DataSource, FilterDefinition, FormPlaceholderOccurrence (dòng + điều kiện lọc); FormDynamicColumnRegion, FormPlaceholderColumnOccurrence (cột + điều kiện). Xem GIAI_PHAP_LOC_DONG và KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.
