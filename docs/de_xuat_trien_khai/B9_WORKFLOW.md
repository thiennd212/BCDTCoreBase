# B9 – Workflow (cấu hình 1–5 cấp, tích hợp submission status)

**Phase 3 – Week 11–12** theo [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md).  
**Mục tiêu:** WorkflowDefinition, WorkflowStep, FormWorkflowConfig (CRUD/cấu hình); tích hợp submission status (Draft → Submitted → Approved/Rejected/Revision) với WorkflowInstance, WorkflowApproval.

---

## 1. Tham chiếu

| Tài liệu / Rule | Nội dung |
|-----------------|----------|
| [06.workflow.sql](../script_core/sql/v2/06.workflow.sql) | 5 bảng: WorkflowDefinition, WorkflowStep, FormWorkflowConfig, WorkflowInstance, WorkflowApproval |
| [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md) | Phase 3 Week 11–12: Workflow Engine (1–5 levels), Approval |
| [WORKFLOW_GUIDE.md](../WORKFLOW_GUIDE.md) | Quy trình phát triển, workflow feature-complete |
| **bcdt-workflow-config** | Skill sinh SQL cấu hình workflow |
| **bcdt-workflow-designer** | Agent thiết kế workflow |
| **always-verify-after-work** | Build, test cases, báo Pass/Fail; RUNBOOK 6.1 trước build |

---

## 2. Schema (trích từ 06.workflow.sql)

- **BCDT_WorkflowDefinition:** Code, Name, Description, TotalSteps (1–5), IsDefault, IsActive, CreatedAt, CreatedBy, UpdatedAt, UpdatedBy.
- **BCDT_WorkflowStep:** WorkflowDefinitionId, StepOrder, StepName, ApproverRoleId (FK BCDT_Role), CanReject, CanRequestRevision, NotifyOnPending, …
- **BCDT_FormWorkflowConfig:** FormDefinitionId, WorkflowDefinitionId, OrganizationTypeId (NULL = mọi loại đơn vị), IsActive, CreatedAt, CreatedBy.
- **BCDT_WorkflowInstance:** SubmissionId, WorkflowDefinitionId, CurrentStep, Status (Pending, Approved, Rejected, Cancelled), StartedAt, CompletedAt, CreatedBy.
- **BCDT_WorkflowApproval:** WorkflowInstanceId, StepOrder, Action (Approve, Reject, RequestRevision, Skip), Comments, ApproverId, ApprovedAt.

**Submission status:** Draft → (Submit) → Submitted; sau đó Approve/Reject/RequestRevision cập nhật submission.Status = Approved | Rejected | Revision.

---

## 3. API đã triển khai

| Nhóm | Method | URL | Mô tả |
|------|--------|-----|--------|
| WorkflowDefinitions | GET | /api/v1/workflow-definitions | Danh sách (query: includeInactive) |
| | GET | /api/v1/workflow-definitions/{id} | Chi tiết |
| | GET | /api/v1/workflow-definitions/code/{code} | Theo code |
| | POST | /api/v1/workflow-definitions | Tạo (TotalSteps 1–5) |
| | PUT | /api/v1/workflow-definitions/{id} | Cập nhật |
| | DELETE | /api/v1/workflow-definitions/{id} | Xóa (không xóa nếu đã có config/instance) |
| WorkflowSteps | GET | /api/v1/workflow-definitions/{id}/steps | Danh sách bước |
| | GET | /api/v1/workflow-definitions/{id}/steps/{stepId} | Chi tiết bước |
| | POST | /api/v1/workflow-definitions/{id}/steps | Tạo bước (ApproverRoleId từ BCDT_Role) |
| | PUT | /api/v1/workflow-definitions/{id}/steps/{stepId} | Cập nhật |
| | DELETE | /api/v1/workflow-definitions/{id}/steps/{stepId} | Xóa bước |
| FormWorkflowConfig | GET | /api/v1/forms/{formId}/workflow-config | Danh sách config của form |
| | POST | /api/v1/forms/{formId}/workflow-config | Gán workflow cho form (body: FormDefinitionId, WorkflowDefinitionId, OrganizationTypeId?) |
| | DELETE | /api/v1/forms/{formId}/workflow-config/{configId} | Xóa gán |
| Submissions | POST | /api/v1/submissions/{id}/submit | Gửi submission (Draft → Submitted), tạo WorkflowInstance |
| | GET | /api/v1/submissions/{id}/workflow-instance | Lấy workflow instance của submission |
| WorkflowInstances | GET | /api/v1/workflow-instances/{id}/approvals | Lịch sử phê duyệt (timeline) |
| | POST | /api/v1/workflow-instances/{id}/approve | Duyệt (next step hoặc Approved) |
| | POST | /api/v1/workflow-instances/{id}/reject | Từ chối |
| | POST | /api/v1/workflow-instances/{id}/request-revision | Yêu cầu chỉnh sửa (submission.Status = Revision) |

