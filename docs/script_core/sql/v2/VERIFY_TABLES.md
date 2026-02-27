# Kiểm tra bảng BCDT sau khi chạy script v2

## Kết quả kiểm tra

**Tổng số bảng trong DB:** 49  
**Tổng số bảng theo script (01–10):** 49  
**Kết luận:** Đã tạo đủ và đúng tất cả bảng theo script v2.

> **Lưu ý:** Tài liệu `03.DATABASE_SCHEMA.md` ghi "44 bảng" (Auth 5, Reporting Period 3). Script v2 thực tế có **6** bảng Authentication (thêm `BCDT_RefreshToken`) và **4** bảng Reporting Period (thêm `BCDT_ScheduleJobHistory`), nên tổng là 49 bảng.

---

## So sánh theo module

| Module | Script (file) | Số bảng kỳ vọng | Bảng trong DB | Trạng thái |
|--------|----------------|-----------------|---------------|------------|
| Organization | 01.organization.sql | 4 | 4 | Đủ |
| Authorization | 02.authorization.sql | 9 | 9 | Đủ |
| Authentication | 03.authentication.sql | 6 | 6 | Đủ |
| Form Definition | 04.form_definition.sql | 8 | 8 | Đủ |
| Data Storage | 05.data_storage.sql | 5 | 5 | Đủ |
| Workflow | 06.workflow.sql | 5 | 5 | Đủ |
| Reporting Period | 07.reporting_period.sql | 4 | 4 | Đủ |
| Signature | 08.signature.sql | 2 | 2 | Đủ |
| Reference Data | 09.reference_data.sql | 3 | 3 | Đủ |
| Notification | 10.notification.sql | 3 | 3 | Đủ |
| **Tổng** | | **49** | **49** | **Đủ** |

---

## Danh sách bảng theo module

### 01. Organization (4)
- BCDT_OrganizationType
- BCDT_Organization
- BCDT_User
- BCDT_UserOrganization

### 02. Authorization (9)
- BCDT_Role
- BCDT_Permission
- BCDT_RolePermission
- BCDT_UserRole
- BCDT_Menu
- BCDT_RoleMenu
- BCDT_DataScope
- BCDT_RoleDataScope
- BCDT_UserDelegation

### 03. Authentication (6)
- BCDT_AuthProvider
- BCDT_UserExternalIdentity
- BCDT_TwoFactorProvider
- BCDT_UserTwoFactor
- BCDT_UserBackupCode
- BCDT_RefreshToken

### 04. Form Definition (8)
- BCDT_FormDefinition
- BCDT_FormVersion
- BCDT_FormSheet
- BCDT_FormColumn
- BCDT_FormRow
- BCDT_FormCell
- BCDT_FormDataBinding
- BCDT_FormColumnMapping

### 05. Data Storage (5)
- BCDT_ReportSubmission
- BCDT_ReportPresentation
- BCDT_ReportDataRow
- BCDT_ReportSummary
- BCDT_ReportDataAudit

### 06. Workflow (5)
- BCDT_WorkflowDefinition
- BCDT_WorkflowStep
- BCDT_FormWorkflowConfig
- BCDT_WorkflowInstance
- BCDT_WorkflowApproval

### 07. Reporting Period (4)
- BCDT_ReportingFrequency
- BCDT_ReportingPeriod
- BCDT_ScheduleJob
- BCDT_ScheduleJobHistory

### 08. Signature (2)
- BCDT_SignatureProvider
- BCDT_DocumentSignature

### 09. Reference Data (3)
- BCDT_ReferenceEntityType
- BCDT_ReferenceEntity
- BCDT_ReferenceEntityAttribute

### 10. Notification (3)
- BCDT_Notification
- BCDT_SystemConfig
- BCDT_AuditLog

---

## Số cột mỗi bảng (trích từ DB)

| Bảng | Số cột |
|------|--------|
| BCDT_AuditLog | 10 |
| BCDT_AuthProvider | 8 |
| BCDT_DataScope | 5 |
| BCDT_DocumentSignature | 24 |
| BCDT_FormCell | 17 |
| BCDT_FormColumn | 18 |
| BCDT_FormColumnMapping | 6 |
| BCDT_FormDataBinding | 18 |
| BCDT_FormDefinition | 22 |
| BCDT_FormRow | 14 |
| BCDT_FormSheet | 11 |
| BCDT_FormVersion | 11 |
| BCDT_FormWorkflowConfig | 7 |
| BCDT_Menu | 10 |
| BCDT_Notification | 18 |
| BCDT_Organization | 19 |
| BCDT_OrganizationType | 11 |
| BCDT_Permission | 7 |
| BCDT_ReferenceEntity | 15 |
| BCDT_ReferenceEntityAttribute | 10 |
| BCDT_ReferenceEntityType | 15 |
| BCDT_RefreshToken | 9 |
| BCDT_ReportDataAudit | 13 |
| BCDT_ReportDataRow | 24 |
| BCDT_ReportingFrequency | 10 |
| BCDT_ReportingPeriod | 19 |
| BCDT_ReportPresentation | 8 |
| BCDT_ReportSubmission | 23 |
| BCDT_ReportSummary | 16 |
| BCDT_Role | 11 |
| BCDT_RoleDataScope | 4 |
| BCDT_RoleMenu | 9 |
| BCDT_RolePermission | 5 |
| BCDT_ScheduleJob | 17 |
| BCDT_ScheduleJobHistory | 7 |
| BCDT_SignatureProvider | 8 |
| BCDT_SystemConfig | 8 |
| BCDT_TwoFactorProvider | 7 |
| BCDT_User | 23 |
| BCDT_UserBackupCode | 6 |
| BCDT_UserDelegation | 14 |
| BCDT_UserExternalIdentity | 9 |
| BCDT_UserOrganization | 9 |
| BCDT_UserRole | 12 |
| BCDT_UserTwoFactor | 8 |
| BCDT_WorkflowApproval | 9 |
| BCDT_WorkflowDefinition | 11 |
| BCDT_WorkflowInstance | 8 |
| BCDT_WorkflowStep | 14 |

---

*Kiểm tra thực hiện bằng MCP user-mssql, ngày kiểm tra: 2025-02-03.*
