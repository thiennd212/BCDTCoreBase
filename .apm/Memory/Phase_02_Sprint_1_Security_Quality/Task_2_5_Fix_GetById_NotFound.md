---
agent: Agent_Backend
task_ref: "Task 2.5 – Fix FormDefinitionService.GetByIdAsync NOT_FOUND"
status: Completed
ad_hoc_delegation: false
compatibility_issues: false
important_findings: false
---

# Task Log: Task 2.5 – Fix GetByIdAsync NOT_FOUND

## Summary

Rà soát và xác nhận `FormDefinitionService.GetByIdAsync` đã trả `Result.Fail("NOT_FOUND", "Form definition not found.")` khi không tìm thấy bản ghi. Controller và test đã dùng `result.IsSuccess`; không có chỗ nào check `result.Data == null` sau khi gọi `GetByIdAsync`. Không có thay đổi code (implementation đã đúng).

## Details

### 1. FormDefinitionService.GetByIdAsync

- **File:** `src/BCDT.Infrastructure/Services/FormDefinitionService.cs`
- **Hiện trạng:** Khi `entity == null`, method đã return `Result.Fail<FormDefinitionDto?>("NOT_FOUND", "Form definition not found.")` (dòng 27–28). Không cần sửa.

### 2. Controller / callers

- **FormDefinitionsController.Get(int id):** Dùng `if (!result.IsSuccess)` và `result.Code == "NOT_FOUND"` → `NotFound(...)`. Không check `result.Data == null`. OK.
- **FormDefinitionsController.GetTemplate:** Gọi `GetByIdAsync(id)` rồi dùng `form.IsSuccess ? form.Data!.Code : "form_template.xlsx"`. Đã dùng `IsSuccess`. OK.

### 3. Unit tests

- **FormDefinitionServiceTests.GetByIdAsync_NotFound_ReturnsNotFoundResult:** Assert `result.IsSuccess == false`, `result.Code == "NOT_FOUND"`, `result.Data == null`. Khớp với hành vi hiện tại. Không cần sửa.

## Files đã kiểm tra (không sửa)

- `src/BCDT.Infrastructure/Services/FormDefinitionService.cs`
- `src/BCDT.Api/Controllers/ApiV1/FormDefinitionsController.cs`
- `src/BCDT.Tests/Services/FormDefinitionServiceTests.cs`

## Kết quả build

Build không được chạy theo yêu cầu user (chỉ đọc/sửa file, không chạy lệnh dotnet). Code hiện tại đã đúng với yêu cầu task; build dự kiến pass nếu chạy `dotnet build src/BCDT.Api`.

## Output mong đợi (đã đạt)

- `GetByIdAsync` trả `Result.Fail("NOT_FOUND")` khi không tìm thấy: **đã đúng trong code**
- Controller dùng `result.IsSuccess` / `result.Code`: **đã đúng**
- Memory log: **đã ghi** (file này)

## Next Steps

Không. Task 2.5 hoàn thành (xác nhận implementation + không thay đổi code).