---

## 4. Entity & Service (đã triển khai)

- **Domain:** WorkflowDefinition, WorkflowStep, FormWorkflowConfig, WorkflowInstance, WorkflowApproval (Entities/Workflow/).
- **Application:** DTOs (WorkflowDefinitionDto, WorkflowStepDto, FormWorkflowConfigDto, WorkflowInstanceDto, Create/Update request); IWorkflowDefinitionService, IWorkflowStepService, IFormWorkflowConfigService, IWorkflowExecutionService.
- **Infrastructure:** WorkflowDefinitionService, WorkflowStepService, FormWorkflowConfigService, WorkflowExecutionService (Submit, Approve, Reject, RequestRevision).
- **Api:** WorkflowDefinitionsController, WorkflowStepsController, FormWorkflowConfigController, WorkflowInstancesController; SubmissionsController (submit, get workflow-instance).

---

## 5. Luồng nghiệp vụ

1. **Cấu hình:** Tạo WorkflowDefinition (vd TotalSteps=2) → thêm WorkflowStep (StepOrder 1, 2; ApproverRoleId = UNIT_ADMIN, FORM_ADMIN) → tạo FormWorkflowConfig (FormDefinitionId, WorkflowDefinitionId, OrganizationTypeId = null).
2. **Gửi báo cáo:** Submission status = Draft → gọi POST /api/v1/submissions/{id}/submit → nếu form có workflow config thì tạo WorkflowInstance (CurrentStep=1, Status=Pending), submission.Status = Submitted.
3. **Duyệt:** Gọi POST /api/v1/workflow-instances/{instanceId}/approve → ghi WorkflowApproval; nếu CurrentStep < TotalSteps thì tăng CurrentStep; nếu đủ bước thì instance.Status = Approved, submission.Status = Approved.
4. **Từ chối / Yêu cầu chỉnh sửa:** Reject → instance.Status = Rejected, submission.Status = Rejected; RequestRevision → submission.Status = Revision (người nộp chỉnh sửa rồi có thể gửi lại).

---

## 6. Edge cases

- Submit submission khi **form chưa có FormWorkflowConfig** → 400 "Form chưa được cấu hình workflow".
- Submit submission khi **status khác Draft** → 400 "Chỉ submission trạng thái Draft mới được gửi".
- Approve/Reject/RequestRevision khi **instance.Status khác Pending** → 400.

---

## 7. Kiểm tra cho AI (7.1)

**AI sau khi triển khai B9 chạy lần lượt và báo Pass/Fail.**

1. **Build**
   - Trước khi build: hủy process BCDT.Api nếu đang chạy (RUNBOOK 6.1).
   - Lệnh: `dotnet build src/BCDT.Api/BCDT.Api.csproj`
   - Kỳ vọng: Build succeeded.

2. **API đang chạy** (dotnet run --project src/BCDT.Api --launch-profile http), đợi vài giây. Login lấy token (POST /api/v1/auth/login, admin / Admin@123).

3. **GET /api/v1/workflow-definitions** (Bearer token)
   - Kỳ vọng: 200, `success: true`, `data` là mảng (có thể rỗng).

4. **POST /api/v1/workflow-definitions** – tạo workflow 2 cấp
   - Body: `{ "code": "WF_TEST", "name": "Workflow test 2 cấp", "totalSteps": 2, "isDefault": false, "isActive": true }`
   - Kỳ vọng: 200, `data` có Id, Code, TotalSteps = 2.

5. **GET /api/v1/workflow-definitions/{id}/steps**
   - Kỳ vọng: 200, `data` là mảng (có thể rỗng).

6. **POST /api/v1/workflow-definitions/{id}/steps** – thêm bước 1
   - Body: `{ "stepOrder": 1, "stepName": "Trưởng phòng duyệt", "approverRoleId": 2, "canReject": true, "canRequestRevision": true, "isActive": true }` (approverRoleId = Id của UNIT_ADMIN trong BCDT_Role, thường 2)
   - Kỳ vọng: 200, `data` có StepOrder = 1.

7. **POST /api/v1/forms/{formId}/workflow-config** – gán workflow cho form
   - Body: `{ "formDefinitionId": 1, "workflowDefinitionId": <wfId>, "organizationTypeId": null, "isActive": true }` (formId trong URL = 1 hoặc id form có sẵn)
   - Kỳ vọng: 200, `data` có FormDefinitionId, WorkflowDefinitionId.

8. **POST /api/v1/submissions/{submissionId}/submit**
   - Dùng submission Id có status Draft và form đã gán workflow ở bước 7.
   - Kỳ vọng: 200, `data` (WorkflowInstanceDto) có SubmissionId, CurrentStep = 1, Status = "Pending". Submission sau đó có Status = "Submitted".

