# Project State – BCDT

Trạng thái hiện tại cho planning và orchestration. Cập nhật khi sprint/blocker/thay đổi quan trọng.

**Cập nhật:** 2026-03-03

---

## Active sprint goal

- **Sprint hiện tại:** **Sprint 8 ✅ HOÀN THÀNH** – Stabilize Production: SessionContext Fix + CCU Breaking Point
- **Kết quả:**
  - S8.1 ✅ SessionContextMiddleware `CancellationToken.None` – stale pool fixed. D-0006.
  - S8.2 ❌ P7 Soak Lần 2: avg↓11% med↓25%, p95=44.82s vẫn FAIL – dev machine CPU limit
  - S8.3 ✅ Merge 4 PRs sprint/3→6 vào main – main branch đầy đủ Sprint 1–8
  - S8.4 ⚠️ P5 Ramp (Phương án C) done: breaking point ~250 VU; Phương án B (staging) chờ provision
  - S8.5 🔵 FormRow Phase 3 – optional, chờ business confirm
- **Kế hoạch chi tiết:** `.apm/Memory/Sprint_8_Plan.md`
- **Nền tảng:** Build 0W/0E · **33 tests** · Sprint 1–8 ✅ · Prod checklist 15/15 ✅

### CCU Summary (localhost dev, Sprint 7–8)
| Phase | CCU | Error | p95 | Verdict |
|-------|-----|-------|-----|---------|
| P0 | 1 | 0% | 2.29s | ✅ |
| P1 | 10 | 0% | 45ms | ✅ |
| P2 | 50 | 0% | 65ms | ⚠️ p99=9.4s (BCrypt) |
| P3 | 100 | 0.84% | 790ms | ⚠️ p99=8s (BCrypt) |
| P4 | 200 | 0.11% | 3.2s | ❌ p95 vượt SLA 7% |
| **P5-200** | 200 | 0.00% | **2.01s** | ⚠️ p95 pass, p99=9s |
| **P5-300** | 300 | 0.22% | **8.12s** | ❌ **Breaking point dev** |
| **P5-500** | 500 | 0.54% | **14.71s** | ❌ Severe, graceful |
| P7 Soak L1 | 100, 60m | 0.04% | 47.67s | ❌ Accumulated stress |
| P7 Soak L2 | 100, 60m | 0.15% | 44.82s | ❌ Dev limit (S8.1 ↓11%) |

**Breaking point dev machine (i5-10210U):** ~250 VU. Hệ thống không crash ở 500 VU (graceful degradation).

### Next sprint: Sprint 9
- Close Sprint 8 docs (done via apm.pm)
- S8.4 Phương án B khi staging ready
- P7 Soak on staging khi staging ready
- Sprint 9 focus: TBD – go-live prep / new features / FormRow Phase 3

---

## Current blockers

- **S8.4 Phương án B + P7 Soak staging**: Cần User provision staging server (8 core, 16GB) per `docs/load-test/STAGING_SETUP.md`

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
