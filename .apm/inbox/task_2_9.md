---
task_ref: "Task 2.9 – Form Clone: Copy FormDefinition + Versions + Sheets + Columns"
agent_assignment: "Agent_Backend"
phase: "Phase_03_Sprint_2_Business_Gaps"
memory_log_path: ".apm/Memory/Phase_03_Sprint_2_Business_Gaps/Task_2_9_Form_Clone.md"
execution_type: single-step
size: medium
---

# Task 2.9 – Form Clone

## Bối cảnh

Admin cần clone một biểu mẫu hiện có (copy toàn bộ cấu trúc) để tạo biểu mẫu mới từ template. Hiện chưa có endpoint này.

## Việc cần làm

1. Đọc các file liên quan:
   - `src/BCDT.Domain/Entities/Form/FormDefinition.cs`
   - `src/BCDT.Infrastructure/Services/FormDefinitionService.cs`
   - `src/BCDT.Api/Controllers/ApiV1/FormDefinitionsController.cs`
   - `src/BCDT.Application/DTOs/Form/` – tìm CreateFormDefinitionRequest

2. Thêm method `CloneAsync(int sourceId, string newCode, string newName)` vào `FormDefinitionService`:
   - Đọc source FormDefinition (IsDeleted=false) → NOT_FOUND nếu không có
   - Kiểm tra `newCode` chưa tồn tại → CONFLICT nếu đã có
   - Deep copy:
     - Tạo `FormDefinition` mới (newCode, newName, copy các field còn lại, Status=Draft)
     - Copy `FormVersion` mới (VersionNumber=1, Status=Draft)
     - Copy `FormSheet` → `FormColumn` → `FormRow` (giữ nguyên cấu trúc, cập nhật FK)
   - SaveChanges
   - Return `Result<FormDefinitionDto>` với entity mới

3. Thêm endpoint:
   ```
   POST /api/v1/form-definitions/{id}/clone
   [Authorize(Policy = "Form.Edit")]
   Body: { "newCode": "...", "newName": "..." }
   → 201 Created với FormDefinitionDto mới
   ```

4. Tạo DTO request `CloneFormDefinitionRequest { NewCode, NewName }` trong Application.

5. Tạo memory log tại `memory_log_path`.

## Lưu ý

- Chỉ đọc và sửa file. Không chạy lệnh shell.
- Clone KHÔNG copy ReportSubmission/data – chỉ copy cấu trúc form.
- Nếu FormVersion/Sheet/Column có field phức tạp, copy tất cả trừ Id và FK parent.
