# AI Project Snapshot – BCDT

Snapshot cho **AI orchestration planning**: cấu trúc dự án, stack, ranh giới module, luồng dữ liệu, rủi ro và gợi ý phân công. Chỉ ghi nội dung phát hiện từ repo; không rõ ghi **Not detected**.

**Cập nhật:** 2026-02-26

---

## 1. Project

- **Mục đích:** Hệ thống báo cáo điện tử động — biểu mẫu Excel định nghĩa động, nhập liệu web, workflow phê duyệt, tổng hợp, dashboard; thu thập/nộp/duyệt/tổng hợp báo cáo theo kỳ từ đơn vị phân cấp 5 cấp.
- **Trạng thái:** MVP 17 tuần xong (Phase 1–4, W16–W17). BE: 28 Controllers, 38+ Services, 59 bảng. FE: 12 trang, 5 E2E specs (21 tests), Postman ~150. **Ưu tiên:** Theo dõi triển khai production (TONG_HOP 3.1, 3.9; RUNBOOK 10).

---

## 2. Stack (one place)

| Layer | Tech |
|-------|------|
| **BE** | .NET 8, Kestrel, REST `/api/v1/`, JWT, FluentValidation, Rate limit, Brotli/Gzip. EF Core 8 (primary + optional ReadReplica), Dapper (DataSourceQuery). Hangfire (SQL). Health: DB + Redis (nếu cấu hình). |
| **FE** | React 19, Vite 7, TS 5.9. Ant Design 6, Fortune-sheet (Excel nhập liệu), DevExtreme 24 (một số màn). React Query, React Router 7, ProtectedRoute. Playwright E2E. |
| **DB** | SQL Server (BCDT, 59 bảng `BCDT_`). Scripts `docs/script_core/sql/v2/` 01→22. RLS + session context (`sp_SetUserContext` / `sp_SetSystemContext`). |
| **Cache** | Redis hoặc in-memory (IDistributedCache). ICacheService cho master data (ReportingFrequency, OrganizationType, DataSource, FilterDefinition, IndicatorCatalog). |
| **Queue** | Not detected (Hangfire = job store SQL, không phải message queue). |
| **Deploy** | Monolith. MVP: single host (React 3000, API 5080, SQL, Redis tùy chọn). Production: xem RUNBOOK 10, script_core/02.KIEN_TRUC_TONG_QUAN. |

---

## 3. Module boundaries (for routing & scope)

**Backend:** API → Application → Domain ← Infrastructure. Api: Controllers/ApiV1, Middleware. Application: I*Service, DTOs, Common, Validators. Domain: Entities (không ref layer khác). Infrastructure: DbContext, service impl, Hangfire, Excel/PDF, DataBindingResolver, BuildWorkbookFromSubmissionService, SyncFromPresentationService, DataSourceQueryService.

**Frontend:** `src/bcdt-web/src`: api (clients), context (Auth, RolePermissions), pages, components, hooks, types, routes.

**10 domain (map task → layer):**

| # | Domain | Ghi chú |
|---|--------|--------|
| 1 | Organization | 4 bảng; cây 5 cấp |
| 2 | Authorization | 9 bảng; Role, Permission, Menu, DataScope, UserDelegation |
| 3 | Authentication | JWT, refresh, session context |
| 4 | Form Definition | 8+ bảng; B12/P8 (chỉ tiêu động, lọc động, placeholder) |
| 5 | Data Storage | ReportSubmission, ReportPresentation, ReportDataRow, ReportSummary, Audit |
| 6 | Workflow | Submit / approve / reject / revision |
| 7 | Reporting Period | Kỳ báo cáo, aggregation |
| 8 | Reference data | ReferenceEntityType, ReferenceEntity (EAV) |
| 9 | Notification | In-app, email (mock) |
|10 | System config | SystemConfig |

