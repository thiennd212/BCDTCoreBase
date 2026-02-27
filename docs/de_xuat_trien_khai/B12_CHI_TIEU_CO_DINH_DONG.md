# B12 – Chỉ tiêu cố định & Chỉ tiêu động (R1–R11)

Đề xuất triển khai mở rộng **Cấu trúc biểu mẫu – Chỉ tiêu cố định & Chỉ tiêu động** theo [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md).

**Phạm vi:** R1–R11 (Authorization, FormDynamicRegion, ReportDynamicIndicator, BCDT_IndicatorCatalog, BCDT_Indicator, FormColumn/FormRow phân cấp, merge header, IndicatorExpandDepth, API, FE).

---

## 1. Trạng thái phase và kế hoạch (một nguồn)

**Trạng thái từng phase (P1–P7) và kế hoạch B12 + P8:** xem **[KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md)** (mục 2, 3, 4). Tài liệu này (B12) giữ **checklist 7.1** và **test cases** bên dưới; không nhân bản bảng phase tại đây.

---

## 2. Tham chiếu giải pháp

- **Data model:** GIAI_PHAP mục 4.2 (FormDynamicRegion, ReportDynamicIndicator), 4.6.1 (BCDT_Indicator), 4.7.1 (BCDT_IndicatorCatalog), 4.8 (FormColumn.ParentId, FormRow).
- **API:** GIAI_PHAP mục 4.3, 4.6.3, 4.7.5.
- **Build workbook:** GIAI_PHAP mục 4.4.

---

## 3. Deliverable theo phase

### P1 – Authorization
- Policy `FormStructureAdmin` (RequireRole SYSTEM_ADMIN, FORM_ADMIN).
- [Authorize(Policy = "FormStructureAdmin")] trên POST, PUT, DELETE của: FormDefinitionsController, FormSheetsController, FormColumnsController, FormColumnDataBindingController, FormColumnMappingController.
- GET giữ [Authorize] (đã đăng nhập).

### P2 – DB
- Script SQL: tạo BCDT_IndicatorCatalog, BCDT_Indicator (ParentId, IndicatorCatalogId), BCDT_FormDynamicRegion (IndicatorExpandDepth, IndicatorCatalogId), BCDT_ReportDynamicIndicator (IndicatorId).
- ALTER BCDT_FormColumn ADD ParentId, IndicatorId; ALTER BCDT_FormRow ADD FormDynamicRegionId.

### P3 – API
- CRUD /api/v1/forms/{formId}/sheets/{sheetId}/dynamic-regions.
- GET/PUT /api/v1/submissions/{id}/dynamic-indicators.
- (P1b) CRUD /api/v1/indicator-catalogs, /api/v1/indicators (tree=true, catalogId, parentId).

### P4 – Build workbook & Sync
- Build workbook: thứ tự cấu hình (FormColumn/FormRow tree) → chỉ tiêu động (theo IndicatorExpandDepth); merge header cột (colspan = số lá).
- Sync từ presentation: vùng placeholder → ReportDynamicIndicator.

### P5–P6 – FE
- FormConfigPage: block "Vùng chỉ tiêu động", chọn danh mục, độ sâu đệ quy.
- SubmissionDataEntryPage: vùng placeholder – TreeSelect chỉ tiêu, PUT dynamic-indicators.

---

## 4. Kiểm tra cho AI (7.1 – Checklist tối thiểu)

Chạy **đủ** các bước sau trước khi báo xong. Báo **Pass** hoặc **Fail** từng bước.

