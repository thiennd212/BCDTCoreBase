---
name: bcdt-workflow-config
description: Tạo cấu hình workflow 1–5 cấp cho form: SQL WorkflowDefinition, WorkflowStep, FormWorkflowConfig. Use when user says "cấu hình workflow", "tạo workflow cho form", "thêm workflow N cấp".
---

# BCDT Workflow Config

Sinh SQL cấu hình workflow phê duyệt 1–5 cấp cho một form. Tham chiếu schema từ agent [bcdt-workflow-designer](../../agents/bcdt-workflow-designer.md).

## Workflow

1. **Thu thập:**
   - Mã form (vd `BC_NHANSU_T`) — FormDefinitionId hoặc Code.
   - Số cấp (1–5).
   - Role mỗi cấp: UNIT_ADMIN, FORM_ADMIN, DATA_ENTRY (map ApproverRoleId từ BCDT_Role).
   - Tùy chọn: OrganizationTypeId trong FormWorkflowConfig (NULL = áp dụng mọi loại đơn vị).

2. **Sinh SQL** theo thứ tự:

### WorkflowDefinition

```sql
INSERT INTO BCDT_WorkflowDefinition (Code, Name, TotalSteps, IsDefault, IsActive, CreatedBy)
VALUES (
    'WF_{FormCode}',           -- e.g. WF_BC_NHANSU_T
    N'Workflow 2 cấp cho {FormName}',
    2,                         -- TotalSteps = số cấp
    0,
    1,
    -1
);
DECLARE @WfId INT = SCOPE_IDENTITY();
```

### WorkflowStep (lặp theo số cấp)

```sql
-- Cấp 1: Trưởng phòng (UNIT_ADMIN)
INSERT INTO BCDT_WorkflowStep (WorkflowDefinitionId, StepOrder, StepName, ApproverRoleId, CanReject, CanRequestRevision, NotifyOnPending, CreatedBy)
VALUES (
    @WfId,
    1,
    N'Trưởng phòng duyệt',
    (SELECT Id FROM BCDT_Role WHERE Code = 'UNIT_ADMIN'),
    1,
    1,
    1,
    -1
);

-- Cấp 2: Giám đốc (FORM_ADMIN)
INSERT INTO BCDT_WorkflowStep (WorkflowDefinitionId, StepOrder, StepName, ApproverRoleId, CanReject, CanRequestRevision, NotifyOnPending, CreatedBy)
VALUES (
    @WfId,
    2,
    N'Giám đốc duyệt',
    (SELECT Id FROM BCDT_Role WHERE Code = 'FORM_ADMIN'),
    1,
    1,
    1,
    -1
);
```

### FormWorkflowConfig (link form với workflow)

```sql
INSERT INTO BCDT_FormWorkflowConfig (FormDefinitionId, WorkflowDefinitionId, OrganizationTypeId, CreatedBy)
VALUES (
    (SELECT Id FROM BCDT_FormDefinition WHERE Code = 'BC_NHANSU_T'),
    @WfId,
    NULL,   -- NULL = áp dụng mọi loại đơn vị; hoặc Id cụ thể nếu chỉ áp dụng 1 loại
    -1
);
```

3. **Checklist:**
   - [ ] WorkflowDefinition có TotalSteps đúng số cấp
   - [ ] WorkflowStep đủ từng bước (StepOrder 1..TotalSteps), ApproverRoleId từ BCDT_Role
   - [ ] FormWorkflowConfig link đúng FormDefinitionId và WorkflowDefinitionId

## Levels gợi ý (từ agent)

| Levels | Chain |
|--------|--------|
| 1 | Manager only |
| 2 | Manager → Director |
| 3 | Reviewer → Manager → Director |
| 4 | + Department Head |
| 5 | + General Director |

## Role Code (BCDT_Role)

- UNIT_ADMIN, FORM_ADMIN, DATA_ENTRY, SYSTEM_ADMIN, VIEWER — dùng Code để lấy Id trong WorkflowStep.
