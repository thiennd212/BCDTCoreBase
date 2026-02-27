---
task_ref: "Task 2.6 – FR-TH-02: Drill-down API ReportSummary → ReportDataRow"
agent_assignment: "Agent_Backend"
phase: "Phase_03_Sprint_2_Business_Gaps"
memory_log_path: ".apm/Memory/Phase_03_Sprint_2_Business_Gaps/Task_2_6_Drilldown_API.md"
execution_type: single-step
size: small
---

# Task 2.6 – Drill-down API: GET /report-summaries/{id}/details

## Bối cảnh

Gap FR-TH-02 từ `docs/de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_REPORTING_DASHBOARD_B10.md`:
Hiện chưa có endpoint riêng "drill từ ReportSummary xuống ReportDataRow detail". FE có thể ghép từ submission list + workbook-data nhưng cần 1 endpoint tiện hơn.

## Việc cần làm

1. Đọc các file liên quan để hiểu context:
   - `src/BCDT.Domain/Entities/Reporting/ReportSummary.cs`
   - `src/BCDT.Infrastructure/Services/ReportSummaryService.cs` (hoặc tương đương)
   - `src/BCDT.Api/Controllers/ApiV1/` – tìm controller liên quan ReportSummary

2. Thêm method `GetDetailsByIdAsync(int summaryId)` vào service (nếu chưa có):
   - Query `BCDT_ReportDataRow` WHERE ReportSummaryId = summaryId
   - Trả `Result<List<ReportDataRowDto>>`

3. Thêm endpoint vào controller:
   ```
   GET /api/v1/report-summaries/{id}/details
   [Authorize]
   → trả danh sách ReportDataRow của summary đó
   → NOT_FOUND nếu summary không tồn tại
   ```

4. Tạo `ReportDataRowDto` nếu chưa có (các field cơ bản: Id, RowKey, ColumnKey, Value, SubmissionId).

5. Tạo memory log tại `memory_log_path` ghi: files đã sửa/tạo, endpoint mới.

## Lưu ý

- Chỉ đọc và sửa file. Không chạy lệnh shell.
- Nếu cấu trúc thực tế khác description trên, điều chỉnh theo code hiện có.
