# Decision Log – BCDT (Optimized)

Log các quyết định có ảnh hưởng kiến trúc, hành vi hệ thống, production, hoặc thay đổi contract.  
Mục tiêu: audit trail rõ, dễ rollback, dễ trace về PR/commit/ticket.

**Rule:** Nếu một thay đổi thuộc nhóm “DECISION REQUIRED” trong AI_WORK_PROTOCOL → phải ghi 1 entry ở đây.

---

## 1) How to use

- Mỗi quyết định = 1 dòng trong bảng + (tuỳ chọn) 1 đoạn “Notes” ngắn.
- Quyết định **nhỏ** nhưng ảnh hưởng hành vi (RLS/Hangfire/workbook/replica/verify gates) vẫn phải ghi.
- Nếu đang thử nghiệm: Status = `Proposed` / `Accepted` / `Deprecated` / `Reverted`.

---

## 2) Decision register

| ID | Date (YYYY-MM-DD) | Area | Title | Status | Owner | Decision | Reason | Impact | Rollback | Rollback-Ready (Y/N) | Links |
|----|-------------------|------|-------|--------|-------|----------|--------|--------|----------|----------------------|-------|
| D-0001 | 2026-02-26 | Production | Baseline decision log | Accepted | <name> | Create decision log format | Need audit & rollback trace | Low | N/A | Y | (PR/Ticket/Doc) |
| D-0002 | 2026-02-27 | Auth | JWT Token Storage: localStorage → in-memory + httpOnly cookie | Accepted | PM+SA | Access token: in-memory JS var; Refresh token: httpOnly cookie `bc_refresh_token`; CORS AllowCredentials | XSS risk khi dùng localStorage; httpOnly cookie không đọc được bởi JS | Auth flow thay đổi; CORS cần AllowCredentials; E2E re-run | Revert tokenStore về localStorage + xóa Set-Cookie | Y | Sprint 1, Task 2.1 |
| D-0003 | 2026-03-02 | Notification | BCDT_Notification: không dùng RLS, bảo vệ ở service layer | Accepted | PM+SA | Bảng BCDT_Notification không có RLS policy. Bảo mật qua WHERE UserId = currentUserId trong mọi query. Hangfire job dùng sp_SetSystemContext(0) | Hangfire phải tạo notification cho nhiều UserId 1 lần → RLS per-user quá tốn (N context switch). Service-layer filter đủ bảo mật cho notification | Mọi service query Notification PHẢI có WHERE UserId; nếu quên → data leak | Thêm RLS policy sau nếu cần | Y | Sprint 5, S5.1 |
| D-0004 | 2026-03-02 | Notification | Email library: MailKit 4.x thay vì System.Net.Mail | Accepted | SA | Dùng MailKit NuGet package cho SmtpEmailService | System.Net.Mail đã deprecated trong .NET 9+; MailKit là chuẩn community, hỗ trợ TLS/OAuth đầy đủ | Thêm NuGet dependency MailKit | Swap SmtpEmailService implementation | Y | Sprint 5, S5.1 |
| D-0005 | 2026-03-02 | Notification | Trigger PERIOD_OPENED: cả manual create và Hangfire CK-02 | Accepted | BA+SA | Tạo notification khi: (1) POST /reporting-periods tạo thủ công; (2) AutoCreateReportingPeriodJob chạy tự động. Dedup bằng check trùng (periodId + type + timestamp < 5min) | User cần nhận thông báo kỳ mới dù mở bằng cách nào | CK-02 job phải gọi NotificationService; cần dedup logic để tránh duplicate | Bỏ trigger ở CK-02, chỉ giữ manual | Y | Sprint 5, S5.1 |
| D-0006 | 2026-03-03 | Middleware | SessionContextMiddleware: ClearUserContext dùng CancellationToken.None | Accepted | PM+SA | `finally` block gọi sp_ClearUserContext với `CancellationToken.None` thay vì `context.RequestAborted` | `context.RequestAborted` cancel ngay khi response gửi xong → `ExecuteNonQueryAsync` throw `OperationCanceledException` → sp_ClearUserContext KHÔNG bao giờ chạy → stale session context trong pool → RLS queries chậm dưới load (root cause P7 Soak latency 22s avg) | Mọi connection sẽ được clear đúng sau mỗi request. Nếu sp_ClearUserContext fail vì lý do khác (SQL overload) → LogWarning thay vì silent catch. Connection không bị invalidate – nếu muốn mạnh hơn có thể close connection trong catch (enhancement) | Revert về `context.RequestAborted` (không khuyến nghị) | Y | Sprint 8, S8.1, commit 4445f8d |

> **Area** gợi ý: RLS, Auth, Middleware, Hangfire, Workbook, Dashboard, Database, Deployment, Performance, Security, Testing/Verification, DevOps.

---

## 3) Notes template (optional)

Dùng khi quyết định phức tạp hoặc cần nêu điều kiện triển khai.

### Notes for D-XXXX
- **Context:** (vì sao phát sinh quyết định)
- **Alternatives considered:** (A/B/C + vì sao bỏ)
- **Constraints:** (RLS, perf, prod env, timeline…)
- **Verification:** (build/E2E/Postman/SQL checks cụ thể)
- **Monitoring:** (metric/log cần theo dõi sau deploy)
- **Follow-ups:** (task tiếp theo nếu có)

---

## 4) Quick rules (để team ghi đúng và đều)

### 4.1 Status definitions
- **Proposed:** đề xuất, chưa merge
- **Accepted:** đã merge/đưa vào dùng
- **Deprecated:** còn tồn tại nhưng không khuyến nghị, sẽ bỏ
- **Reverted:** đã rollback (ghi rõ lý do + link PR revert)

### 4.2 Rollback-Ready
- **Y** nếu rollback có hướng dẫn rõ + không phá data
- **N** nếu rollback phức tạp (migrate data, contract breaking…)

### 4.3 Links
Ít nhất 1 trong các loại:
- PR link / commit hash
- Jira ticket ID
- Doc link (RUNBOOK section / spec/tasks file)

---

## 5) Common decision triggers (tham chiếu nhanh)

Bắt buộc ghi decision khi có thay đổi thuộc các nhóm:

- **RLS/session context** (middleware/SP/policy/hành vi 503)
- **Hangfire jobs** có đọc/ghi bảng RLS, hoặc thay đổi context pattern
- **Workbook flow** (contract workbook-data/report-presentations, thứ tự sync, resolver/binding)
- **Dashboard/replica/DbContext strategy** (AppDbContext vs AppReadOnlyDbContext)
- **Production/deployment behavior** (env vars bắt buộc, timeouts, rate limit, CORS, JWT, secrets handling)
- **Verify gates** (thay đổi quy định build/E2E/Postman, thêm/bỏ test bắt buộc)
- **DB schema/migrations** có rủi ro dữ liệu/production

---

## 6) Index (optional)

Nếu log dài, có thể thêm index theo Area:

- RLS: D-xxxx, D-xxxx
- Hangfire: D-xxxx
- Workbook: D-xxxx
- Production: D-xxxx