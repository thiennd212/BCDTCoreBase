# Task 2.6 – Drill-down API: GET /report-summaries/{id}/details

**Phase:** Phase_03_Sprint_2_Business_Gaps  
**Gap:** FR-TH-02  
**Ngày hoàn thành:** 2026-02-27  
**Trạng thái:** ✅ Hoàn thành

---

## Files đã tạo / sửa

| File | Hành động | Mô tả |
|------|-----------|-------|
| `src/BCDT.Application/DTOs/Data/ReportDataRowDto.cs` | Tạo mới | DTO cho ReportDataRow (drill-down) |
| `src/BCDT.Application/Services/Data/IReportSummaryService.cs` | Tạo mới | Interface service với `GetDetailsByIdAsync` |
| `src/BCDT.Infrastructure/Services/Data/ReportSummaryService.cs` | Tạo mới | Implementation: query ReportDataRow theo SubmissionId + SheetIndex của summary |
| `src/BCDT.Api/Controllers/ApiV1/ReportSummariesController.cs` | Tạo mới | Controller với endpoint GET `/{id}/details` |
| `src/BCDT.Api/Program.cs` | Sửa | Đăng ký `IReportSummaryService → ReportSummaryService` |

---

## Endpoint mới

```
GET /api/v1/report-summaries/{id}/details
Authorization: Bearer <token>
```

**Logic:**
1. Tìm `ReportSummary` theo `id` → 404 nếu không tồn tại.
2. Query `BCDT_ReportDataRow` WHERE `SubmissionId = summary.SubmissionId AND SheetIndex = summary.SheetIndex`.
3. Trả `List<ReportDataRowDto>` sắp xếp theo `RowIndex`.

**Response thành công (200):**
```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "submissionId": 10,
      "sheetIndex": 0,
      "rowIndex": 0,
      "referenceEntityId": null,
      "numericValue1": 100.5,
      ...
    }
  ]
}
```

**Response lỗi (404):**
```json
{
  "success": false,
  "errors": [{ "code": "NOT_FOUND", "message": "ReportSummary không tồn tại." }]
}
```

---

## Ghi chú kỹ thuật

- `ReportSummary` không có FK trực tiếp đến `ReportDataRow`; liên kết qua `(SubmissionId, SheetIndex)` – đúng với thiết kế schema hiện tại.
- Service dùng EF Core `AsNoTracking` + projection để tối ưu hiệu năng.
- Không cần migration vì không thêm bảng/cột mới.
