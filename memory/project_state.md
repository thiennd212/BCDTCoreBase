# Project State – BCDT

Trạng thái hiện tại cho planning và orchestration. Cập nhật khi sprint/blocker/thay đổi quan trọng.

**Cập nhật:** 2026-02-26

---

## Active sprint goal

- **Mục tiêu hiện tại:** Theo dõi **triển khai production cả nước (Prod)** — đảm bảo checklist R1–R15 (Prod-1..Prod-15) đã triển khai và tài liệu RUNBOOK mục 10 sẵn sàng cho deploy thật.
- **Trạng thái:** Prod-1 → Prod-15 đã đánh dấu xong trong TONG_HOP (2026-02-25–26). Không có sprint formal; ưu tiên 1 theo TONG_HOP 3.1 là “theo dõi” và rà lại RUNBOOK 10 / REVIEW_PRODUCTION_CA_NUOC khi chuẩn bị go-live.
- **Nguồn:** TONG_HOP 3.1, 3.9; [REVIEW_PRODUCTION_CA_NUOC.md](../docs/REVIEW_PRODUCTION_CA_NUOC.md).

---

## Current blockers

- **Không có blocker cấp bách** được ghi trong tài liệu.
- **Rủi ro có thể cản trở production hoặc task tiếp:**
  - **CI/CD:** Không có pipeline tại repo root → không có gate tự động (build/test) trước merge hoặc deploy.
  - **Backend unit/integration tests:** Không có *Tests*.csproj → thay đổi BE dễ gây regression; phụ thuộc E2E + Postman + UAT thủ công.
  - **Secrets và môi trường Prod:** Phụ thuộc việc cấu hình đúng biến môi trường (RUNBOOK 10.1); sai cấu hình = blocker khi deploy.

---

## Modules under heavy modification

- **Hiện tại:** Không có module đang được sửa đổi nặng (MVP 17 tuần đã xong; Prod-1..15 đã xong).
- **Vùng vừa chạm gần đây (Prod-11→15):**
  - **Middleware:** SessionContextMiddleware (503 khi SetUserContext fail), RequestTraceMiddleware (X-Request-Id, TraceId), Rate limiter (AddRateLimiter).
  - **Auth/API:** Login logging; RUNBOOK 10.2/10.3 (timeout, checklist), 10.5 (dữ liệu trong nước).
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
