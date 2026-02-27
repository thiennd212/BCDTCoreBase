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