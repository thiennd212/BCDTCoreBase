# Project State – BCDT

Trạng thái hiện tại cho planning và orchestration. Cập nhật khi sprint/blocker/thay đổi quan trọng.

**Cập nhật:** 2026-03-02

---

## Active sprint goal

- **Sprint hiện tại:** **Sprint 5** – Notification module (Hangfire + MailKit) + UX improvements
- **Mục tiêu:** Triển khai hệ thống thông báo in-app + email đầy đủ; cải thiện UX UserDelegation; bổ sung E2E coverage
- **Kế hoạch chi tiết:** `.apm/Memory/Sprint_5_Plan.md`
- **Decisions đã approved:** D-0003 (Notification no RLS), D-0004 (MailKit), D-0005 (Period trigger cả hai)
- **Nền tảng:** Build 0 warnings · 24 tests · Sprint 1–4 ✅

---

## Current blockers

- **Không có blocker kỹ thuật.** Sprint 5 có thể bắt đầu ngay.
- **PRs cần tạo thủ công:** `sprint/3` → `main` và `sprint/4` → `main` qua GitHub UI (gh CLI không available).

---

## Modules under heavy modification

- **Sprint 5 – đang chuẩn bị:** Notification module (mới hoàn toàn), UserDelegation (UX fix nhỏ), E2E (user-delegations).
- **Vùng sẽ chạm Sprint 5:**
  - **Hangfire:** NotificationDispatchJob (job mới, phải gọi sp_SetSystemContext(0))
  - **WorkflowService/ReportingPeriodService/UserDelegationService:** thêm trigger gọi NotificationService
  - **AppDbContext:** thêm DbSet&lt;Notification&gt;
  - **FE AppLayout.tsx:** thêm bell badge icon
- **Khi có task mới:** Module dễ bị sửa nhiều theo TONG_HOP / AI_PROJECT_SNAPSHOT: **Form & Submission (B12, P8)** — FormConfig, SubmissionDataEntry, workbook-data, BuildWorkbookFromSubmissionService, SyncFromPresentationService.

---

## Known fragile areas

- **BuildWorkbookFromSubmissionService / SyncFromPresentationService / DataBindingResolver:** Logic phức tạp (B12 chỉ tiêu động, P8 lọc động/placeholder), nhiều bảng và cache; đã tối ưu batch (Perf-8, Perf-12) nhưng vẫn dễ lỗi khi đổi form structure hoặc binding.
- **RLS + session context:** Mọi request phải qua SessionContextMiddleware; nếu set context sai hoặc thiếu → RLS filter sai. SessionContext throw → 503 (Prod-11). Dashboard đã chuyển sang AppDbContext khi dùng RLS (Prod-3); Hangfire job phải gọi sp_SetSystemContext (Prod-8).
- **Frontend nhập liệu Excel:** Fortune-sheet + `fortuneSheetAdapter` + SubmissionDataEntryPage; đồng bộ workbook ↔ API (workbook-data, report-presentations) dễ lệch format hoặc lỗi khi cấu trúc form thay đổi.
- **Không có Repository/UnitOfWork:** Service dùng DbContext trực tiếp → unit test service cần mock DbContext hoặc in-memory provider; hiện chỉ có E2E + Postman.

---

## High-risk components

- **Luồng nhập liệu end-to-end:** Form config → BuildWorkbookFromSubmissionService → GET workbook-data → FE Fortune-sheet → PUT report-presentations → SyncFromPresentationService → ReportDataRow + ReportSummary. Hỏng ở bất kỳ bước nào ảnh hưởng dữ liệu báo cáo.
- **Hangfire + RLS:** Job chạy ngoài HTTP; nếu quên sp_SetSystemContext → đọc/ghi bảng RLS có thể sai hoặc 0 dòng. Đã xử lý trong AggregateSubmissionJob (Prod-8); job mới cần tuân thủ tương tự.
- **Read replica (khi bật):** Dashboard đã không dùng replica (Prod-3). Bất kỳ service nào dùng AppReadOnlyDbContext cho bảng RLS mà không set session context trên replica → rủi ro số liệu sai.
- **Production secrets & env:** Connection string, JWT secret, CORS, Hangfire ServerEnabled — sai cấu hình = lỗi auth, CORS hoặc job trùng. RUNBOOK 10.1 liệt kê biến bắt buộc.
- **API nặng (workbook-data, aggregate):** Timeout hoặc tải cao; đã có Kestrel limits + CancellationToken (Perf-4, Prod-14) và rate limit (Prod-13); vẫn cần theo dõi khi tải thật.

---

## References

| Doc | Use |
|-----|-----|
| [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) | Ưu tiên, Prod 3.9, block giao AI |
| [AI_PROJECT_SNAPSHOT.md](../docs/AI_PROJECT_SNAPSHOT.md) | Stack, module, hot paths, verify gates |
| [REVIEW_PRODUCTION_CA_NUOC.md](../docs/REVIEW_PRODUCTION_CA_NUOC.md) | R1–R15, rủi ro production |
| [RUNBOOK.md](../docs/RUNBOOK.md) | Build 6.1, E2E, Production 10 |
