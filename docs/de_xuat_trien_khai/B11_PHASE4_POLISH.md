# B11 – Phase 4: Polish & UAT (Week 15–17)

**Phase 4** theo [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md).  
**Mục tiêu:** PDF Export, Notification (in-app + email mock), Bug fixes, UAT localhost, Documentation.

---

## 1. Tham chiếu

| Tài liệu / Rule | Nội dung |
|-----------------|----------|
| [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md) | Phase 4 W15–17: PDF Export, Notification, Bug fixes, UAT, Documentation |
| [10.notification.sql](../script_core/sql/v2/10.notification.sql) | BCDT_Notification, BCDT_SystemConfig, BCDT_AuditLog |
| [CẤU_TRÚC_CODEBASE.md](../CẤU_TRÚC_CODEBASE.md) | API response format, layered architecture |
| [RUNBOOK.md](../RUNBOOK.md) mục 6.1 | Trước build: hủy process BCDT.Api |
| **always-verify-after-work** | Build, checklist 7.1, báo Pass/Fail từng bước |

---

## 2. Phạm vi Phase 4

### 2.1. PDF Export (Backend)

- Endpoint: **GET /api/v1/submissions/{id}/pdf**
- Trả về file PDF (application/pdf) nội dung tóm tắt submission (metadata + presentation/summary nếu có).
- Thư viện: QuestPDF (Community/MIT) hoặc tương đương; không bắt buộc DevExpress.

### 2.2. Notification (in-app + email mock)

- **In-app:** Bảng BCDT_Notification (schema đã có trong 10.notification.sql).
  - API: GET /api/v1/notifications (danh sách thông báo của user đăng nhập, filter unread), PATCH /api/v1/notifications/{id}/read (đánh dấu đã đọc).
  - Tạo thông báo khi workflow (submit, approve, reject, revision) – tích hợp với WorkflowExecutionService (optional trong Phase 4: có thể chỉ API CRUD + seed 1–2 bản ghi mẫu).
- **Email mock:** Interface IEmailSender + implementation ghi log (hoặc gửi MailHog nếu cấu hình). Gọi khi gửi thông báo loại Email (Channels chứa "Email").

### 2.3. Bulk operations (Backend)

- **Bulk create submissions (Import):** Tạo hàng loạt submission cho nhiều đơn vị trong cùng Form + Kỳ báo cáo.
  - API: **POST /api/v1/submissions/bulk** – body: `formDefinitionId`, `formVersionId`, `reportingPeriodId`, `organizationIds[]`. Trả về `createdIds`, `skippedCount`, `errors[]` (bỏ qua org đã có submission, ghi lỗi org không tồn tại).
- **Bulk approve:** Duyệt hàng loạt workflow instance.
  - API: **POST /api/v1/workflow-instances/bulk-approve** – body: `workflowInstanceIds[]`, `comments?`. Trả về `succeededIds`, `failed[]` (id, code, message).

### 2.4. Bug fixes

- Sửa lỗi nghiêm trọng nếu phát hiện trong quá trình test; không mở rộng scope.

### 2.5. UAT localhost & Documentation

- Checklist UAT trên localhost (ghi trong mục 7.1).
- Cập nhật hoặc tạo tài liệu: Setup guide (RUNBOOK), User guide tối thiểu (link từ TONG_HOP hoặc README).

---

## 3. API cần triển khai

### 3.1. PDF Export

| Method | URL | Mô tả |
|--------|-----|--------|
| GET | /api/v1/submissions/{id}/pdf | Trả file PDF (application/pdf). 404 nếu submission không tồn tại. |

### 3.2. Notifications (in-app)

| Method | URL | Mô tả |
|--------|-----|--------|
| GET | /api/v1/notifications | Danh sách thông báo của user (query: unreadOnly). |
| PATCH | /api/v1/notifications/{id}/read | Đánh dấu đã đọc. |
| POST | /api/v1/notifications | (Nội bộ hoặc test) Tạo thông báo – body: Type, Title, Message, EntityType, EntityId, ActionUrl, Priority, Channels. |

### 3.3. Bulk operations

| Method | URL | Mô tả |
|--------|-----|--------|
| POST | /api/v1/submissions/bulk | Body: formDefinitionId, formVersionId, reportingPeriodId, organizationIds[]. Tạo submission cho từng org (bỏ qua nếu đã có). Trả createdIds, skippedCount, errors. |
| POST | /api/v1/workflow-instances/bulk-approve | Body: workflowInstanceIds[], comments?. Duyệt hàng loạt. Trả succeededIds, failed[]. |

---

## 4. Entity & Layer

- **Domain:** Notification (entity map BCDT_Notification).
- **Application:** DTOs (NotificationDto, CreateNotificationRequest); INotificationService; IEmailSender (interface), ISubmissionPdfService; BulkCreateSubmissionsRequest/ResultDto, BulkApproveRequest/ResultDto; IReportSubmissionService.BulkCreateAsync, IWorkflowExecutionService.BulkApproveAsync.
- **Infrastructure:** NotificationService; MockEmailSender; SubmissionPdfService; ReportSubmissionService.BulkCreateAsync; WorkflowExecutionService.BulkApproveAsync.
- **Api:** NotificationsController; SubmissionsController (GetPdf, BulkCreate); WorkflowInstancesController (BulkApprove).

