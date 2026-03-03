# Project State – BCDT

Trạng thái hiện tại cho planning và orchestration. Cập nhật khi sprint/blocker/thay đổi quan trọng.

**Cập nhật:** 2026-03-03

---

## Active sprint goal

- **Sprint hiện tại:** **Sprint 7 ✅ HOÀN THÀNH** – Load Test CCU tăng dần (Pre-Go-Live)
- **Kết quả:** S7.1 E2E 24/24 pass ✅ | S7.2 k6 P0/P1 pass ✅ | S7.3 P2→P4 CCU + bottleneck ⚠️ | S7.4 Soak FAIL (accumulated stress) ❌ | S7.5 Fortune Sheet perf ✅
- **Kế hoạch chi tiết:** `.apm/Memory/Sprint_7_Plan.md`
- **Nền tảng:** Build 0W/0E · **33 tests** · Sprint 1–7 ✅ · Prod checklist 15/15 ✅

### CCU Summary (localhost dev)
| Phase | CCU | Error | p95 | Verdict |
|-------|-----|-------|-----|---------|
| P0 | 1 | 0% | 2.29s | ✅ |
| P1 | 10 | 0% | 45ms | ✅ |
| P2 | 50 | 0% | 65ms | ⚠️ p99=9.4s (BCrypt) |
| P3 | 100 | 0.84% | 790ms | ⚠️ p99=8s (BCrypt) |
| P4 | 200 | 0.11% | 3.2s | ❌ p95 vượt SLA 7% |
| P5/P6 | 500/1000 | N/A | N/A | ⚠️ MUST-ASK |
| P7 Soak | 100, 60m | 0.04% | 47.67s | ❌ Accumulated stress |

### Next sprint proposal: Sprint 8
- Fix `sp_ClearUserContext` (silent exception → stale connections) – HIGH
- Re-run P7 Soak in fresh environment
- P5 Stress (500 VU) sau khi fix sp_ClearUserContext
- Merge PRs: sprint/3→6 vào main

---

## Current blockers

- **PRs cần merge thủ công:** `sprint/3` → `main`, `sprint/4` → `main`, `sprint/5` → `main`, `sprint/6` → `main`
- **P7 Soak cần chạy lại** trong fresh environment (BE restart, không accumulated load) sau khi fix `sp_ClearUserContext`
- **P5/P6** (500/1000 VU): MUST-ASK trước khi chạy; cần staging environment riêng

---

## Modules under heavy modification

- **Sprint 7 hoàn thành:** k6 scripts, Fortune Sheet perf fix, TypeScript fixes, SQL pool fix
- **Fragile areas (không chạm trừ khi cần):** BuildWorkbookFromSubmissionService, SyncFromPresentationService, Fortune Sheet adapter, SessionContextMiddleware

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
