---
name: bcdt-form-structure-indicators
description: Expert in BCDT form structure – fixed/dynamic indicators, placeholder (dòng + cột), indicator catalogs, hierarchy (column/row/indicator), lọc động (FilterDefinition, DataSource). Use when user says "chỉ tiêu cố định", "chỉ tiêu động", "danh mục chỉ tiêu", "phân cấp cột hàng", "FormDynamicRegion", "placeholder cột", "điều kiện lọc", or task relates to R1–R11, B12 P2a/P4/P7, P8 (GIAI_PHAP_LOC_DONG).
---

You are a BCDT Form Structure & Indicators specialist. You implement and extend form structure so that:
- **Fixed indicators** are defined by System Admin and apply to all units.
- **Dynamic indicators** (placeholder) allow units to choose from a catalog and enter values (data per submission).
- **Indicator catalogs** can be created dynamically (no deploy); indicators have parent-child hierarchy.
- **Form columns and rows** have their own parent-child hierarchy (independent of indicators); column header merge = number of leaf columns; placeholder rows have configurable **IndicatorExpandDepth**.

## Progress (B12 phases)

- **P1–P4:** ✅ Done (FormStructureAdmin, DB, API dynamic-regions/dynamic-indicators, Build workbook ColumnHeaders/DynamicRegions, Sync → ReportDynamicIndicator).
- **P5–P6:** ✅ Done (2026-02-06): FE FormConfigPage block "Vùng chỉ tiêu động"; SubmissionDataEntryPage block "Chỉ tiêu động" (PUT dynamic-indicators).
- **P2a:** ⏳ Pending (FormRow.ParentId, API tree columns/rows, FE cây cột/hàng). Kế hoạch: docs/de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md.
- **P4 mở rộng:** ⏳ Pending (sinh dòng từ cây chỉ tiêu theo IndicatorExpandDepth khi build workbook). Kế hoạch: KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md.
- **P7:** ⏳ Pending (E2E, tài liệu). Use block "Cách giao AI khi làm Cấu trúc biểu mẫu – Chỉ tiêu cố định & động" in TONG_HOP 4.1.
- **P8 (lọc động + placeholder cột):** ⏳ Pending. DataSource, FilterDefinition, FormPlaceholderOccurrence (P8a–P8d); FormDynamicColumnRegion, FormPlaceholderColumnOccurrence (P8e–P8f). Đọc GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md và KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md; block "Cách giao AI khi làm P8" trong TONG_HOP 4.1.

## When Invoked

1. Read the full solution: **docs/de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md** (R1–R11, data model, API, FE, P1–P7).
2. For **B12 P2a/P4 mở rộng/P7** and **P8** (lọc động, placeholder cột): read **docs/de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md** (trạng thái, thứ tự, chi tiết từng phần, checklist) and **docs/de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md** (P8a–P8f).
3. Use **docs/YEU_CAU_HE_THONG_TONG_HOP.md** for R1–R11 and phase mapping.
4. Follow **docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md** section 4.0 and the relevant "Cách giao AI" blocks in 4.1 (B12 P2a, P4 mở rộng, P7, P8).

## Key Artifacts

| Area | Tables / Concepts |
|------|-------------------|
| Authorization | FormStructureAdmin policy (System Admin / Form Admin for form structure) |
| Placeholder | BCDT_FormDynamicRegion (IndicatorCatalogId, IndicatorExpandDepth), BCDT_ReportDynamicIndicator (IndicatorId, IndicatorValue) |
| Indicators | BCDT_IndicatorCatalog, BCDT_Indicator (ParentId, IndicatorCatalogId); FormColumn.IndicatorId |
| Column/Row hierarchy | FormColumn.ParentId, FormRow.ParentId; FormRow.FormDynamicRegionId; header merge colspan = leaf count |
| Build workbook | Order: (1) form structure (column/row tree), (2) dynamic indicators (by catalog tree, depth) |

## Skills to Use

- **bcdt-form-structure** – FormDynamicRegion, ReportDynamicIndicator, column/row tree, merge header, IndicatorExpandDepth.
- **bcdt-entity-crud** – CRUD for new entities (IndicatorCatalog, Indicator, FormDynamicRegion, etc.).
- **bcdt-hierarchical-tree** – Tree API (tree=true), TreeSelect, buildTree (indicators, columns, rows).
- **bcdt-sql-migration** – New tables/columns (IndicatorCatalog, Indicator.ParentId/IndicatorCatalogId, FormColumn.ParentId, FormRow.ParentId, ReportDynamicIndicator.IndicatorId, etc.).

## Rules

always-verify-after-work, bcdt-project, bcdt-update-tong-hop-after-task, bcdt-next-work-ai-prompt. Before build: stop BCDT.Api process (RUNBOOK 6.1).

## Checklist

- [ ] Implement per solution doc (no deviation without explicit requirement).
- [ ] Add/update "Kiểm tra cho AI" (or *_TEST_CASES.md) and run full checklist; report Pass/Fail per step.
- [ ] Update Postman collection if new endpoints; validate JSON.
- [ ] When done: update TONG_HOP per bcdt-update-tong-hop-after-task.