---

## 5. Edge cases

- GET submissions/{id}/pdf với id không tồn tại → 404.
- GET submissions/{id}/pdf với submission chưa có presentation → vẫn trả PDF tóm tắt (metadata).
- GET/PATCH notifications với user chưa đăng nhập → 401.
- PATCH notifications/{id}/read với notification không thuộc user → 403 hoặc 404.
- POST submissions/bulk với organizationIds rỗng → 200, createdIds rỗng.
- POST submissions/bulk với org đã có submission → skippedCount tăng, không tạo trùng.
- POST workflow-instances/bulk-approve với instance không Pending → nằm trong failed[].

---

## 6. UAT checklist (localhost)

Dùng cho QA/BA khi chấp nhận trên localhost:

1. **Setup:** Theo [RUNBOOK.md](../RUNBOOK.md): DB đã chạy script 01→14, appsettings.Development.json, dotnet run API (mục 6.1 tắt process trước khi build).
2. **Auth:** Login (admin / Admin@123), kiểm tra /me, refresh, logout.
3. **Submissions:** Tạo submission đơn, tạo bulk (nhiều org), xuất PDF, upload Excel (nếu có form/column mapping).
4. **Workflow:** Gửi duyệt submission, duyệt/từ chối từng cái; gọi bulk-approve với nhiều instance Pending.
5. **Notifications:** GET danh sách, tạo mẫu, đánh dấu đã đọc.
6. **Dashboard:** GET admin/stats, user/tasks (nếu có dữ liệu).

**Documentation:** Setup guide = [RUNBOOK.md](../RUNBOOK.md). User guide tối thiểu = mục 7.1 (Kiểm tra cho AI) và mục 6 (UAT) trong file này.

---

## 7. Postman

- Thêm request: GET submissions/{{submissionId}}/pdf (Save response as file).
- Thêm folder Notifications: GET notifications, PATCH notifications/{{id}}/read, POST notifications (test).
- Thêm request: POST submissions/bulk, POST workflow-instances/bulk-approve.
- Xác thực JSON collection hợp lệ sau khi sửa.

---

## 8. Kiểm tra cho AI (7.1)

**AI sau khi triển khai Phase 4 chạy lần lượt và báo Pass/Fail.**

1. **Build**
   - Trước khi build: hủy process BCDT.Api nếu đang chạy (RUNBOOK 6.1).
   - Lệnh: `dotnet build src/BCDT.Api/BCDT.Api.csproj`
   - Kỳ vọng: Build succeeded.

2. **API đang chạy** (dotnet run --project src/BCDT.Api --launch-profile http). Login lấy token (POST /api/v1/auth/login, admin / Admin@123).

3. **GET /api/v1/submissions/{id}/pdf** (Bearer token, thay {id} bằng submissionId có trong DB)
   - Kỳ vọng: 200, Content-Type application/pdf, body là file PDF.

4. **Edge: GET /api/v1/submissions/999999/pdf** (id không tồn tại)
   - Kỳ vọng: 404.

5. **GET /api/v1/notifications** (Bearer token)
   - Kỳ vọng: 200, `success: true`, `data` là mảng (có thể rỗng).

6. **POST /api/v1/notifications** – tạo thông báo mẫu (nếu API có)
   - Body: `{ "type": "Reminder", "title": "Nhắc hạn nộp", "message": "Báo cáo kỳ 2026-01 sắp đến hạn.", "priority": "Normal", "channels": "InApp" }`
   - Kỳ vọng: 200, `data` có Id.

7. **PATCH /api/v1/notifications/{id}/read** (với id vừa tạo)
   - Kỳ vọng: 200; GET notifications có thể unreadOnly=true để kiểm tra đã đọc.

8. **Postman collection**
   - Mở docs/postman/BCDT-API.postman_collection.json, kiểm tra có request PDF, Notifications, Bulk; chạy PowerShell: `Get-Content docs/postman/BCDT-API.postman_collection.json -Raw -Encoding UTF8 | ConvertFrom-Json` → không lỗi parse.

9. **POST /api/v1/submissions/bulk** (Bearer token)
   - Body: `{ "formDefinitionId": 1, "formVersionId": 1, "reportingPeriodId": 1, "organizationIds": [2, 3] }` (dùng orgId chưa có submission cho form+period này).
   - Kỳ vọng: 200, `data.createdIds` có 1 hoặc 2 id, `data.skippedCount` hoặc `data.errors` tùy dữ liệu.

10. **POST /api/v1/workflow-instances/bulk-approve** (Bearer token)
    - Body: `{ "workflowInstanceIds": [1], "comments": "Bulk duyệt" }` (dùng instance Id đang Pending và user có quyền duyệt).
    - Kỳ vọng: 200, `data.succeededIds` hoặc `data.failed`; nếu không có instance Pending thì failed chứa lỗi.

---

**Version:** 1.1  
**Ngày:** 2026-02-06 (bổ sung Bulk operations, UAT checklist, mục 8 Kiểm tra cho AI bước 9–10)
