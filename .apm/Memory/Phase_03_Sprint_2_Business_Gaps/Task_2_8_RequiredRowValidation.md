# Task 2.8 – Validation required row khi nộp báo cáo

**Ngày:** 2026-02-27
**Kết quả:** ✅ DONE – Build Pass
**Size:** SMALL (1 file)

## Việc đã làm

Trong `ReportSubmissionService.UpdateAsync`, khi status chuyển sang "Submitted":

```csharp
var sheetIds = await _db.FormSheets.AsNoTracking()
    .Where(s => s.FormDefinitionId == entity.FormDefinitionId)
    .Select(s => s.Id).ToListAsync(ct);
var hasRequired = await _db.FormRows.AsNoTracking()
    .AnyAsync(r => sheetIds.Contains(r.FormSheetId) && r.IsRequired, ct);
if (hasRequired)
{
    var dataCount = await _db.ReportDataRows.AsNoTracking()
        .CountAsync(r => r.ReportSubmissionId == entity.Id, ct);
    if (dataCount == 0)
        return Result.Fail("VALIDATION_FAILED", "Biểu mẫu có dòng bắt buộc nhưng chưa có dữ liệu.");
}
```

## Ghi chú

- Cursor CLI trả "DONE" nhưng không có code → implement trực tiếp
- Validation chỉ áp dụng khi status → Submitted (không chặn Draft)
