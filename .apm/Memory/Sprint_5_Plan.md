# BCDT – Sprint 5 Plan

**Lập bởi:** PM Agent | **Ngày:** 2026-03-02
**Sprint Goal:** Triển khai Notification module (Hangfire + Email) và nâng cao trải nghiệm người dùng
**Nền tảng:** Sprint 1–4 hoàn thành · Build 0 warnings · 24 tests pass

---

## Context

| Chỉ số | Giá trị |
|--------|---------|
| Tests hiện tại | 24 Pass, 0 Fail |
| Build | 0 Warnings, 0 Errors |
| Branch chính | `sprint/4` (chờ PR → main) |
| Sprint 5 branch | `sprint/5` (tạo từ `sprint/4` sau khi merge) |

---

## Sprint 5 Tasks

| # | Task | Effort | Loại | MUST-ASK | Depends on |
|---|------|--------|------|----------|------------|
| **S5.0** | Housekeeping: cập nhật docs APM + PR sprint/3,4→main | S | Infra | — | — |
| **S5.1** | Notification BE: entity, service, Hangfire job, SMTP (MailKit) | M | Feature | ⚠️ Design đã approved | S5.0 |
| **S5.2** | Notification FE: NotificationsPage + bell badge header | M | Feature | — | S5.1 |
| **S5.3** | UserDelegation UX: hiển thị tên user thay vì ID | S | UX Fix | — | — |
| **S5.4** | E2E tests: `/user-delegations` Playwright spec | S | Quality | — | S5.3 |
| **S5.5** | (Backlog Sprint 6) Bulk approve submissions | L | Feature | ⚠️ | — |

---

## Architecture Decisions (đã approved)

| ID | Quyết định |
|----|-----------|
| D-0003 | Notification: không RLS trên bảng, filter ở service layer |
| D-0004 | Email: MailKit 4.x |
| D-0005 | Trigger PERIOD_OPENED: cả manual + CK-02 Hangfire, dedup 5min |

---

## S5.0 – Housekeeping (làm trước, không block task khác)

**Việc cần làm:**
- [ ] Cập nhật `memory/project_state.md` (Sprint 5 goal, xóa stale blockers)
- [ ] Thêm Phase 3+4 vào `.apm/Memory/Memory_Root.md`
- [ ] Fix TONG_HOP dòng 329 ("Còn Prod-11→15" → đã xong)
- [ ] Fix TONG_HOP dòng 306 ("Review nghiệp vụ từng module" thêm ✅)
- [ ] Hướng dẫn User tạo PR `sprint/3` → `main` và `sprint/4` → `main` qua GitHub UI

---

## S5.1 – Notification BE (MUST-ASK đã passed)

### DB Schema
```sql
-- docs/script_core/sql/v2/30.notification_table.sql
CREATE TABLE [dbo].[BCDT_Notification] (
    [Id]          INT IDENTITY(1,1) PRIMARY KEY,
    [UserId]      INT NOT NULL,
    [Type]        NVARCHAR(50) NOT NULL,   -- SUBMISSION_APPROVED, SUBMISSION_REJECTED,
                                            -- SUBMISSION_REVISION, PERIOD_OPENED,
                                            -- DELEGATION_CREATED, DELEGATION_REVOKED
    [Title]       NVARCHAR(256) NOT NULL,
    [Message]     NVARCHAR(1024) NOT NULL,
    [RelatedId]   INT NULL,
    [RelatedUrl]  NVARCHAR(512) NULL,
    [IsRead]      BIT NOT NULL DEFAULT 0,
    [IsDelivered] BIT NOT NULL DEFAULT 0,
    [CreatedAt]   DATETIME2 NOT NULL,
    [ReadAt]      DATETIME2 NULL,
    [DeliveredAt] DATETIME2 NULL,
    CONSTRAINT FK_Notification_User FOREIGN KEY (UserId) REFERENCES BCDT_User(Id)
);
CREATE INDEX IX_Notification_UserId_IsRead  ON BCDT_Notification(UserId, IsRead);
CREATE INDEX IX_Notification_IsDelivered    ON BCDT_Notification(IsDelivered) WHERE IsDelivered = 0;
```

### Files cần tạo/sửa