**Orchestration:** Task → tài liệu + Agent/Skill theo TONG_HOP 3.2 và block "Cách giao AI" (3.3, 3.5, 3.7). Agent theo domain: bcdt-auth-expert, bcdt-org-admin, bcdt-hierarchical-data, bcdt-form-structure-indicators, bcdt-workflow-designer, bcdt-business-reviewer (review nghiệp vụ).

---

## 4. Data flow (key paths only)

- **Pipeline:** Request → Trace → Exception → Compression → CORS → Auth (JWT) → RateLimit → SessionContext (RLS) → Authorization → Controller → I*Service → DbContext/Dapper → ApiResponse `{ success, data | errors }`. Pagination max 500.
- **Nhập liệu:** Form config → BuildWorkbookFromSubmissionService → GET workbook-data → FE Fortune-sheet → PUT report-presentations → SyncFromPresentationService → ReportDataRow + ReportSummary.
- **Workflow:** Submit/Approve/Reject/Revision → WorkflowExecutionService; NotificationService (mock email).
- **Dashboard:** DashboardService (AppDbContext khi RLS; không dùng ReadReplica cho Dashboard).
- **Integrations:** Not detected (email mock, file local).

---

## 5. DevOps & verify gates

- **CI/CD:** Not detected.
- **Test:** E2E Playwright 5 specs (21 tests) trong `src/bcdt-web`, BE 5080; Postman ~150; UAT script `run-w17-uat.ps1`. Không có *Tests*.csproj BE.
- **Branching / Code review:** Not detected.

**Verify gates (orchestration):** Trước khi báo xong: build (tắt process BCDT.Api trước build BE); nếu sửa FE → `npm run test:e2e`, báo Pass/Fail từng spec; checklist "Kiểm tra cho AI" hoặc Postman theo task. Chi tiết: E2E_VERIFY.md, always-verify-after-work rule.

---

## 6. Technical debt & risks

- **Phức tạp:** BuildWorkbookFromSubmissionService, SyncFromPresentationService, DataBindingResolver (B12/P8, cache batch đã làm Perf-8, Perf-12). RLS + ReadReplica: Dashboard dùng AppDbContext (Prod-3); Hangfire job gọi sp_SetSystemContext (Prod-8). SessionContext lỗi → 503 (Prod-11).
- **Circular deps:** Not detected (Api→App+Infra, App→Domain, Infra→Domain+App).
- **Production:** Prod-1..Prod-15 đã ghi xong; rà RUNBOOK 10 khi deploy thật (REVIEW_PRODUCTION_CA_NUOC).

---

## 7. Active work & orchestration anchors

- **Ưu tiên theo dõi:** Triển khai production (TONG_HOP 3.1, 3.9; REVIEW_PRODUCTION_CA_NUOC, RUNBOOK 10).
- **Hot modules (planning):** Form & Submission (B12, P8) — FormConfig, SubmissionDataEntry, workbook-data, BuildWorkbook/Sync; Auth & RBAC (mọi request); Dashboard & Reporting (aggregation, Hangfire).
- **Task source:** TONG_HOP mục 3.2 (bảng Task → Tài liệu · Rules · Agent · Skill), mục 3.3/3.5/3.7 (block Cách giao AI). Workflow: Plan → Execute → Verify → Reflect (bcdt-agentic-workflow).

---

## References

| Doc | Use |
|-----|-----|
| [AI_CONTEXT.md](AI_CONTEXT.md) | Task map, rules, agent/skill |
| [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) | Ưu tiên, block giao AI |
| [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md) | Cây thư mục, 10 module |
| [RUNBOOK.md](RUNBOOK.md) | Chạy, build (6.1), E2E, Prod (10) |
| [E2E_VERIFY.md](E2E_VERIFY.md) | Khi chạy E2E, spec list |
| [REVIEW_PRODUCTION_CA_NUOC.md](REVIEW_PRODUCTION_CA_NUOC.md) | Rủi ro production |
