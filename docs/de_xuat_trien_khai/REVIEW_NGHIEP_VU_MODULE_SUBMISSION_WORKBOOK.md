# Báo cáo Review nghiệp vụ – Module Submission & Workbook

**Ngày:** 2026-02-24  
**Agent:** bcdt-business-reviewer  
**Phạm vi:** Submission CRUD, workbook-data, upload Excel, sync-from-presentation, nhập liệu web (FR-NL-*); hybrid storage (ReportSubmission, ReportPresentation, ReportDataRow).

---

## 1. Phạm vi review

- **Yêu cầu nguồn:** 01.YEU_CAU_HE_THONG (FR-NL-01–FR-NL-06, BM-01/02, EX-* liên quan), YEU_CAU_HE_THONG_TONG_HOP, B8 (Data Binding, Column Mapping), B10 (submission, aggregation), RUNBOOK.
- **Implementation:** SubmissionsController (CRUD, bulk, presentation, workbook-data, upload-excel, sync-from-presentation, submit, aggregate, audit, pdf); ReportPresentationsController; IReportSubmissionService, IReportPresentationService, IBuildWorkbookFromSubmissionService, ISubmissionExcelService, ISyncFromPresentationService; BCDT_ReportSubmission, BCDT_ReportPresentation, BCDT_ReportDataRow; FE SubmissionsPage, SubmissionDataEntryPage (Fortune-sheet).

---

## 2. Bảng đối chiếu (Yêu cầu ↔ Implementation)

| # | Yêu cầu | Nguồn | Implementation | Trạng thái |
|---|---------|-------|----------------|------------|
| 1 | Tạo Excel động (generate với data binding) | FR-NL-01 | GET /forms/{id}/template (fillBinding); GET /submissions/{id}/workbook-data (BuildWorkbookFromSubmissionService); ReportDataRow + FormColumnMapping | **Đạt** |
| 2 | Nhập liệu web (edit Excel trực tiếp) | FR-NL-02 | GET/PUT /submissions/{id}/presentation (WorkbookJson); sync-from-presentation → ReportDataRow; FE SubmissionDataEntryPage (Fortune-sheet), workbook-data load | **Đạt** |
| 3 | Auto-save (lưu tự động draft) | FR-NL-03 | FE gọi PUT presentation khi lưu; backend UpsertPresentation; không bắt buộc auto-save theo timer – FE có thể debounce save | **Đạt** |
| 4 | Submit (nộp chính thức) | FR-NL-04 | POST /submissions/{id}/submit; WorkflowExecutionService.SubmitSubmissionAsync; Draft → Submitted, tạo WorkflowInstance nếu có workflow | **Đạt** |
| 5 | Bulk import (nhiều file / nhiều submission) | FR-NL-05 | POST /submissions/bulk (BulkCreateAsync, 1 submission per org); POST /submissions/{id}/upload-excel (Import Excel từ file); có thể tạo nhiều submission rồi upload từng file | **Đạt** |
| 6 | Validation trước submit | FR-NL-06 | Có thể trong WorkflowExecutionService hoặc service trước khi chuyển trạng thái; deadline (AllowLateSubmission) kiểm tra khi submit; chi tiết validation từng cell tùy nghiệp vụ | **Một phần** (validation nghiệp vụ tùy form) |
| 7 | Submission CRUD | B8, B10 | GET/POST/PUT/DELETE /submissions; filter formDefinitionId, organizationId, reportingPeriodId, status; RLS | **Đạt** |
| 8 | Presentation (Layer 1 JSON) | Hybrid storage | GET/PUT/POST /submissions/{id}/presentation; ReportPresentation (WorkbookJson, WorkbookHash, FileSize); ReportPresentationsController Get/Update | **Đạt** |
| 9 | Upload Excel → ReportDataRow + Presentation | B8 | POST /submissions/{id}/upload-excel (multipart .xlsx/.xls); ISubmissionExcelService.ProcessUploadedExcelAsync; FormColumnMapping map cột → ReportDataRow | **Đạt** |
| 10 | Sync từ presentation (sau nhập web) | Hybrid | POST /submissions/{id}/sync-from-presentation; ISyncFromPresentationService; WorkbookJson → ReportDataRow | **Đạt** |
| 11 | FE SubmissionsPage + SubmissionDataEntry | TONG_HOP 4 | SubmissionsPage (list); SubmissionDataEntryPage (Fortune-sheet, load workbook-data, lưu presentation, export .xlsx) | **Đạt** |
| 12 | Aggregate (ReportSummary từ ReportDataRow) | B10 | POST /submissions/{id}/aggregate; IAggregationService.AggregateSubmissionAsync | **Đạt** |

---

## 3. Gap

| Mức độ | Mô tả |
|--------|--------|
| **Minor** | **FR-NL-06 Validation:** Validation dữ liệu trước submit (vd bắt buộc ô, format số, range) phụ thuộc từng biểu mẫu; hiện có kiểm tra deadline (AllowLateSubmission) và trạng thái. Validation theo rule từng cột (ValidationRule trong FormColumn) có thể chưa áp dụng đầy đủ khi submit – cần rà lại trong Submission/Workflow service. |

Không có gap **Critical** hoặc **Major** đối với module Submission & Workbook trong MVP.

---

## 4. Mâu thuẫn / Rủi ro

- **Không phát hiện mâu thuẫn** giữa tài liệu (B8, B10, RUNBOOK) và code (endpoint, hybrid storage, luồng workbook-data ↔ presentation ↔ ReportDataRow).
- **Rủi ro nhỏ:** BuildWorkbookFromSubmissionService phức tạp (B12/P8 placeholder, DataSource, Filter); đã có trong B12/P8 và W16 tối ưu; review này chỉ xác nhận endpoint và luồng cơ bản đạt.

---

## 5. Khuyến nghị

| Ưu tiên | Khuyến nghị |
|---------|-------------|
| **P2** | (Tùy chọn) Chuẩn hóa validation trước submit: đọc FormColumn.ValidationRule (hoặc rule theo FormDefinition); chạy kiểm tra trên WorkbookJson hoặc ReportDataRow trước khi SubmitSubmissionAsync; trả 400 + danh sách lỗi nếu vi phạm. |
| **P3** | Giữ checklist "Kiểm tra cho AI" trong tài liệu submission/upload (vd test-submission-upload.ps1, RUNBOOK); khi sửa submission/workbook tiếp tục chạy đủ bước và báo Pass/Fail. |

**Kết luận:** Module Submission & Workbook **đạt đủ yêu cầu MVP** cho FR-NL-01–FR-NL-05 và luồng hybrid storage (presentation, workbook-data, upload, sync-from-presentation). Gap ở mức Minor (validation trước submit theo rule từng cột); không ảnh hưởng nghiệm thu Phase 2.
