status: DONE
timestamp: 2026-02-27T21:07:14Z

Tất cả các bước đã hoàn thành. Dưới đây là tóm tắt những gì đã thực hiện:

---

## Tóm tắt Task 2.6 – Drill-down API FR-TH-02

### Files đã tạo/sửa

**Tạo mới (4 files):**

1. `src/BCDT.Application/DTOs/Data/ReportDataRowDto.cs` – DTO ánh xạ đầy đủ các field của entity `ReportDataRow`

2. `src/BCDT.Application/Services/Data/IReportSummaryService.cs` – Interface với method `GetDetailsByIdAsync(long summaryId)`

3. `src/BCDT.Infrastructure/Services/Data/ReportSummaryService.cs` – Implementation: tìm summary theo id → query `ReportDataRow` theo `(SubmissionId, SheetIndex)` của summary đó → trả `Result<List<ReportDataRowDto>>`

4. `src/BCDT.Api/Controllers/ApiV1/ReportSummariesController.cs` – Controller với endpoint:
   ```
   GET /api/v1/report-summaries/{id}/details
   [Authorize]
   → 200 + List<ReportDataRowDto>
   → 404 nếu summary không tồn tại
   ```

**Sửa (1 file):**

5. `src/BCDT.Api/Program.cs` – Thêm dòng đăng ký DI:
   ```csharp
   builder.Services.AddScoped<IReportSummaryService, ReportSummaryService>();
   ```

### Ghi chú thiết kế

`ReportSummary` không có FK trực tiếp đến `ReportDataRow` trong schema. Liên kết được thực hiện qua cặp `(SubmissionId, SheetIndex)` – service query `ReportDataRow WHERE SubmissionId = summary.SubmissionId AND SheetIndex = summary.SheetIndex`, đúng với thiết kế hiện tại. Không cần migration.