---
task_ref: "Task 2.5 – Fix FormDefinitionService.GetByIdAsync NOT_FOUND"
agent_assignment: "Agent_Backend"
phase: "Phase_02_Sprint_1_Security_Quality"
memory_log_path: ".apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_5_Fix_GetById_NotFound.md"
execution_type: single-step
---

# Task Assignment: Task 2.5 – Fix GetByIdAsync NOT_FOUND

## Vấn đề

`FormDefinitionService.GetByIdAsync` hiện trả `Result.Ok(null)` khi không tìm thấy record thay vì `Result.Fail("NOT_FOUND", "...")`. Điều này không nhất quán với contract của các service khác trong hệ thống và làm cho unit tests phải assert sai hành vi.

## Việc cần làm

1. Đọc `src/BCDT.Infrastructure/Services/FormDefinitionService.cs` – tìm method `GetByIdAsync`
2. Sửa: nếu entity == null → return `Result.Fail("NOT_FOUND", "Form definition not found.")`
3. Kiểm tra xem có Controller hoặc code nào đang check `result.Data == null` sau khi gọi `GetByIdAsync` không – nếu có thì update để dùng `result.IsSuccess` thay thế
4. `dotnet build src/BCDT.Api` → pass
5. Tạo file memory log tại `.apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_5_Fix_GetById_NotFound.md` với nội dung:
   - Files đã sửa
   - Kết quả build

## Output mong đợi

- `GetByIdAsync` trả `Result.Fail("NOT_FOUND")` khi không tìm thấy
- Build pass
- Memory log được ghi