| # | Bước | Hành động | Kỳ vọng |
|---|------|-----------|---------|
| 1 | Build BE | Hủy process BCDT.Api (RUNBOOK 6.1). `dotnet build src/BCDT.Api/BCDT.Api.csproj` | Build succeeded. |
| 2 | P1 – Policy | Gọi POST /api/v1/forms (tạo biểu mẫu) với token user **không** có SYSTEM_ADMIN/FORM_ADMIN | 403 Forbidden. |
| 3 | P1 – Policy | Gọi POST /api/v1/forms với token user **có** SYSTEM_ADMIN | 200 hoặc 201 (hoặc 400/409 theo nghiệp vụ). |
| 4 | P2 – DB | Chạy script migration (20.chi_tieu_co_dinh_dong.sql). Query `SELECT name FROM sys.tables WHERE name IN ('BCDT_FormDynamicRegion','BCDT_ReportDynamicIndicator','BCDT_IndicatorCatalog','BCDT_Indicator')` | Trả đủ 4 bảng. |
| 5 | P2 – Cột mới | Query `SELECT COLUMN_NAME FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='BCDT_FormColumn' AND COLUMN_NAME IN ('ParentId','IndicatorId')` | 2 dòng. |
| 5b | P2a – Rows API | GET /api/v1/forms/{formId}/sheets/{sheetId}/rows (formId, sheetId hợp lệ) | 200, data array (có thể rỗng). |
| 5c | P2a – Rows tree | GET .../rows?tree=true | 200, array (cây: mỗi phần tử có Children). |
| 5d | P2a – Columns tree | GET .../columns?tree=true | 200, array (cây: mỗi phần tử có Children). |
| 5e | P2a – POST row | POST .../rows, body { RowCode, RowName, ExcelRowStart, RowType, DisplayOrder } (FormStructureAdmin) | 201, trả row với Id, ParentId. |
| 5f | P2a – POST column ParentId | POST .../columns, body có ParentId (nullable), IndicatorId (nullable) (FormStructureAdmin) | 200/201, trả column có ParentId, IndicatorId. |
| 5g | P2a – Script test | Đảm bảo API chạy (http://localhost:5080). Chạy `.\docs\script_core\test-b12-p2a-checklist.ps1` | Tất cả bước trong script báo Pass. |
| 5h | P2a – FE FormConfig cây | Vào Cấu hình biểu mẫu → chọn sheet: block "Cột (dạng cây)" hiển thị cây; Thêm/Sửa cột có "Cột cha"; block "Hàng (Form Row – dạng cây)" có bảng cây, Thêm/Sửa hàng có "Hàng cha", "Vùng chỉ tiêu động". | Cột/hàng hiển thị phân cấp; Modal có TreeSelect cha; Build FE Pass. |
| 6 | P3 – Dynamic regions | GET /api/v1/forms/{formId}/sheets/{sheetId}/dynamic-regions (sau khi có API) | 200, data array. |
| 7 | P3 – Dynamic indicators | GET /api/v1/submissions/{id}/dynamic-indicators (sau khi có API) | 200, data array (hoặc empty). |
| 8 | Postman | Validate JSON: `Get-Content docs/postman/BCDT-API.postman_collection.json -Raw -Encoding UTF8 \| ConvertFrom-Json` | Không lỗi parse. |
| 9 | P4 – Build workbook | GET /api/v1/submissions/{id}/workbook-data; response.sheets[].columnHeaders (colspan), sheets[].dynamicRegions (rows) | 200; có columnHeaders khi có cột; có dynamicRegions khi sheet có vùng và có dữ liệu. |
| 9b | **P4 mở rộng** – Catalog + depth | Vùng có IndicatorCatalogId + IndicatorExpandDepth; GET workbook-data → dynamicRegions[].rows thứ tự theo cây chỉ tiêu (gốc→con→cháu), cắt đúng depth; pre-fill khi chưa có ReportDynamicIndicator, merge thứ tự khi đã có; 1 query indicators theo catalog (tránh N+1). | Số dòng và thứ tự đúng theo GIAI_PHAP 4.8.3; build Pass. |
| 10 | P4 – Sync | PUT presentation (WorkbookJson có vùng placeholder), gọi sync (upload/sync); GET dynamic-indicators | Sync ghi đúng ReportDynamicIndicator theo vùng. |
| 11 | P5 – FormConfig | Vào Cấu hình biểu mẫu → chọn sheet → block "Vùng chỉ tiêu động": Thêm/Sửa/Xóa vùng (ExcelRowStart, ExcelColName, ExcelColValue, MaxRows, IndicatorExpandDepth, IndicatorCatalogId). | Hiển thị bảng vùng; Modal Thêm/Sửa; Xóa có xác nhận. |
| 12 | P6 – SubmissionDataEntry | Trang nhập liệu báo cáo (submission Draft/Revision) có ít nhất một vùng chỉ tiêu động: block "Chỉ tiêu động", bảng Tên chỉ tiêu / Giá trị, Thêm dòng, Lưu chỉ tiêu động. | PUT dynamic-indicators; sau lưu GET dynamic-indicators trả đúng. |
| 13 | **P7 – E2E** | Đảm bảo API chạy (http://localhost:5080). Trong `src/bcdt-web`: `npm run test:e2e` (hoặc `npx playwright test e2e/b12-p7-formconfig-submission.spec.ts`). | P7.1 Pass: FormConfig → chọn sheet → card "Vùng chỉ tiêu động" + nút "Thêm vùng". P7.2 Pass: SubmissionDataEntry → trang entry load, nút "Lưu" hiển thị. |

**Lưu ý:** Khi triển khai từng phase, chỉ chạy các bước áp dụng cho phase đó; khi toàn bộ xong chạy đủ 1–13.

### Dữ liệu test cho P2a (API + FE)

- **API:** Đảm bảo API chạy (http://localhost:5080). Chạy `.\docs\script_core\test-b12-p2a-checklist.ps1` → script tự tạo form/sheet (hoặc dùng form đầu tiên), thêm rows và columns có phân cấp (ParentId). Mỗi lần chạy dùng mã cột/hàng có suffix thời gian nên không bị CONFLICT khi chạy lại.
- **FE:** Sau khi chạy script (hoặc đã có form có sheet có ít nhất 1 cột/1 hàng): đăng nhập FE (admin/Admin@123) → Biểu mẫu → chọn một biểu mẫu → Cấu hình → chọn một sheet → kiểm tra block **Cột (dạng cây)** và **Hàng (Form Row – dạng cây)**; Thêm cột / Thêm hàng → Modal có **Cột cha** / **Hàng cha** (TreeSelect), **Vùng chỉ tiêu động** (hàng).

### Dữ liệu test cho P4 mở rộng (workbook-data pre-fill/merge)

- **Seed:** Chạy script `docs/script_core/sql/v2/seed_b12_p4_workbook_dynamic.sql` (sau 01–14, 20; cần đã có form+sheet, vd đã chạy seed_mcp_1). Script tạo: danh mục DM_P4_TEST, cây chỉ tiêu (gốc → con 1, con 2 → cháu dưới con 1), 1 FormDynamicRegion gắn catalog + IndicatorExpandDepth=3 trên sheet đầu tiên (ưu tiên form TEST_EXCEL_ENTRY). Hoặc chạy `Ensure-TestData.ps1` (sẽ chạy seed B12 P4 nếu chưa có DM_P4_TEST).
- **Tự test:** Đảm bảo API chạy (http://localhost:5080). Chạy `.\docs\script_core\test-b12-p4-workbook-dynamic.ps1`. Kỳ vọng: bước 1–5 Pass; 6. GET workbook-data (pre-fill) Pass (4 dòng, thứ tự gốc→con1→cháu→con2); 7. PUT dynamic-indicators Pass; 8. GET workbook-data (merge) Pass (thứ tự + giá trị 100,200,300,400).

---

## 5. Test cases (Happy path & Edge)

| ID | Mô tả | Request / Hành động | Kỳ vọng |
|----|--------|----------------------|---------|
| TC-01 | GET dynamic-regions (có quyền) | GET /api/v1/forms/1/sheets/1/dynamic-regions, Bearer token | 200, [ ]. |
| TC-02 | POST dynamic-region (System Admin) | POST .../dynamic-regions, body { ExcelRowStart, ExcelColName, ExcelColValue, MaxRows, IndicatorExpandDepth } | 201, region id. |
| TC-03 | GET dynamic-indicators (submission của đơn vị user) | GET /api/v1/submissions/{id}/dynamic-indicators | 200, [ ]. |
| TC-04 | PUT dynamic-indicators (batch) | PUT .../dynamic-indicators, body [{ FormDynamicRegionId, RowOrder, IndicatorName, IndicatorValue }] | 200. |
| TC-05 | POST form structure (user không phải FormStructureAdmin) | POST /api/v1/forms với token DATA_ENTRY | 403. |
| TC-06 | GET rows (flat) | GET /api/v1/forms/1/sheets/1/rows, Bearer | 200, [ ]. |
| TC-07 | GET rows (tree) | GET .../rows?tree=true | 200, [ ] hoặc cây (Children). |
| TC-08 | POST row (FormStructureAdmin) | POST .../rows, { RowCode: "R1", RowName: "Hàng 1", ExcelRowStart: 5, RowType: "Data", DisplayOrder: 0 } | 201, Id, ParentId. |
| TC-09 | GET columns (tree) | GET .../columns?tree=true | 200, array (cây). |
| TC-10 | POST column với ParentId | POST .../columns với ParentId (id cột cha hợp lệ) | 200/201, column.ParentId đúng. |
| TC-11 | **P4 mở rộng** – Pre-fill từ catalog | FormDynamicRegion có IndicatorCatalogId, catalog có chỉ tiêu cây (ParentId, DisplayOrder); submission chưa có ReportDynamicIndicator; GET /api/v1/submissions/{id}/workbook-data | 200; dynamicRegions[0].rows = danh sách theo cây (gốc→con→cháu), cắt theo IndicatorExpandDepth; IndicatorName từ BCDT_Indicator. |
| TC-12 | **P4 mở rộng** – Merge thứ tự | Cùng setup TC-11; đã có ReportDynamicIndicator (IndicatorId khớp catalog); GET workbook-data | 200; rows thứ tự theo catalog; giá trị giữ từ ReportDynamicIndicator. |
| TC-13 | **P7 – E2E** FormConfig + SubmissionDataEntry | Trong `src/bcdt-web`: `npm run test:e2e` (hoặc `npx playwright test e2e/b12-p7-formconfig-submission.spec.ts`). API http://localhost:5080 đang chạy. | P7.1 Pass: FormConfig → chọn sheet → card "Vùng chỉ tiêu động" + nút "Thêm vùng". P7.2 Pass: SubmissionDataEntry → trang entry load, nút "Lưu" hiển thị. |

---

## 6. Tham chiếu

- [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md)
- [RUNBOOK.md](../RUNBOOK.md) mục 6.1
- [B2_RBAC.md](B2_RBAC.md) – Role, policy
- **Trạng thái + Kế hoạch (B12 P2a/P4/P7 + P8):** [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md). **Cách giao AI:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) mục 3.3, 3.5 hoặc 3.7 (block B12 P2a, P4 mở rộng, P7, P8).

---

**Version:** 1.6 · **Last updated:** 2026-02-09 · Phase/trạng thái gốc tại KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG; B12 giữ checklist 7.1 (bước 13 P7 E2E), test cases (TC-13).