9. **GET /api/v1/submissions/{submissionId}/workflow-instance**
   - Kỳ vọng: 200, `data` khớp instance vừa tạo.

10. **POST /api/v1/workflow-instances/{instanceId}/approve** (body: `{}` hoặc `{ "comments": "OK" }`)
    - Kỳ vọng: 200. Nếu workflow 1 cấp thì instance.Status = Approved, submission.Status = Approved; nếu 2 cấp thì CurrentStep = 2.

10b. **GET /api/v1/workflow-instances/{instanceId}/approvals** (sau khi đã có ít nhất một lần approve/reject/request-revision)
    - Kỳ vọng: 200, `success: true`, `data` là mảng (StepOrder, Action, Comments, ApproverId, ApprovedAt). Instance không tồn tại → 404.

11. **Edge: POST submit với submission đã Submitted**
    - Kỳ vọng: 400, message chứa "Draft".

12. **Edge: POST submit với form chưa có workflow config**
    - Tạo submission mới với form chưa gán workflow (hoặc dùng formId chưa config).
    - Kỳ vọng: 400, message chứa "cấu hình workflow" hoặc "NOT_FOUND".

---

## 7.2. Kiểm tra cho AI (FE – Trang Quy trình phê duyệt)

Trang **Quy trình phê duyệt** (`/workflow-definitions`): WorkflowDefinitionsPage – bảng định nghĩa quy trình, Thêm/Sửa/Xóa quy trình; chọn một quy trình → card "Các bước duyệt" với bảng steps, Thêm/Sửa/Xóa bước. Gọi API workflow-definitions và workflow-definitions/{id}/steps.

| Bước | Nội dung | Cách kiểm tra |
|------|----------|----------------|
| 1 | Build FE | `npm run build` trong `src/bcdt-web`. Kỳ vọng: thành công. |
| 2 | Mở trang | Vào `/workflow-definitions`. Bảng quy trình hiển thị (có thể rỗng). Nút "Thêm quy trình" visible. |
| 3 | Thêm quy trình | Thêm quy trình → Mã, Tên, Số bước (1–5), Đang hoạt động → Tạo. Kỳ vọng: thành công, bảng cập nhật. |
| 4 | Quản lý bước | Chọn một dòng quy trình → card "Các bước duyệt" hiện; Thêm bước duyệt (Thứ tự, Tên bước, Role phê duyệt…) → Tạo. Kỳ vọng: thành công. |
| 5 | Sửa quy trình / Sửa bước | Sửa quy trình (Mã disabled); Sửa bước → Cập nhật. Kỳ vọng: thành công. |
| 6 | DevTools Console | F12 → Console: không error, không warning. |

Gắn workflow cho biểu mẫu: trong **Cấu hình biểu mẫu** (Form Config) đã có block gắn/gỡ workflow (formWorkflowConfigApi). Chạy đủ 7.1 (API) và 7.2 (FE) khi hoàn thành task B9 hoặc FE Workflow admin.

---

## 7.3. Kiểm tra cho AI (Menu Quy trình phê duyệt)

Sau khi chạy script **23.seed_menu_workflow_definitions.sql** (thêm mục menu "Quy trình phê duyệt" vào BCDT_Menu + RoleMenu cho role 1, 2, 3):

| Bước | Nội dung | Kỳ vọng |
|------|----------|---------|
| 1 | Chạy script | `docs/script_core/sql/v2/23.seed_menu_workflow_definitions.sql` (idempotent). Hoặc qua MCP: thực thi 2 batch (insert Menu, insert RoleMenu). |
| 2 | Query kiểm tra | `SELECT * FROM BCDT_Menu WHERE Code = 'WORKFLOW_DEFINITIONS'` → 1 dòng (Url=/workflow-definitions). `SELECT * FROM BCDT_RoleMenu WHERE MenuId = (SELECT Id FROM BCDT_Menu WHERE Code = 'WORKFLOW_DEFINITIONS')` → 3 dòng (RoleId 1, 2, 3). |
| 3 | Đăng nhập FE | Đăng nhập với admin (role FormAdmin hoặc SystemAdmin) → sidebar có mục "Quy trình phê duyệt" → click mở /workflow-definitions. |

---

## 8. Postman

- Collection đã bổ sung folder **Workflow Definitions**, **Workflow Steps**, **Form Workflow Config**, **Submissions (Submit, Get workflow-instance)**, **Workflow Instances (Approve, Reject, Request Revision)**. File: [docs/postman/BCDT-API.postman_collection.json](../postman/BCDT-API.postman_collection.json).

---

**Version:** 1.0  
**Ngày:** 2026-02-06