**Domain:**
- `src/BCDT.Domain/Entities/Notification/Notification.cs`
- `src/BCDT.Domain/Interfaces/INotificationService.cs`
- `src/BCDT.Domain/Interfaces/IEmailService.cs`

**Application:**
- `src/BCDT.Application/DTOs/Notification/NotificationDto.cs`
- `src/BCDT.Application/DTOs/Notification/CreateNotificationRequest.cs`

**Infrastructure:**
- `src/BCDT.Infrastructure/Services/NotificationService.cs` (không RLS, filter WHERE UserId)
- `src/BCDT.Infrastructure/Services/SmtpEmailService.cs` (MailKit)
- `src/BCDT.Infrastructure/Jobs/NotificationDispatchJob.cs` (Hangfire, sp_SetSystemContext(0))
- `src/BCDT.Infrastructure/Persistence/AppDbContext.cs` (thêm DbSet<Notification>)

**API:**
- `src/BCDT.Api/Controllers/ApiV1/NotificationsController.cs`
  - `GET /api/v1/notifications` (paged, filter IsRead)
  - `GET /api/v1/notifications/unread-count`
  - `PUT /api/v1/notifications/{id}/read`
  - `PUT /api/v1/notifications/mark-all-read`
- `src/BCDT.Api/Program.cs` (DI, Hangfire register)

**Trigger integration (các service phải gọi NotificationService):**
- `WorkflowApprovalService` / `WorkflowService` → SUBMISSION_APPROVED, REJECTED, REVISION
- `ReportingPeriodService.CreateAsync` → PERIOD_OPENED (manual)
- `AutoCreateReportingPeriodJob` → PERIOD_OPENED (Hangfire, dedup 5min)
- `UserDelegationService.CreateAsync` → DELEGATION_CREATED
- `UserDelegationService.RevokeAsync` → DELEGATION_REVOKED

**Config (appsettings.json):**
```json
"Email": {
  "SmtpHost": "",
  "SmtpPort": 587,
  "FromAddress": "",
  "FromName": "BCDT System",
  "EnableSsl": true,
  "Username": "",
  "Password": ""
}
```

**SQL seed:**
- `docs/script_core/sql/v2/30.notification_table.sql`
- `docs/script_core/sql/v2/31.seed_menu_notifications.sql` (menu item)

---

## S5.2 – Notification FE

**Files:**
- `src/bcdt-web/src/types/notification.types.ts`
- `src/bcdt-web/src/api/notificationsApi.ts`
- `src/bcdt-web/src/pages/NotificationsPage.tsx` (đã có route `/notifications`)
- `src/bcdt-web/src/components/AppLayout.tsx` (bell badge, poll 30s unread-count)

---

## S5.3 – UserDelegation UX Fix

**Vấn đề:** Table hiện hiển thị `fromUserId: 1`, `toUserId: 2` dạng số nguyên.
**Fix:** BE thêm `FromUserName`, `ToUserName` vào `UserDelegationDto`; Service JOIN với Users.
**Files:** `UserDelegationDto.cs`, `UserDelegationService.cs`, `UserDelegationsPage.tsx`

---

## S5.4 – E2E Tests UserDelegations

**File:** `src/bcdt-web/e2e/user-delegations.spec.ts`
**Tests:**
1. Mở trang `/user-delegations` – hiển thị đúng
2. Tạo ủy quyền mới – form submit → row xuất hiện
3. Thu hồi ủy quyền – confirm → IsActive = false
4. Filter activeOnly – toggle ẩn/hiện dòng đã thu hồi

---

## Verify Gates

| Task | Gate |
|------|------|
| S5.0 | Docs cập nhật, không có stale info |
| S5.1 | Build 0 warnings; dotnet test 24+ pass; Postman: notification tạo + email delivered |
| S5.2 | TypeScript 0 errors; E2E page loads; badge count cập nhật |
| S5.3 | TypeScript 0 errors; UserDelegationsPage hiển thị tên thay vì ID |
| S5.4 | Playwright: 4 tests pass |

---

## Sprint 6 Backlog (defer)

- Bulk approve/reject submissions (MUST-ASK, L effort)
- FormRow Phase 3 – hàng từ danh mục chỉ tiêu
- Digital Signature module
- Form preview độc lập
