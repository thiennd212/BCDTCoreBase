---
task_ref: "Task 2.7 – FR-TH-03: Export Aggregated Report Endpoint"
agent_assignment: "Agent_Backend"
phase: "Phase_03_Sprint_2_Business_Gaps"
memory_log_path: ".apm/Memory/Phase_03_Sprint_2_Business_Gaps/Task_2_7_Export_Aggregated.md"
execution_type: single-step
size: medium
---

# Task 2.7 – Export Aggregated Report: GET /report-summaries/{periodId}/export

## Bối cảnh

Gap FR-TH-03 từ `docs/de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_REPORTING_DASHBOARD_B10.md`:
Hiện export workbook/submission đơn lẻ có, nhưng chưa có endpoint export "báo cáo tổng hợp" (nhiều đơn vị, một kỳ báo cáo) thành một file.

## Việc cần làm

1. Đọc các file liên quan:
   - `src/BCDT.Domain/Entities/Reporting/ReportSummary.cs`
   - `src/BCDT.Infrastructure/Services/` – tìm service liên quan export/Excel
   - `src/BCDT.Api/Controllers/ApiV1/` – tìm controller ReportSummary hoặc Dashboard

2. Thêm endpoint:
   ```
   GET /api/v1/reporting-periods/{periodId}/export-summary
   [Authorize]
   ```
   Logic:
   - Query tất cả `ReportSummary` của `periodId`
   - Với mỗi summary: lấy tên đơn vị, tổng các chỉ tiêu từ `ReportDataRow`
   - Tạo file Excel đơn giản (dùng ClosedXML hoặc NPOI nếu đã có trong project) hoặc trả JSON dạng bảng nếu không có Excel library
   - Nếu đã có Excel export service → dùng lại; nếu chưa → trả JSON `{ periodId, exportedAt, rows: [{orgName, summaryId, ...indicators}] }`

3. Tạo memory log tại `memory_log_path`.

## Lưu ý

- Kiểm tra project đã có Excel library chưa (ClosedXML, NPOI, EPPlus trong .csproj). Nếu có → dùng. Nếu không → trả JSON.
- Chỉ đọc và sửa file. Không chạy lệnh shell.
