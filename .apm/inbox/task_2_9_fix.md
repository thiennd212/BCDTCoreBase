---
task_ref: "Task 2.9-fix – Implement CloneAsync in FormDefinitionService"
agent_assignment: "Agent_Backend"
phase: "Phase_03_Sprint_2_Business_Gaps"
memory_log_path: ".apm/Memory/Phase_03_Sprint_2_Business_Gaps/Task_2_9_Form_Clone.md"
execution_type: single-step
size: small
---

# Task 2.9-fix – Implement CloneAsync

## Bối cảnh

Build lỗi:
```
error CS0535: 'FormDefinitionService' does not implement interface member
'IFormDefinitionService.CloneAsync(int, CloneFormDefinitionRequest, int, CancellationToken)'
```

## Việc cần làm

1. Đọc `src/BCDT.Application/Services/Form/IFormDefinitionService.cs` – xem đúng signature của `CloneAsync`
2. Đọc `src/BCDT.Application/DTOs/Form/CloneFormDefinitionRequest.cs` – xem fields
3. Đọc `src/BCDT.Infrastructure/Services/FormDefinitionService.cs` – xem code hiện tại
4. Thêm implementation `CloneAsync(int sourceId, CloneFormDefinitionRequest request, int createdBy, CancellationToken)` vào `FormDefinitionService`:
   - Load source FormDefinition → NOT_FOUND nếu null
   - Check `request.NewCode` chưa tồn tại → CONFLICT nếu đã có
   - Deep copy: FormDefinition mới → FormVersion → FormSheet → FormColumn → FormRow (giữ nguyên cấu trúc)
   - `SaveChangesAsync`
   - Return `Result<FormDefinitionDto>` entity mới
5. Kiểm tra `src/BCDT.Api/Controllers/ApiV1/FormDefinitionsController.cs` – endpoint clone đã được thêm chưa; nếu chưa thì thêm `POST /api/v1/form-definitions/{id}/clone`

Chỉ đọc và sửa file. Không chạy lệnh shell.
