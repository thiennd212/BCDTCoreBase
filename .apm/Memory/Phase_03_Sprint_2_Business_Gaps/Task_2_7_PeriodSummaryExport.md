# Task 2.7 – Export tổng hợp kỳ báo cáo

**Ngày:** 2026-02-27
**Kết quả:** ✅ DONE – Build Pass
**Size:** SMALL (3 files)

## Việc đã làm

1. Tạo `src/BCDT.Application/DTOs/ReportingPeriod/PeriodSummaryExportDto.cs`:
   - `PeriodSummaryExportDto` { PeriodId, ExportedAt, Rows: List<PeriodSummaryRowDto> }
   - `PeriodSummaryRowDto` { SubmissionId, OrganizationId, SheetIndex, DataRowCount, TotalValue1..10 }

2. Thêm vào `IReportingPeriodService`:
   ```csharp
   Task<Result<PeriodSummaryExportDto>> GetSummaryExportAsync(int periodId, CancellationToken);
   ```

3. Implement trong `ReportingPeriodService.GetSummaryExportAsync`:
   - Query ReportSubmissions cho periodId
   - Join ReportSummaries theo submissionIds
   - Map sang PeriodSummaryRowDto

4. Thêm endpoint `GET /api/v1/reporting-periods/{id}/export-summary` vào `ReportingPeriodsController`.

## Ghi chú

- Cursor CLI trả "DONE" nhưng không có code → implement trực tiếp bằng Claude Code
- ReportSummary entity: xác nhận property names trước khi implement
