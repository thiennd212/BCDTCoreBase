# BCDT – APM Memory Root

**Memory Strategy:** Dynamic-MD  
**Project Overview:** Plan điều phối BCDT theo snapshot/state: ưu tiên TONG_HOP (production cả nước, tùy chọn 3.7); tuân AI_WORK_PROTOCOL; task → tài liệu + Agent/Skill theo TONG_HOP 3.2 và block "Cách giao AI". Nguồn sự thật: [AI_PROJECT_SNAPSHOT](../../docs/AI_PROJECT_SNAPSHOT.md), [TONG_HOP](../../docs/TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [AI_WORK_PROTOCOL](../../memory/AI_WORK_PROTOCOL.md), [DECISIONS](../../memory/DECISIONS.md), [project_state](../../memory/project_state.md).

---

## Index

| Mục | Mô tả |
|-----|--------|
| [Implementation Plan](../Implementation_Plan.md) | Plan điều phối (Phase 1, Tasks 1.1–1.3) |
| [BCDT rules](#bcdt-rules--protocol) | Scope, MUST-ASK, verify (AI_WORK_PROTOCOL) |
| [Decision triggers](#decision-triggers) | Khi nào ghi DECISIONS.md |
| [Phase 1](#phase-1--điều-phối-theo-tong_hop-và-production-readiness) | Điều phối TONG_HOP & Production readiness |

---

## BCDT rules & protocol

Mọi task APM phải tuân [memory/AI_WORK_PROTOCOL.md](../../memory/AI_WORK_PROTOCOL.md):

- **Scope (§1):** Chỉ sửa file trong phạm vi task (BE `src/BCDT.*`, FE `src/bcdt-web/src`, Docs `docs/`, `memory/`, SQL `docs/script_core/sql/`). Cấm refactor diện rộng, đổi middleware/Auth/RLS/schema “tiện tay”.
- **MUST-ASK (§2.1):** Nếu chạm RLS/session context, Middleware, Hangfire jobs, Workbook flow, Dashboard/Replica, SQL production → dừng, yêu cầu impact analysis trước khi sửa.
- **DECISION REQUIRED (§2.2):** Thay đổi kiến trúc, RLS, workbook workflow, Hangfire Prod, replica/DbContext, verify gate → bắt buộc ghi [memory/DECISIONS.md](../../memory/DECISIONS.md).
- **Verify (§4):** Trước khi báo xong: build BE (tắt BCDT.Api trước); nếu sửa FE → E2E `npm run test:e2e` (BE 5080); Postman khi sửa API. Completion (§5): task ID, file list, verify result, DECISIONS nếu có, project_state nếu >1 phiên.

---

## Decision triggers

Ghi entry vào [memory/DECISIONS.md](../../memory/DECISIONS.md) khi thay đổi thuộc nhóm (theo DECISIONS.md §5):

- RLS / session context (middleware, SP, policy, 503)
- Hangfire jobs đọc/ghi bảng RLS hoặc đổi context pattern
- Workbook flow (contract, thứ tự sync, resolver/binding)
- Dashboard / replica / DbContext strategy
- Production/deployment (env, timeout, rate limit, CORS, JWT, secrets)
- Verify gates (build/E2E/Postman)
- DB schema/migrations có rủi ro production

---

## Phase 1 – Điều phối theo TONG_HOP và Production readiness

| Task | Mô tả | Log |
|------|--------|-----|
| Task 1.1 | Theo dõi ưu tiên 1 (Prod), block Cách giao AI 3.9, verify, cập nhật TONG_HOP | [Task_1_1_Theo_doi_uu_tien_1_Prod.md](Phase_01_TONG_HOP_Production_readiness/Task_1_1_Theo_doi_uu_tien_1_Prod.md) |
| Task 1.2 | Rà RUNBOOK 10 & REVIEW_PRODUCTION_CA_NUOC khi go-live (Depends on 1.1) | [Task_1_2_Ra_RUNBOOK_10_REVIEW_PRODUCTION.md](Phase_01_TONG_HOP_Production_readiness/Task_1_2_Ra_RUNBOOK_10_REVIEW_PRODUCTION.md) |
| Task 1.3 | (Tùy chọn) Công việc tùy chọn TONG_HOP 3.7 (Depends on 1.1) | [Task_1_3_Cong_viec_tuy_chon_TONG_HOP_3_7.md](Phase_01_TONG_HOP_Production_readiness/Task_1_3_Cong_viec_tuy_chon_TONG_HOP_3_7.md) |

**Phase summary:** Điều phối theo TONG_HOP và Production readiness. Trạng thái Phase 1 chờ User kích hoạt khi cần go-live.

---

## Phase 2 – Sprint 1: Bảo mật & Nền tảng kiểm thử

**Hoàn thành:** 2026-02-27 · **4/4 tasks** · Build pass

| Task | Mô tả | Trạng thái | Log |
|------|--------|------------|-----|
| Task 2.1 | JWT Token Storage: localStorage → in-memory + httpOnly cookie `bc_refresh_token` | ✅ Done | [Task_2_1_JWT_Storage_Fix.md](Phase_02_Sprint_1_Security_Quality/Task_2_1_JWT_Storage_Fix.md) |
| Task 2.2 | Auth Minor Gaps: Refresh token rotation + Permission-based authorization handler | ✅ Done | [Task_2_2_Auth_Minor_Gaps.md](Phase_02_Sprint_1_Security_Quality/Task_2_2_Auth_Minor_Gaps.md) |
| Task 2.3 | CI/CD Pipeline: GitHub Actions build BE + FE tự động khi push/PR lên main | ✅ Done | [Task_2_3_CICD_Pipeline.md](Phase_02_Sprint_1_Security_Quality/Task_2_3_CICD_Pipeline.md) |
| Task 2.4 | Backend Unit Tests: BCDT.Tests project, 15 tests (FormDefinition, Submission, Auth) pass | ✅ Done | [Task_2_4_Backend_Unit_Tests.md](Phase_02_Sprint_1_Security_Quality/Task_2_4_Backend_Unit_Tests.md) |

**Phase summary:** Sprint 1 hoàn thành toàn bộ. Điểm cần theo dõi: (1) `FormDefinitionService.GetByIdAsync` trả `Result.Ok(null)` thay vì NOT_FOUND – nên fix ở sprint sau; (2) CI cần push lên `main` để xác nhận green lần đầu; (3) E2E đầy đủ cần BE chạy tại port 5080.

---

## Phase 3 – Sprint 2: Nghiệp vụ & Business Gaps

**Hoàn thành:** 2026-02-27 · **6/6 tasks** · Build pass

| Task | Mô tả | Trạng thái |
|------|--------|------------|
| S2.4 FE | Nút Nhân bản form (Clone) trong FormsPage | ✅ Done |
| S2.5 BE | UserDelegation BE API (Full/Partial, overlap check, soft-revoke) | ✅ Done |
| Task 2.6 | GET /report-summaries/{id}/details – Drilldown API | ✅ Done |
| Task 2.7 | GET /reporting-periods/{id}/export-summary – PeriodSummaryExport | ✅ Done |
| Task 2.8 | Validation required row khi nộp báo cáo | ✅ Done |
| Task 2.9 | POST /forms/{id}/clone – CloneAsync deep copy | ✅ Done |
| CK-02 | Hangfire auto-create reporting period job (daily 1AM UTC) | ✅ Done |

**Phase summary:** Toàn bộ business gaps Sprint 2 đã xử lý. Tests: 15 pass. Build clean. UserDelegation BE sẵn sàng; FE sẽ được bổ sung Sprint 4.

---

## Phase 4 – Sprint 3+4: UX Overhaul + Quality + Zero-Warning

**Hoàn thành:** 2026-03-02 · **10/10 tasks** · Build 0 warnings 0 errors · 24 tests

| Task | Mô tả | Trạng thái |
|------|--------|------------|
| S3.1 | FormConfigPage split: 2670 → 166 lines + 12 section components | ✅ Done |
| S3.2 | SubmissionDataEntryPage UX: loading/error/boundary | ✅ Done |
| S3.3 | Dashboard filter theo kỳ báo cáo + export CSV | ✅ Done |
| S3.4 | Error handling UX: ErrorBoundary + ErrorPage | ✅ Done |
| S3.5 | Loading & empty states: PageSkeleton + EmptyState | ✅ Done |
| S4.1 | UserDelegations FE: trang quản lý ủy quyền tạm thời | ✅ Done |
| S4.2 | FluentValidation cho CreateUserDelegationRequest | ✅ Done |
| S4.3 | Seed menu Ủy quyền người dùng (script 29) | ✅ Done |
| S4.4 | xUnit unit tests UserDelegationService (9 tests mới, tổng 24) | ✅ Done |
| S4.5 | Zero-warning build: Directory.Build.props + CI -warnaserror + test step | ✅ Done |

**Phase summary:** UX cải thiện đáng kể (FormConfig tách nhỏ, error handling, loading states). UserDelegation hoàn chỉnh BE+FE+Tests. CI pipeline robust: full solution build -warnaserror + dotnet test. Build: **0 warnings, 0 errors, 24 tests pass**.
