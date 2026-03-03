---
task_ref: "Task 2.8 – Submission Validation: Bắt buộc điền đủ ô required trước khi submit"
agent_assignment: "Agent_Backend"
phase: "Phase_03_Sprint_2_Business_Gaps"
memory_log_path: ".apm/Memory/Phase_03_Sprint_2_Business_Gaps/Task_2_8_Submission_Validation.md"
execution_type: single-step
size: medium
---

# Task 2.8 – Submission Validation trước khi Submit

## Bối cảnh

Hiện tại user có thể submit báo cáo dù chưa điền đủ các ô/hàng bắt buộc. Cần validate trước khi chuyển trạng thái Draft → Submitted.

## Việc cần làm

1. Đọc các file liên quan:
   - `src/BCDT.Domain/Entities/Form/FormColumn.cs` – xem có field IsRequired không
   - `src/BCDT.Domain/Entities/Form/FormRow.cs` – xem có field IsRequired không
   - `src/BCDT.Infrastructure/Services/ReportSubmissionService.cs` – tìm method Submit/ChangeStatus
   - `src/BCDT.Domain/Entities/Submission/ReportSubmission.cs`

2. Trong method xử lý submit (chuyển Draft → Submitted):
   - Query các `FormColumn` hoặc `FormRow` có `IsRequired = true` của form version đó
   - Query `ReportDataRow` đã nhập cho submission này
   - Nếu có cột/hàng required mà chưa có data → return `Result.Fail("VALIDATION_FAILED", "Vui lòng điền đủ các trường bắt buộc trước khi nộp báo cáo.")`
   - Nếu không có field IsRequired trong schema → thêm `public bool IsRequired { get; set; }` vào FormColumn (default false, không cần migration vì default)

3. Đảm bảo error response đúng format: `{ success: false, errors: [{ code: "VALIDATION_FAILED", message: "..." }] }`

4. Tạo memory log tại `memory_log_path`.

## Lưu ý

- Chỉ đọc và sửa file. Không chạy lệnh shell.
- Nếu cấu trúc khác, điều chỉnh theo code hiện có.
- Không thay đổi FE – chỉ BE service validation.
