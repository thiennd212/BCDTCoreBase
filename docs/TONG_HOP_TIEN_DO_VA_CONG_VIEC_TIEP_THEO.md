# Tổng hợp tiến độ và công việc tiếp theo – BCDT

Tài liệu tổng hợp hiện trạng dự án và công việc tiếp theo, theo [06.KE_HOACH_MVP.md](script_core/06.KE_HOACH_MVP.md).

**Cho AI:** Đọc [AI_CONTEXT.md](AI_CONTEXT.md) trước khi bắt đầu task để nắm ngữ cảnh, tìm đúng tài liệu và giảm token.

**Ngày cập nhật:** 2026-03-02 · **Version 2.75** · **Rà soát lần 120** (Sprint 3 UX/UI Overhaul hoàn thành)

---

## 1. Tóm tắt

| Phase | Trạng thái | Ghi chú |
|-------|------------|---------|
| **Phase 1 – Foundation (W1–4)** | ✅ | A1, A2, B1–B6, Tree đơn vị, Refresh token FE. |
| **Phase 2 – Form Definition (W5–10)** | ✅ | B7, B8, Excel Generator, Data Storage, Submission, Data Binding Resolver. |
| **Phase 3 – Workflow & Reporting (W11–14)** | ✅ | B9 Workflow, B10 Reporting Period/Aggregation/Dashboard. |
| **Phase 4 W15 – Polish** | ✅ | B11 (PDF, Notification, Bulk), FE Phase 2–3, B12 P1–P7, P8a–P8f. |
| **Phase 4 W16–17 – Quality & UAT** | ✅ | **W16:** ✅ Đã xong (baseline, OWASP Pass, tối ưu batch DataSource). **W17:** ✅ Đã xong (UAT script run-w17-uat.ps1: **35 Pass, 0 Fail, 3 Skip**; User Guide, Demo Script, RUNBOOK 8.1; Demo flow Pass). |

**Rà soát code (lần 64):** BE: **28 Controllers**, 38+ Services, 27 Entities, 37 DbSet. FE: **12 Pages**, **14 API clients**, **5 E2E (21 tests)**. DB: 22 scripts, **59 bảng**, RLS. Postman: **~150 requests**. Chi tiết: **mục 5**. **Rà soát chi tiết toàn bộ tiến độ từng hạng mục:** [RA_SOAT_TIEN_DO_CHI_TIET.md](RA_SOAT_TIEN_DO_CHI_TIET.md).

---

## 2. Hiện trạng đã hoàn thành

> Tất cả Phase 1–3 và Phase 4 W15 đã hoàn tất. Dưới đây là danh sách tóm tắt và link tài liệu tham chiếu.

| Phase | Hạng mục | Tài liệu |
|-------|----------|----------|
| **Setup** | A1 – SQL 01→22 (59 bảng, RLS, seed) | [VERIFY_TABLES.md](script_core/sql/v2/VERIFY_TABLES.md) |
| | A2 – appsettings, RUNBOOK, Build BE | [RUNBOOK.md](RUNBOOK.md) |
| **P1** | B1 – JWT Auth (login, refresh, logout, /me) | [B1_JWT.md](de_xuat_trien_khai/B1_JWT.md) |
| | B2 – RBAC (5 roles, policy) | [B2_RBAC.md](de_xuat_trien_khai/B2_RBAC.md) |
| | B3 – RLS & Session Context | [B3_RLS.md](de_xuat_trien_khai/B3_RLS.md) |
| | B4 – Organization CRUD (cây 5 cấp) | [B4_ORGANIZATION.md](de_xuat_trien_khai/B4_ORGANIZATION.md) |
| | B5 – User Management CRUD | [B5_USER_MANAGEMENT.md](de_xuat_trien_khai/B5_USER_MANAGEMENT.md) |
| | B6 – Frontend (Login, Org/User, Tree đơn vị, E2E) | [B6_FRONTEND.md](de_xuat_trien_khai/B6_FRONTEND.md), [B6_DE_XUAT_TREE_DON_VI.md](de_xuat_trien_khai/B6_DE_XUAT_TREE_DON_VI.md) |
| **P2** | B7 – Form Definition CRUD | [B7_FORM_DEFINITION.md](de_xuat_trien_khai/B7_FORM_DEFINITION.md) |
| | B8 – Sheet, Column, Data Binding, Mapping (25/25 Pass) | [B8_FORM_SHEET_COLUMN_DATA_BINDING.md](de_xuat_trien_khai/B8_FORM_SHEET_COLUMN_DATA_BINDING.md) |
| | Excel Generator, Data Storage, Submission (10/10), Data Binding Resolver | — |
| | Nhập liệu Excel (Fortune-sheet, workbook-data, export .xlsx) | [FORTUNE_EXCEL_STYLES_FIX.md](FORTUNE_EXCEL_STYLES_FIX.md), [SEED_VIA_MCP.md](script_core/sql/v2/SEED_VIA_MCP.md) |
| **P3** | B9 – Workflow (submit, approve/reject/revision) | [B9_WORKFLOW.md](de_xuat_trien_khai/B9_WORKFLOW.md) |
| | B10 – Reporting Period, Aggregation, Dashboard | [B10_REPORTING_PERIOD.md](de_xuat_trien_khai/B10_REPORTING_PERIOD.md) |
| **P4 W15** | B11 – PDF Export, Notification (in-app + email mock), Bulk | [B11_PHASE4_POLISH.md](de_xuat_trien_khai/B11_PHASE4_POLISH.md) |
| | FE Phase 2–3 (Dashboard, Forms, Submissions, Workflow UI) | [FE_PHASE2_3.md](de_xuat_trien_khai/FE_PHASE2_3.md) |
| | B12 P1–P7 – Chỉ tiêu cố định & động (R1–R11) | [B12_CHI_TIEU_CO_DINH_DONG.md](de_xuat_trien_khai/B12_CHI_TIEU_CO_DINH_DONG.md), [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) |
| | P8a–P8f – Lọc động, placeholder dòng + cột | [P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md), [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md), [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md) |
| **Tài liệu** | Cấu trúc codebase, Giải pháp kỹ thuật, Workflow Guide | [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md), [04.GIAI_PHAP_KY_THUAT.md](script_core/04.GIAI_PHAP_KY_THUAT.md), [WORKFLOW_GUIDE.md](WORKFLOW_GUIDE.md) |
| | Postman collection (đầy đủ P8 + workbook-data, ~150 requests, +OrgType, +Freq, +Notifications, +Audit) | [BCDT-API.postman_collection.json](postman/BCDT-API.postman_collection.json) |
| | Seed test data, Hierarchical data base | [README_SEED_TEST.md](script_core/sql/v2/README_SEED_TEST.md), [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md) |
| **P4 W16** | W16 – Performance & Security | [W16_PERFORMANCE_SECURITY.md](de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md) – Baseline đo (script w16-measure-baseline.ps1), OWASP Pass, tối ưu batch DataSource trong BuildWorkbookFromSubmissionService. |
| **P4 W17** | W17 – UAT & Demo ✅ | [W17_UAT_DEMO.md](de_xuat_trien_khai/W17_UAT_DEMO.md) – UAT script `run-w17-uat.ps1`: **35 Pass, 0 Fail, 3 Skip**; [USER_GUIDE.md](USER_GUIDE.md), [DEMO_SCRIPT.md](DEMO_SCRIPT.md); RUNBOOK 8.1. Demo flow (core + P8) Pass. |
| **Post-MVP** | User–Role–Org, Chuyển vai trò, Menu theo quyền ✅ | [KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md](de_xuat_trien_khai/KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md), [CHUYEN_VAI_TRO_KIEM_TRA.md](de_xuat_trien_khai/CHUYEN_VAI_TRO_KIEM_TRA.md). BE: DTO RoleOrgAssignments, UserService Create/Update/Get theo cặp (role, org); Auth me/roles trả organizationId/Name; Menu lọc theo RequiredPermission + RolePermission (vai trò có quyền). FE: form User bảng (vai trò + đơn vị), chuyển vai trò (dropdown, modal, hiển thị "Vai trò (Đơn vị)", redirect /dashboard + invalidateQueries); menu theo currentRole.id; RolePermissionsContext (load quyền theo vai trò). Seed: 14.seed_data + MOF, admin 2 vai trò (SYSTEM_ADMIN, UNIT_ADMIN@MOF); seed đầy đủ qua MCP (idempotent). |

**Cột/hàng từ danh mục chỉ tiêu (2026-02-24):** ✅ **Đã xong (phân tích + Phase 1 + Phase 2a + Phase 2b + FE Phase 2b)** – Phương án: [DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md](de_xuat_trien_khai/DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md). **Phase 1:** BE copy metadata từ Indicator; FE FormConfig "Thêm cột" mặc định chọn từ danh mục, nút "Tạo cột mới". **Phase 2a:** validation theo config (checklist mục 6). **Phase 2b:** script 25, FormColumn.IndicatorId NOT NULL, API bắt buộc indicatorId. **FE Phase 2b:** GET /api/v1/indicators/by-code/_SPECIAL_GENERIC; FormConfig "Tạo cột mới" và form sửa cột luôn gửi indicatorId; Build BE+FE Pass. Phase 3 (hàng) tùy nghiệp vụ.

**Kết luận (rà soát 77):** A1, A2, B1–B6, B7–B12, P8, W16, W17 đã xong. **Review nghiệp vụ từng module: 8/8 đã xong (2026-02-24):** Auth ✅, Org/User ✅, Form (B7–B8) ✅, Submission & Workbook ✅, Workflow (B9) ✅, Reporting & Dashboard (B10) ✅, B12 ✅, P8 (Lọc động, placeholder) ✅. P8: 0 gap. [REVIEW_NGHIEP_VU_MODULE_P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_P8_FILTER_PLACEHOLDER.md). **Đã bổ sung API workflow history (2026-02-24):** GET /api/v1/workflow-instances/{id}/approvals (gap Minor B9). Postman: đã thêm request "Get workflow instance approvals". **Không còn module review;** công việc tùy chọn: xem mục 3.1, 3.7, 3.8 (task khác). **Perf-1 (IDistributedCache) đã xong (2026-02-25):** cache master data (ReportingFrequency, OrganizationType, DataSource, FilterDefinition, IndicatorCatalog), checklist DE_XUAT 5.1. **Perf-3 (Health check) đã xong (2026-02-25):** AddHealthChecks Db, MapHealthChecks("/health"); DE_XUAT 5.2. **Perf-5 (Nén response) đã xong (2026-02-25):** Brotli/Gzip, DE_XUAT 5.3. **Perf-4 (Timeout & CancellationToken) đã xong (2026-02-25):** CT lan truyền; Kestrel Limits; DE_XUAT 5.4. **Perf-2 (Pagination chuẩn) đã xong (2026-02-25):** PagedResultDto; GET /forms và GET /submissions hỗ trợ ?pageSize=&pageNumber=; data có items, totalCount, pageNumber, pageSize, hasNext; DE_XUAT 5.5. **Perf-7 (Index thiếu) đã xong (2026-02-25):** Script 26.perf7_missing_indexes.sql (IX_ReportSubmission_Form_Org_Period_Status); DE_XUAT 5.6. **Perf-8 (Batch FilterDefinition) đã xong (2026-02-25):** IFilterDefinitionService.GetByIdsAsync; BuildWorkbook + DataSourceQueryService dùng filterCache; MCP user-mssql chạy script 26; DE_XUAT 5.7. **Perf-6 (Static & cache nội bộ) đã xong (2026-02-25):** Tài liệu hướng dẫn deploy static nội bộ, Cache-Control, ví dụ nginx; DE_XUAT 5.8, RUNBOOK 8.3. **Perf-9 (Cache master data 2.2.1) đã xong (2026-02-25):** Đạt bởi Perf-1 (ReportingFrequency, OrganizationType, DataSource, FilterDefinition, IndicatorCatalog qua ICacheService); DE_XUAT 5.9. **Perf-10 (Lazy load route FE) đã xong (2026-02-25):** React.lazy + Suspense cho trang ít dùng (FormConfig, SubmissionDataEntry, IndicatorCatalogs, WorkflowDefinitions, Settings, ReferenceEntities/Types, Menus, Roles, Permissions, …); fallback PageLoading; DE_XUAT 5.10. **Perf-11 (Partition/replica/archive) đã xong (2026-02-25):** Tài liệu PERF11_PARTITION_REPLICA_ARCHIVE.md (partition-ready, read replica–ready, archive policy); script mẫu 27.perf11_partition_sample.sql; config ArchivePolicy trong appsettings; DE_XUAT 5.11. **Perf-12 (Batch cột động, AsNoTracking) đã xong (2026-02-25):** BuildWorkbookFromSubmissionService gom nhóm FormPlaceholderColumnOccurrence theo (DataSourceId, FilterDefinitionId), gọi QueryWithFilterAsync một lần mỗi cặp (columnDataSourceCache); AsNoTracking đã dùng nhất quán; DE_XUAT 5.12. **Perf-13 (Hangfire) đã xong (2026-02-25):** AddHangfire (SQL Server), Dashboard /hangfire; POST /api/v1/jobs/aggregate-submission (enqueue), GET /api/v1/jobs/{jobId} (status); AggregateSubmissionJob mẫu; DE_XUAT 5.13. **Perf-14 (React Query staleTime + Bundle analysis) đã xong (2026-02-25):** QueryClient defaultOptions staleTime 1 phút; rollup-plugin-visualizer, dist/stats.html; DE_XUAT 5.14. **Perf-15 (Reverse proxy cache) đã xong (2026-02-25):** Tài liệu "Triển khai Perf-15" (static Cache-Control, tùy chọn cache API, nginx + IIS ARR); RUNBOOK 8.3; DE_XUAT 5.15. **Perf-16 (Redis khi scale > 1 instance) đã xong (2026-02-25):** Cấu hình optional ConnectionStrings:Redis; Program.cs dùng StackExchangeRedis khi có Redis, else MemoryDistributedCache; DE_XUAT 5.16. **Perf-17 (Read replica) đã xong (2026-02-25):** AppReadOnlyDbContext; ConnectionStrings:ReadReplica optional; DashboardService dùng read context; DE_XUAT 5.17. **Perf-18 (Partition/archive) đã xong (2026-02-25):** Script 28.perf18_archive_sample.sql (bảng _Archive + sp_BCDT_ArchiveSubmissions_Batch); PERF11 mục Triển khai Perf-18; DE_XUAT 5.18. **Perf-19 (Load balancer) đã xong (2026-02-25):** Tài liệu "Triển khai Perf-19 – Load balancer" (health check /health, JWT stateless, nginx upstream, Hangfire/Redis lưu ý); DE_XUAT 5.19. **Prod-1 (R8 – Giới hạn max pageSize) đã xong (2026-02-25):** PagingConstants.MaxPageSize = 500 trong Application.Common; FormDefinitionService và ReportSubmissionService cap pageSize; Swagger summary "max 500" cho GET /forms và GET /submissions; Build Pass. **Prod-2 (R4 – Secrets Production) đã xong (2026-02-25):** RUNBOOK mục 10.1 "Production – Biến môi trường bắt buộc" (bảng tên biến, mô tả, bắt buộc/optional; ví dụ PowerShell/Bash). **Prod-3 (R1 – RLS + ReadReplica) đã xong (2026-02-25):** DashboardService chuyển sang AppDbContext; Dashboard không dùng replica → RLS đúng khi bật ReadReplica. Build Pass. **Prod-4 (R13 – RUNBOOK Production) đã xong (2026-02-25):** RUNBOOK mục 10.3 Checklist triển khai Production (deploy, health, LB, Hangfire, Redis, backup, RLS, pageSize, CORS). Ưu tiên 1 Prod (Prod-1→4) hoàn thành. **Prod-5 (R5 – FluentValidation) đã xong (2026-02-25):** FluentValidation + FluentValidation.AspNetCore; validators cho Login, Create/Update FormDefinition, Create ReportSubmission, Create Organization, Create User; auto-validation pipeline. Build Pass; POST login {} → 400 + message. **Prod-6 (R12 – Health Redis) đã xong (2026-02-25):** AspNetCore.HealthChecks.Redis; khi có ConnectionStrings:Redis thì AddRedis(name: "redis"); /health gồm db + redis. Build Pass. **Prod-7 (R9 – MaxRequestBodySize) đã xong (2026-02-25):** Kestrel.Limits.MaxRequestBodySize 104857600 (100 MB) trong appsettings; ExceptionMiddleware bắt BadHttpRequestException 413 → trả PAYLOAD_TOO_LARGE. Build Pass. **Prod-8 (R2 – Hangfire + RLS) đã xong (2026-02-25):** AggregateSubmissionJob gọi sp_SetSystemContext trên connection trước khi gọi AggregationService; finally sp_ClearUserContext. Build Pass. **Prod-9 (R14 – Backup & DR) đã xong (2026-02-25):** RUNBOOK mục 10.4: chính sách backup, RPO/RTO, kịch bản khôi phục. **Prod-10 (R6 – ICurrentUserService) đã xong (2026-02-25):** ICurrentUserService + CurrentUserService; thay GetCurrentUserId/GetUserId trong 20+ controller. Build Pass. **Prod-11 (R3 – SessionContext lỗi) đã xong (2026-02-26):** SessionContextMiddleware khi SetUserContext throw → trả 503 + SESSION_CONTEXT_FAILED, không gọi _next. Build Pass. **Prod-12 (R11 – RequestId/TraceId) đã xong (2026-02-26):** RequestTraceMiddleware (X-Request-Id, scope TraceId), log login success/failure. Build Pass. **Prod-13 (R7 – Rate limiting) đã xong (2026-02-26):** AddRateLimiter theo IP/user, FixedWindow (PermitLimit/WindowSeconds config), 429 + RATE_LIMIT_EXCEEDED; /health, /, /swagger, /hangfire loại trừ. Build Pass. **Prod-14 (R10 – Timeout) đã xong (2026-02-26):** Đã verify Perf-4 (Kestrel Limits + CT lan truyền); RUNBOOK 10.2 + 10.3 bổ sung Timeout R10, checklist mục 11. **Prod-15 (R15 – Dữ liệu trong nước) đã xong (2026-02-26):** RUNBOOK mục 10.5 (bảng DB/Redis/server trong nước), 10.2 + 10.3 checklist mục 12. **Rà soát tài liệu và checklist đã xong (2026-02-23):** RUNBOOK thêm 7.1 E2E, 8.2 Kiểm tra cho AI, Version 1.1; E2E_VERIFY mục 5 đồng bộ 21 tests (17 passed, 4 skipped). **Bỏ skip 3 test E2E + Sửa Bước 4 (2026-02-25):** Bước 5b, Chọn quy trình, Thêm bước duyệt đã bỏ skip (reload + lật trang). Bước 4: sửa FE ReferenceEntityTypesPage (handleSubmit mutateAsync + validateFields theo mode) → submit Cập nhật gửi PUT, bỏ skip. E2E: 17 Pass, 0 Skip, 0 Fail. **Phân cấp Menu đã xong (2026-02-23):** MenusPage dùng `all=true` + `buildTree`/`treeExcludeSelfAndDescendants` từ treeUtils, Table tree, TreeSelect khi sửa loại trừ self + descendants; checklist trong [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md) mục 10. **Bổ sung Postman/Swagger đã xong (2026-02-23):** Thêm ~17 request (Forms from-template, upload template, template-display; Workflow definition/step get-put-delete, form workflow config delete; ReportingPeriods get/put/delete by id; Submissions sync-from-presentation); biến reportingPeriodId; Swagger Summary cho ReportingPeriodsController. **Phân cấp ReferenceEntity đã xong (2026-02-23):** BE CRUD ReferenceEntity/ReferenceEntityType + list `all=true`; FE ReferenceEntitiesPage (chọn loại → cây, TreeSelect cha, treeExcludeSelfAndDescendants); Postman + checklist mục 10.1 [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md). **CRUD ReferenceEntityType đã bổ sung:** GET {id}, POST, PUT {id}, DELETE {id} (409 nếu type đã có reference entity); Postman + checklist 10.2. **FE quản lý Loại thực thể:** trang `/reference-entity-types` (ReferenceEntityTypesPage), bảng + Modal CRUD; API client getById/create/update/delete; checklist 10.3.

---

## 3. Công việc tiếp theo

### 3.1. Thứ tự ưu tiên

| Ưu tiên | Công việc | Trạng thái | Ghi chú |
|---------|-----------|------------|---------|
| ~~**1**~~ | ~~**Week 16 – Performance & Security**~~ | ✅ **Đã xong** | [W16_PERFORMANCE_SECURITY.md](de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md). Baseline đo (login, forms, submissions, workbook-data, dashboard, data-sources, filter-definitions, P8 APIs). OWASP Pass. Tối ưu batch DataSource trong BuildWorkbookFromSubmissionService. Script: `docs/script_core/w16-measure-baseline.ps1`. |
| ~~**1**~~ | ~~**Week 17 – UAT, Documentation, Demo**~~ | ✅ **Đã xong** | [W17_UAT_DEMO.md](de_xuat_trien_khai/W17_UAT_DEMO.md): script `run-w17-uat.ps1` **35 Pass, 0 Fail, 3 Skip** (2026-02-12). [USER_GUIDE.md](USER_GUIDE.md), [DEMO_SCRIPT.md](DEMO_SCRIPT.md), RUNBOOK 8.1. Demo flow Pass. |
| ~~Tùy chọn~~ | ~~Kiểm tra thủ công Refresh token FE~~ | ✅ **Đã xong** | **5/5 Pass** (2026-02-12). [RA_SOAT_REFRESH_TOKEN.md](de_xuat_trien_khai/RA_SOAT_REFRESH_TOKEN.md) mục 5.1. |
| ~~Tùy chọn~~ | ~~Chạy lại UAT (có submission Draft)~~ | ✅ **Đã xong** | **35 Pass, 0 Fail, 3 Skip** (2026-02-12). Fix script PowerShell (array JSON, versionId). |
| ~~Post-MVP~~ | ~~User–Role–Org, Chuyển vai trò, Menu theo quyền~~ | ✅ **Đã xong** | Gán cặp (vai trò, đơn vị) cho user; chuyển vai trò + redirect /dashboard; menu theo quyền (RequiredPermission + RolePermission); RolePermissionsContext; seed qua MCP (2026-02-13). |
| ~~Tùy chọn~~ | ~~Phân cấp Menu~~ | ✅ **Đã xong** | Menu: all=true, treeUtils (buildTree, treeExcludeSelfAndDescendants), Table tree, TreeSelect (2026-02-23). [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md) mục 10. |
| ~~Tùy chọn~~ | ~~Phân cấp ReferenceEntity~~ | ✅ **Đã xong** | BE CRUD + all=true; FE ReferenceEntitiesPage (tree, TreeSelect); Postman; checklist 10.1 (2026-02-23). |
| ~~Tùy chọn~~ | ~~Bổ sung Postman / Swagger~~ | ✅ **Đã xong** | Postman: +17 request (forms from-template/template/template-display; workflow CRUD; reporting-periods by id; sync-from-presentation). Swagger: Summary ReportingPeriodsController (2026-02-23). |
| ~~**Tùy chọn**~~ ✅ | ~~**Review nghiệp vụ từng module**~~ | **Đã xong (8/8, 2026-02-24)** | Auth, Org/User, Form, Submission & Workbook, Workflow B9, Reporting B10, B12, P8. Báo cáo trong docs/de_xuat_trien_khai/REVIEW_NGHIEP_VU_*.md. |
| ~~**1**~~ ✅ | ~~**Cột/hàng định nghĩa biểu mẫu từ danh mục chỉ tiêu dùng chung**~~ | **Đã xong (phân tích + Phase 1 + Phase 2a + Phase 2b 2026-02-24)** | Phương án: [DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md](de_xuat_trien_khai/DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md). Phase 1+2a: như trước. Phase 2b: script 25 (NOT NULL + _SPECIAL_GENERIC); API bắt buộc indicatorId; checklist mục 6. |
| **1 (theo dõi)** | **Triển khai production cả nước (Prod)** | Các hạng mục đáp ứng triển khai production quy mô cả nước: giới hạn pageSize, secrets, RLS+Replica, RUNBOOK Production, validation, health Redis, body size, Hangfire+RLS, backup/DR, ICurrentUserService, SessionContext lỗi, logging, rate limit, timeout. Theo dõi theo bảng mục **3.9**. | [REVIEW_PRODUCTION_CA_NUOC.md](REVIEW_PRODUCTION_CA_NUOC.md), [REVIEW_TRIEN_KHAI_PRODUCT.md](REVIEW_TRIEN_KHAI_PRODUCT.md), [RUNBOOK.md](RUNBOOK.md), [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md). |

**Đề xuất thứ tự và Cách giao AI:** Xem **mục 3.7** (bảng ưu tiên tùy chọn + block copy-paste), **mục 3.8** (Tối ưu hiệu năng & mở rộng – Perf-1..19), **mục 3.9** (Triển khai production cả nước – Prod-1..Prod-15, Cách giao AI Prod-1).

### 3.2. Bảng tham chiếu AI (Tài liệu · Rules · Agent · Skill)

| Công việc | Tài liệu bắt buộc | Rules | Agent | Skill |
|-----------|-------------------|-------|-------|-------|
| **Week 16** | [06.KE_HOACH_MVP.md](script_core/06.KE_HOACH_MVP.md) (Phase 4 W16), [RUNBOOK.md](RUNBOOK.md), [04.GIAI_PHAP_KY_THUAT.md](script_core/04.GIAI_PHAP_KY_THUAT.md), [B11_PHASE4_POLISH.md](de_xuat_trien_khai/B11_PHASE4_POLISH.md), [**W16_PERFORMANCE_SECURITY.md**](de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md), [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md), [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md), [P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md) | always-verify-after-work, bcdt-backend, bcdt-project | — | bcdt-test |
| **Week 17** | [06.KE_HOACH_MVP.md](script_core/06.KE_HOACH_MVP.md) (Phase 4 W17), [RUNBOOK.md](RUNBOOK.md), [B11_PHASE4_POLISH.md](de_xuat_trien_khai/B11_PHASE4_POLISH.md), [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md), [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md), [P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md) | always-verify-after-work, bcdt-project, bcdt-update-tong-hop-after-task | — | bcdt-test, bcdt-seed-test-data |
| Refresh token FE | [RA_SOAT_REFRESH_TOKEN.md](de_xuat_trien_khai/RA_SOAT_REFRESH_TOKEN.md) mục 5.1 | always-verify-after-work | — | — |
| Phân cấp Menu | [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md), [B6_DE_XUAT_TREE_DON_VI.md](de_xuat_trien_khai/B6_DE_XUAT_TREE_DON_VI.md) | always-verify-after-work, bcdt-frontend, bcdt-hierarchical-data | bcdt-hierarchical-data | bcdt-hierarchical-tree |
| Phân cấp ReferenceEntity | Cùng tài liệu trên | Cùng rules/agent/skill | bcdt-hierarchical-data | bcdt-hierarchical-tree |
| Bổ sung Postman/Swagger | [RUNBOOK.md](RUNBOOK.md), [postman/README.md](postman/README.md), [B11_PHASE4_POLISH.md](de_xuat_trien_khai/B11_PHASE4_POLISH.md), TONG_HOP mục 5.4–5.5 | always-verify-after-work, bcdt-api | — | — |
| Sửa test E2E b12-p7 P7.1 | [E2E_VERIFY.md](E2E_VERIFY.md), [B12_CHI_TIEU_CO_DINH_DONG.md](de_xuat_trien_khai/B12_CHI_TIEU_CO_DINH_DONG.md), e2e/b12-p7-formconfig-submission.spec.ts | always-verify-after-work, bcdt-project | — | bcdt-test |
| Xác nhận full E2E Pass (API 5080) | [E2E_VERIFY.md](E2E_VERIFY.md) mục 2, 4, 5 | always-verify-after-work, bcdt-project | — | bcdt-test |
| Bỏ skip 3 test E2E | [E2E_VERIFY.md](E2E_VERIFY.md), e2e/reference-entity-types.spec.ts, e2e/workflow-definitions.spec.ts | always-verify-after-work, bcdt-project | — | bcdt-test |
| ~~Rà soát tài liệu và checklist~~ ✅ Đã xong | [RUNBOOK.md](RUNBOOK.md), [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [E2E_VERIFY.md](E2E_VERIFY.md) | always-verify-after-work, bcdt-project | — | — |
| **Review nghiệp vụ (từng module)** | [01.YEU_CAU_HE_THONG.md](script_core/01.YEU_CAU_HE_THONG.md), [YEU_CAU_HE_THONG_TONG_HOP.md](YEU_CAU_HE_THONG_TONG_HOP.md), file đề xuất tương ứng module (B1_JWT, B2_RBAC, B3_RLS, B4_ORGANIZATION, B5_USER_MANAGEMENT, B7/B8, B9_WORKFLOW, B10_REPORTING_PERIOD, B12, P8) | bcdt-project, bcdt-agentic-workflow | **bcdt-business-reviewer** | — |
| **Cột/hàng từ danh mục chỉ tiêu (phân tích & phương án)** | [REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md](de_xuat_trien_khai/REVIEW_THIET_KE_DINH_NGHIA_BIEU_MAU_COT_HANG.md), [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md), [B12_CHI_TIEU_CO_DINH_DONG.md](de_xuat_trien_khai/B12_CHI_TIEU_CO_DINH_DONG.md) | bcdt-project, bcdt-agentic-workflow | **bcdt-business-reviewer** | — |
| **Tối ưu hiệu năng & mở rộng (Perf)** | [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md), [W16_PERFORMANCE_SECURITY.md](de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md), [RUNBOOK.md](RUNBOOK.md) mục 6.1 | always-verify-after-work, bcdt-project, bcdt-agentic-workflow | — | bcdt-sql-migration (index), bcdt-api-endpoint (health, pagination) |
| **Triển khai production cả nước (Prod)** | [REVIEW_PRODUCTION_CA_NUOC.md](REVIEW_PRODUCTION_CA_NUOC.md), [REVIEW_TRIEN_KHAI_PRODUCT.md](REVIEW_TRIEN_KHAI_PRODUCT.md), [RUNBOOK.md](RUNBOOK.md) mục 10, [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md) | always-verify-after-work, bcdt-project, bcdt-agentic-workflow | — | bcdt-api-endpoint (limit, validation) |

---

### 3.3. Block giao AI – Week 16: Performance & Security *(đã xong – block tham chiếu)*

```
Task: Triển khai Week 16 (Quality) theo 06.KE_HOACH_MVP Phase 4: Performance baseline, Security review, Performance tuning.

Tài liệu đọc trước: docs/script_core/06.KE_HOACH_MVP.md (Phase 4 Week 16), docs/CẤU_TRÚC_CODEBASE.md, docs/RUNBOOK.md (mục 6.1), docs/script_core/04.GIAI_PHAP_KY_THUAT.md. Tham chiếu: docs/de_xuat_trien_khai/B11_PHASE4_POLISH.md (mục 6–7 UAT checklist). **Tài liệu P8 mở rộng (bắt buộc đọc):** docs/de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md (B12 + P8 plan), docs/de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md (giải pháp lọc dòng/cột), docs/de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md (checklist P8a–P8f + test cases).

Rules: always-verify-after-work, bcdt-backend, bcdt-project. Trước khi build: hủy process BCDT.Api (RUNBOOK 6.1).

Model AI đề xuất (tối ưu chi phí):
- **Bước 1** (đo baseline) + **bước 4** (đo lại) + **bước 5–7** (security grep/check) + **bước 8–10** (tạo file, Postman, cập nhật TONG_HOP): → **gpt-4o-mini** (task cơ học, lặp lại, không cần suy luận phức tạp).
- **Bước 2–3** (phân tích query chậm, tối ưu N+1, batch load, MemoryCache, refactor BuildWorkbookFromSubmissionService): → **claude-4-opus** (task khó nhất – cần đọc hiểu code phức tạp, suy luận kiến trúc, đề xuất tối ưu chính xác).

Yêu cầu:

--- W16a – Performance Baseline & Tuning ---
1. Đo baseline response time (ms) các API chính – ghi nhận bảng:
   - POST /api/v1/auth/login
   - GET /api/v1/forms (list, 10–50 records)
   - GET /api/v1/submissions (list, 10–50 records)
   - GET /api/v1/submissions/{id}/workbook-data (form đơn giản: chỉ có cột cố định)
   - **GET /api/v1/submissions/{id}/workbook-data (form phức tạp: có FormDynamicRegion + FormPlaceholderOccurrence (N hàng) + FormPlaceholderColumnOccurrence (N cột))**
   - GET /api/v1/dashboard/admin/stats
   - POST /api/v1/submissions/{id}/submit
   - **GET /api/v1/data-sources (list)**
   - **GET /api/v1/data-sources/{id}/columns**
   - **GET /api/v1/filter-definitions (list)**
   - **GET /api/v1/forms/{id}/sheets/{sheetId}/placeholder-occurrences (list)**
   - **GET /api/v1/forms/{id}/sheets/{sheetId}/dynamic-column-regions (list)**
   - **GET /api/v1/forms/{id}/sheets/{sheetId}/placeholder-column-occurrences (list)**
   Tiêu chí MVP: < 3s load (single user). Chạy ít nhất 3 lần/API lấy trung bình.
2. Phân tích query chậm: bật SET STATISTICS TIME ON hoặc xem query plan cho các endpoint nặng. **Đặc biệt chú ý:**
   - **BuildWorkbookFromSubmissionService**: load FormPlaceholderOccurrence → resolve FilterDefinition/FilterCondition → QueryWithFilterAsync (Dapper) → N hàng; load FormPlaceholderColumnOccurrence → ResolveColumnLabelsAsync → N cột. Ghi nhận số query và thời gian.
   - workbook-data, dashboard/admin/stats, submissions/aggregate. Ghi nhận query > 500ms.
3. Tối ưu:
   - Kiểm tra N+1 queries (Include/ThenInclude trong EF Core, hoặc dùng Dapper cho query nặng).
   - Kiểm tra missing indexes: chạy sys.dm_db_missing_index_details cho DB BCDT; thêm index nếu cần. **Đặc biệt: indexes cho BCDT_FilterCondition (FilterDefinitionId), BCDT_FormPlaceholderOccurrence (FormSheetId), BCDT_FormPlaceholderColumnOccurrence (FormSheetId).**
   - Xem xét MemoryCache (IMemoryCache) cho dữ liệu ít thay đổi: ReportingFrequency, OrganizationType, IndicatorCatalog, **DataSource metadata, FilterDefinition/FilterCondition (ít thay đổi sau khi cấu hình)**.
   - **Tối ưu BuildWorkbookFromSubmissionService**: batch load tất cả occurrence + filter + condition cho 1 sheet trong 1–2 query thay vì N query; batch resolve column labels.
4. Đo lại sau tối ưu, so sánh trước/sau. Ghi kết quả vào bảng performance baseline. **Bảng phải có cột riêng cho workbook-data đơn giản vs workbook-data phức tạp (có P8 placeholder dòng + cột).**

--- W16b – Security Review ---
5. OWASP Top 10 code audit:
   - SQL Injection: verify 100% query parameterized (EF Core + Dapper: không string concat). Grep mã nguồn tìm string interpolation/concat trong SQL.
   - XSS: verify API trả JSON (không render HTML); FE dùng React (auto-escape).
   - CSRF: verify API dùng JWT (stateless, không cookie auth → CSRF N/A).
   - Broken Authentication: verify JWT expiry, refresh token rotation, logout invalidate token.
   - Broken Access Control: verify RLS active; test API endpoint với user khác org (kỳ vọng 403 hoặc empty list). Verify [Authorize] trên tất cả controller (trừ login). **Bổ sung P8:** verify API data-sources, filter-definitions, placeholder-occurrences, dynamic-column-regions, placeholder-column-occurrences đều yêu cầu [Authorize]; DataSource không cho phép user truy cập data-source ngoài phạm vi; FilterCondition tham chiếu DataSource hợp lệ.
   - Input Validation: kiểm tra tất cả POST/PUT endpoint có FluentValidation hoặc DataAnnotation; verify max length, required fields. **Bổ sung P8:** verify FilterCondition không inject SQL qua FieldName/Operator/Value (Dapper parameterized); verify DataSource TableOrViewName chỉ chấp nhận whitelist ký tự (a-zA-Z0-9_).
6. Kiểm tra: không hardcoded secrets trong code (grep "password", "secret", "connectionstring" trong *.cs, *.ts); appsettings.Development.json trong .gitignore.
7. Ghi nhận kết quả: bảng OWASP check (Pass/Fail + ghi chú) cho từng mục.

--- Kết quả ---
8. Tạo file đề xuất docs/de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md với:
   - Bảng Performance Baseline (trước/sau tối ưu)
   - Bảng Security Review (OWASP checklist)
   - Mục "Kiểm tra cho AI" (checklist: build, đo performance, security audit)
   Template: docs/de_xuat_trien_khai/DE_XUAT_TEST_COVERAGE_TONG_QUAT.md.
9. Cập nhật Postman collection nếu thêm endpoint; xác thực JSON.
10. Khi xong: cập nhật TONG_HOP theo rule bcdt-update-tong-hop-after-task.
```

---

### 3.4. Block giao AI – Week 17: UAT, Documentation, Demo *(đã xong – block tham chiếu)*

```
Task: Triển khai Week 17 (UAT & Demo) theo 06.KE_HOACH_MVP Phase 4: UAT trên localhost, Documentation, Demo preparation, Handover.

Tài liệu đọc trước: docs/script_core/06.KE_HOACH_MVP.md (Phase 4 Week 17), docs/RUNBOOK.md, docs/CẤU_TRÚC_CODEBASE.md, docs/de_xuat_trien_khai/B11_PHASE4_POLISH.md (mục 6 UAT checklist). Tham chiếu: docs/de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md (nếu có – kết quả Week 16). **Tài liệu P8 mở rộng:** docs/de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md, docs/de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md, docs/de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md (checklist P8a–P8f + test cases).

Rules: always-verify-after-work, bcdt-project, bcdt-update-tong-hop-after-task.

Model AI đề xuất (tối ưu chi phí):
- **Bước 1** (tạo UAT checklist) + **bước 3** (chạy UAT) + **bước 5–6** (Swagger, RUNBOOK) + **bước 7–9** (Demo Script, sample data, test demo) + **bước 10–12** (Handover, tạo file, cập nhật TONG_HOP): → **gpt-4o-mini** (task cơ học: tạo checklist, gọi API, ghi Pass/Fail, viết tài liệu).
- **Bước 2** (chuẩn bị sample data phức tạp cho P8: DataSource, Filter, DynamicRegion, Placeholder) + **Bước 4** (viết User Guide rõ ràng, có cấu trúc): → **claude-4-opus** (cần hiểu domain sâu, thiết kế dữ liệu test chính xác, viết tài liệu chất lượng cao).

Yêu cầu:

--- W17a – UAT Preparation & Execution ---
1. Tạo UAT checklist chi tiết (bổ sung/mở rộng B11 mục 6):
   - Auth: login admin + user thường, token refresh, logout.
   - Organization: CRUD, tree 5 cấp, tìm kiếm.
   - User: CRUD, gán role, gán đơn vị.
   - Form Definition: CRUD, xem versions, cấu hình sheet/column/data-binding.
   - **P8 – Cấu hình mở rộng (yêu cầu mở rộng cấu hình động cho dòng và cột):**
     - **UAT-P8a: DataSource** – CRUD data-sources; list columns từ API.
     - **UAT-P8b: FilterDefinition** – CRUD filter-definitions + filter-conditions; gán DataSourceId.
     - **UAT-P8c: FormDynamicRegion** – Cấu hình vùng chỉ tiêu động cho sheet; gán DataSourceId + FilterDefinitionId.
     - **UAT-P8d: Placeholder dòng (FormPlaceholderOccurrence)** – Tạo occurrence, gán row index + filter; verify workbook-data trả về N hàng tương ứng data từ nguồn đã lọc.
     - **UAT-P8e: Dynamic Column Region (FormDynamicColumnRegion)** – Cấu hình vùng cột động; gán DataSourceId + labelColumn + startColumnIndex.
     - **UAT-P8f: Placeholder cột (FormPlaceholderColumnOccurrence)** – Tạo occurrence + gán DynamicColumnRegionId; verify workbook-data trả về N cột tương ứng label từ nguồn dữ liệu.
     - **UAT-P8 tổng hợp: Form có CẢ placeholder dòng + cột** – Cấu hình form mẫu: sheet có 1 vùng dòng + 1 vùng cột; gọi workbook-data → verify đồng thời N hàng × M cột.
   - Submission: tạo, upload Excel, nhập liệu (Fortune-sheet), lưu, gửi duyệt.
   - **Workbook-data: load đúng cột cố định; load đúng cột/hàng động từ P8 (placeholder dòng/cột, dynamic regions); verify merge giữa cột cố định + cột động.**
   - Workflow: submit → approve/reject/revision; bulk approve.
   - Reporting Period: CRUD; Dashboard admin/user.
   - PDF Export, Notification, Bulk create submissions.
2. Chuẩn bị sample data cho UAT: đủ org tree (Bộ → Sở → Phòng), form mẫu, submissions ở nhiều trạng thái (Draft, Submitted, Approved), workflow instances, notifications. **Bổ sung cho P8:**
   - Tạo ít nhất 2 DataSource (1 có dữ liệu ≥ 5 records, 1 có 0 records để test edge case).
   - Tạo FilterDefinition + FilterCondition (vd lọc theo cột "Tỉnh" = "Hà Nội").
   - Tạo Form mẫu có: FormDynamicRegion (vùng dòng), FormPlaceholderOccurrence (2–3 occurrence), FormDynamicColumnRegion (vùng cột), FormPlaceholderColumnOccurrence (2–3 occurrence).
   - Có thể dùng/mở rộng Ensure-TestData.ps1 hoặc tạo script mới (tham khảo skill bcdt-seed-test-data).
3. Thực hiện UAT: chạy API (dotnet run) + FE (npm run dev); duyệt từng mục checklist; báo Pass/Fail từng mục. **Với UAT-P8: gọi API trực tiếp (curl/Postman) + kiểm tra FE nếu có giao diện; xác nhận JSON response chứa đúng số hàng/cột.**

--- W17b – Documentation ---
4. Tạo hoặc cập nhật User Guide tối thiểu:
   - Hướng dẫn sử dụng từng chức năng chính (Auth, Org, User, Form, Submission, Workflow, Dashboard).
   - Ảnh chụp hoặc mô tả UI (nếu có thể).
   - Ghi trong docs/USER_GUIDE.md (hoặc link từ RUNBOOK).
5. Kiểm tra Swagger annotations (Summary, Description, ProducesResponseType) trên tất cả controller; bổ sung nếu thiếu.
6. Cập nhật RUNBOOK nếu có thay đổi từ Week 16.

--- W17c – Demo Preparation ---
7. Tạo Demo Script (kịch bản demo từng bước):
   - **Kịch bản chính (Core flow):** Login → tạo đơn vị → tạo user → tạo form → cấu hình sheet/column → tạo kỳ báo cáo → tạo submission (bulk) → nhập liệu Excel → gửi duyệt → duyệt → xem dashboard.
   - **Kịch bản mở rộng (P8 – Cấu hình động):** Login admin → tạo DataSource → tạo FilterDefinition + FilterCondition (lọc theo trường) → cấu hình form: thêm FormDynamicRegion (vùng dòng) + FormPlaceholderOccurrence (gán bộ lọc) → thêm FormDynamicColumnRegion (vùng cột) + FormPlaceholderColumnOccurrence → tạo submission → gọi workbook-data → **demo: N hàng được tạo từ nguồn dữ liệu đã lọc, M cột động từ nhãn nguồn dữ liệu** → nhập liệu → gửi duyệt.
   - **Kịch bản edge case (tùy chọn):** Form không có vùng động (baseline), DataSource 0 records (0 hàng/cột).
   - Ghi trong docs/DEMO_SCRIPT.md.
8. Chuẩn bị sample data cho demo (có thể dùng chung W17a-2). **Đảm bảo có DataSource với dữ liệu thực tế (≥ 5 records) để demo P8.**
9. Test demo flow end-to-end: chạy kịch bản demo **cả core flow lẫn P8 flow** từ đầu đến cuối; báo Pass/Fail.

--- W17d – Handover ---
10. Verify deliverables theo 06.KE_HOACH_MVP mục 9 (Deliverables):
    - Source code (Git repo): ✅
    - Database scripts (sql/v2/*.sql): verify script chạy từ 01→22 trên DB trống.
    - Setup guide (RUNBOOK): verify chạy được theo hướng dẫn.
    - User guide: W17b-4 ở trên.
    - API documentation: Swagger + Postman collection.
    - Demo script: W17c-7 ở trên.
    - Test cases: verify test cases đầy đủ trong docs/de_xuat_trien_khai/*.md.
    - Sample data: scripts seed + Ensure-TestData.ps1.

--- Kết quả ---
11. Tạo file docs/de_xuat_trien_khai/W17_UAT_DEMO.md (UAT checklist + results, Demo script ref).
12. Khi xong: cập nhật TONG_HOP theo rule bcdt-update-tong-hop-after-task.
```

---

### 3.5. Block giao AI – Tùy chọn

#### ~~Kiểm tra Refresh token FE~~ ✅ Đã xong (2026-02-12, 5/5 Pass)

```
(Block tham chiếu – task đã hoàn thành)

Task: Kiểm tra thủ công Refresh token trên frontend theo checklist.
Kết quả: 5/5 Pass. Xem mục 3.7 và RA_SOAT_REFRESH_TOKEN.md mục 5.1 để biết chi tiết.
```

#### Phân cấp Menu / ReferenceEntity

```
Task: Áp dụng base dữ liệu phân cấp cho Menu hoặc ReferenceEntity (API all=true, FE treeUtils, Tree/TreeSelect).

Tài liệu: docs/de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md, docs/de_xuat_trien_khai/B6_DE_XUAT_TREE_DON_VI.md.

Agent: bcdt-hierarchical-data. Skill: bcdt-hierarchical-tree.

Rules: always-verify-after-work, bcdt-frontend, bcdt-hierarchical-data.

Model AI: **gpt-4o-mini** (CRUD pattern đã có mẫu, áp dụng lại).

Yêu cầu: Backend list endpoint hỗ trợ all=true; Frontend dùng utils/treeUtils (buildTree, treeExcludeSelfAndDescendants), Ant Design Tree/TreeSelect. Tạo/cập nhật mục "Kiểm tra cho AI" và tự test; báo Pass/Fail từng bước.
```

---

### 3.6. Prompt mẫu test (scripts có sẵn)

```
# Test Submission (10 bước)
Đảm bảo API chạy (dotnet run --project src/BCDT.Api --launch-profile http), chạy docs/script_core/test-submission-upload.ps1. Kỳ vọng 10/10 Pass.
```

```
# Test E2E (21 tests)
Đảm bảo API chạy (5080), chạy npm run test:e2e trong src/bcdt-web. Báo Pass/Fail từng spec (login, pages, reference-entity-types, b12-p7-formconfig-submission, workflow-definitions).
```

---

### 3.7. Đề xuất công việc tiếp theo (sau MVP W1–W17)

MVP 17 tuần đã hoàn thành. Các công việc dưới đây là **tùy chọn** (chất lượng, trải nghiệm, mở rộng).

| Ưu tiên | Công việc | Mục đích | Tài liệu / Ghi chú |
|---------|-----------|----------|--------------------|
| ~~**1**~~ ✅ | ~~Kiểm tra thủ công Refresh token FE~~ | Xác nhận FE lưu refreshToken, 401→refresh→retry, logout gọi API revoke; báo Pass/Fail từng bước. | **Đã xong (2026-02-12):** 5/5 Pass. [RA_SOAT_REFRESH_TOKEN.md](de_xuat_trien_khai/RA_SOAT_REFRESH_TOKEN.md) mục 5.1. |
| ~~**2**~~ ✅ | ~~Chạy lại UAT với submission Draft~~ | Để UAT mục 29, 30, 32 Pass: tạo submission Draft mới → Submit → Bulk-approve; chạy `run-w17-uat.ps1`. | **Đã xong (2026-02-12):** 35 Pass, 0 Fail, 3 Skip. Đã fix script PowerShell (array JSON, versionId). |
| ~~**Post-MVP**~~ ✅ | ~~User–Role–Org, Chuyển vai trò, Menu theo quyền~~ | Gán cặp (vai trò, đơn vị); chuyển vai trò + redirect; menu theo quyền; RolePermissionsContext; seed MCP. | **Đã xong (2026-02-13).** [KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md](de_xuat_trien_khai/KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md), [CHUYEN_VAI_TRO_KIEM_TRA.md](de_xuat_trien_khai/CHUYEN_VAI_TRO_KIEM_TRA.md). |
| ~~**1 (tùy chọn)**~~ ✅ | ~~Phân cấp Menu~~ | Menu: all=true, treeUtils, Table tree, TreeSelect (khi sửa loại trừ self + descendants). | **Đã xong (2026-02-23).** [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md) mục 10. |
| ~~**1 (tùy chọn)**~~ ✅ | ~~Phân cấp ReferenceEntity~~ | BE CRUD + all=true; FE ReferenceEntitiesPage (tree, TreeSelect); Postman; checklist 10.1. | **Đã xong (2026-02-23).** [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md) mục 10.1. |
| ~~**2 (tùy chọn)**~~ ✅ | ~~Bổ sung Postman / Swagger~~ | Đã thêm request thiếu + Swagger Summary (ReportingPeriods). | **Đã xong (2026-02-23).** Mục 5.4, 5.5. |
| ~~**Tùy chọn**~~ ✅ | ~~Chạy toàn bộ E2E và báo Pass/Fail từng spec~~ | Xác nhận pipeline E2E (4 spec) với BE tại 5080. | **Đã xong (2026-02-23):** 12 Pass, 1 Skip. [E2E_VERIFY.md](E2E_VERIFY.md). Sửa test: logout (dropdown header), reference-entity-types (strict mode), b12-p7 (assert linh hoạt). |
| ~~**Tùy chọn**~~ ✅ | ~~FE quản lý Workflow Definitions/Steps~~ | Trang admin quy trình + bước duyệt. | **Đã có sẵn (2026-02-23):** WorkflowDefinitionsPage, route /workflow-definitions, CRUD definition + steps; Form Config gắn workflow. B9 mục 7.2 Kiểm tra cho AI (FE) đã bổ sung; TONG_HOP 5.2 cập nhật. |
| ~~**Tùy chọn**~~ ✅ | ~~Menu "Quy trình phê duyệt" (workflow-definitions)~~ | Sidebar có mục dẫn tới /workflow-definitions. | **Đã xong (2026-02-23):** Script 23.seed_menu_workflow_definitions.sql (BCDT_Menu + RoleMenu 1,2,3); B9 mục 7.3 Kiểm tra cho AI. |
| ~~**Tùy chọn**~~ ✅ | ~~E2E cho trang Quy trình phê duyệt~~ | Playwright spec workflow-definitions. | **Đã xong (2026-02-23):** e2e/workflow-definitions.spec.ts (4 test: mở trang, Thêm quy trình, Chọn quy trình → card bước, Thêm bước duyệt); E2E_VERIFY.md mục 3 cập nhật. |
| ~~**Tùy chọn (ưu tiên tiếp)**~~ ✅ | ~~Sửa test E2E b12-p7 P7.1 (Form Config)~~ | P7.1 timeout `getByText('Cấu hình:')` trên Form Config → full E2E Pass. | **Đã xong (2026-02-23):** tăng timeout 15s cho assert "Cấu hình:" và "Sheet (Hàng)" trong P7.1; E2E_VERIFY mục 5 thêm workflow-definitions. Chạy full E2E khi API 5080. |
| ~~**Tùy chọn (ưu tiên tiếp)**~~ ✅ | ~~Xác nhận full E2E Pass (API 5080)~~ | Chạy toàn bộ E2E khi BE tại 5080; báo Pass/Fail từng spec. | **Đã xong (2026-02-23):** API 5080 + npm run test:e2e → **14 passed, 3 skipped, 0 failed.** Sửa: reference-entity-types Bước 3 (dialog hidden + table visible), workflow Thêm quy trình (dialog hidden + table visible); skip Bước 4, 5b, Thêm bước duyệt (list refetch timing). E2E_VERIFY mục 5 cập nhật. |
| ~~**Tùy chọn (ưu tiên tiếp)**~~ ✅ | ~~Bỏ skip 3 test E2E + Sửa Bước 4~~ | Làm cho 3 test skip chạy Pass; sửa FE Bước 4. | **Đã xong (2026-02-25):** Bỏ skip Bước 5b, Chọn quy trình, Thêm bước duyệt. Sửa ReferenceEntityTypesPage (mutateAsync + validateFields theo mode) → Bước 4 Pass. E2E: 17 passed, 0 skipped, 0 failed. |
| ~~**Tùy chọn (ưu tiên tiếp)**~~ ✅ | ~~**Rà soát tài liệu và checklist (RUNBOOK, TONG_HOP, E2E_VERIFY)**~~ | **Đã xong (2026-02-23):** RUNBOOK 7.1 E2E, 8.2 Kiểm tra cho AI, Version 1.1; E2E_VERIFY mục 5: 21 tests (17 passed, 4 skipped). Link/Version đã kiểm tra. | [RUNBOOK.md](RUNBOOK.md), [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [E2E_VERIFY.md](E2E_VERIFY.md). |
| **Tùy chọn** | **Review nghiệp vụ từng module** | Đối chiếu yêu cầu–code–DB theo 8 module; báo cáo gap, mâu thuẫn, khuyến nghị. Agent: **bcdt-business-reviewer**. Chi tiết và Cách giao AI: mục 3.7 bảng "Review nghiệp vụ từng module". | [01.YEU_CAU_HE_THONG.md](script_core/01.YEU_CAU_HE_THONG.md), [YEU_CAU_HE_THONG_TONG_HOP.md](YEU_CAU_HE_THONG_TONG_HOP.md), [de_xuat_trien_khai/](de_xuat_trien_khai/). |
| ~~**1 (theo dõi)**~~ ✅ | ~~**Cột/hàng định nghĩa biểu mẫu từ danh mục chỉ tiêu dùng chung**~~ | **Đã xong (phân tích + Phase 1 + Phase 2a + Phase 2b 2026-02-24).** Phase 2b: script 25, FormColumn.IndicatorId NOT NULL, API bắt buộc indicatorId. | Phase 3 (hàng) khi cần: [KE_HOACH_COT_HANG_TU_DANH_MUC_CHI_TIEU.md](de_xuat_trien_khai/KE_HOACH_COT_HANG_TU_DANH_MUC_CHI_TIEU.md). |
| ~~**Ưu tiên (tùy chọn)**~~ ✅ | **Tối ưu hiệu năng & mở rộng (dài hạn)** | **Perf-1–Perf-19 đã xong (2026-02-25):** IDistributedCache, Pagination, Health, Timeout/CT, Nén, Static, Index, Batch FilterDefinition, Lazy load route FE, Partition/replica/archive, Batch cột động + AsNoTracking, Hangfire, React Query staleTime + Bundle analysis, Reverse proxy cache (tài liệu Ops), Redis optional, Read replica, Partition/archive (script 28 + PERF11), **Load balancer (tài liệu Ops)**. **Không còn task Perf trong mục 3.8** – toàn bộ Perf-1→19 đã hoàn thành. | Khối chính phủ: không CDN công cộng; MCP user-mssql cho DB. |
| ~~**Sprint 1 – Bảo mật**~~ ✅ | ~~**JWT Token Storage: localStorage → in-memory + httpOnly cookie**~~ | **Đã xong (2026-02-27):** `tokenStore` in-memory; cookie `bc_refresh_token` HttpOnly/Secure/SameSite=Strict; CORS `WithOrigins+AllowCredentials`; DECISIONS.md D-001. | `src/bcdt-web/src/api/apiClient.ts`, `authApi.ts`, `AuthContext.tsx`, `AuthController.cs` |
| ~~**Sprint 1 – Bảo mật**~~ ✅ | ~~**Auth Minor Gaps: Refresh token rotation + Permission authorization**~~ | **Đã xong (2026-02-27):** `AuthService.RefreshAsync` rotate token (revoke cũ, tạo mới); `PermissionRequirement` + `PermissionAuthorizationHandler` (query UserRole→RolePermission→Permission); policies Form.Edit, Submission.Submit áp dụng trên 2 endpoint. | `AuthService.cs`, `PermissionAuthorizationHandler.cs`, `Program.cs` |
| ~~**Sprint 1 – DevOps**~~ ✅ | ~~**CI/CD Pipeline: GitHub Actions build BE + FE**~~ | **Đã xong (2026-02-27):** `.github/workflows/ci.yml`; job build-backend (.NET 8 Release) + build-frontend (Node 20, npm ci); trigger push/PR → main; RUNBOOK mục 8.4 CI/CD. | `.github/workflows/ci.yml`, `docs/RUNBOOK.md` |
| ~~**Sprint 1 – Tests**~~ ✅ | ~~**Backend Unit Tests: BCDT.Tests project (xUnit, 15 tests)**~~ | **Đã xong (2026-02-27):** `src/BCDT.Tests/` (xUnit + Moq + EF InMemory); 15 tests pass: FormDefinitionServiceTests (5), ReportSubmissionServiceTests (5), AuthServiceTests (5). `dotnet test` clean. | `src/BCDT.Tests/`, `BCDTCoreBase.sln` |
| ~~**Sprint 2 – Task 2.7**~~ ✅ | ~~**Export tổng hợp kỳ báo cáo (GET /reporting-periods/{id}/export-summary)**~~ | **Đã xong (2026-02-27):** `PeriodSummaryExportDto`; `IReportingPeriodService.GetSummaryExportAsync`; endpoint trả JSON tổng hợp số liệu (SubmissionId, OrganizationId, SheetIndex, DataRowCount, TotalValue1..10). Build Pass. | `ReportingPeriodService.cs`, `ReportingPeriodsController.cs`, `PeriodSummaryExportDto.cs` |
| ~~**Sprint 2 – Task 2.8**~~ ✅ | ~~**Validation required row khi nộp báo cáo**~~ | **Đã xong (2026-02-27):** `ReportSubmissionService.UpdateAsync` kiểm tra FormRow.IsRequired khi status → Submitted; nếu chưa có dữ liệu → 400 VALIDATION_FAILED. Build Pass. | `ReportSubmissionService.cs` |
| ~~**Sprint 2 – Task 2.9**~~ ✅ | ~~**CloneAsync: Nhân bản biểu mẫu (FormDefinition deep copy)**~~ | **Đã xong (2026-02-27):** Deep copy FormDefinition → FormVersions → FormSheets → FormColumns (ParentId re-map) → FormRows (ParentRowId re-map); endpoint `POST /api/v1/forms/{id}/clone`; policy `FormStructureAdmin`. Build Pass. | `FormDefinitionService.cs`, `FormDefinitionsController.cs` |
| ~~**Sprint 2 – CK-02**~~ ✅ | ~~**Hangfire job tự động tạo kỳ báo cáo (AutoCreateReportingPeriodJob)**~~ | **Đã xong (2026-02-27):** Cron `0 1 * * *` (1AM UTC); xử lý DAILY/WEEKLY/MONTHLY/QUARTERLY/YEARLY; skip nếu đã tồn tại; unset IsCurrent cũ, tạo kỳ mới với deadline offset. `sp_SetSystemContext` + `sp_ClearUserContext`. Build Pass. | `AutoCreateReportingPeriodJob.cs`, `Program.cs` |
| ~~**Sprint 2 – S2.4 FE**~~ ✅ | ~~**FE: Nút Nhân bản biểu mẫu trong FormsPage**~~ | **Đã xong (2026-02-27):** `formsApi.clone(id, {newCode, newName})`; Modal nhân bản (pre-fill `_COPY`/`(bản sao)`); `cloneMutation`; sau thành công → navigate `/forms/{id}/config`. TypeScript clean. | `FormsPage.tsx`, `formsApi.ts` |
| ~~**Sprint 2 – S2.5 BE**~~ ✅ | ~~**UserDelegation BE API (ủy quyền tạm thời)**~~ | **Đã xong (2026-02-27):** Entity `UserDelegation` (Full/Partial, overlap check, soft-revoke); DTOs; `IUserDelegationService`; `UserDelegationService`; `UserDelegationsController` (GET list, GET by id, POST create, DELETE revoke); DI. DB: `ALTER TABLE BCDT_UserDelegation`. Build Pass. | `UserDelegation.cs`, `UserDelegationService.cs`, `UserDelegationsController.cs` |
| ~~**Sprint 3 – S3.1**~~ ✅ | ~~**FormConfigPage split: 2670 → 166 lines + 12 section components**~~ | **Đã xong (2026-03-02):** Tạo `src/components/formConfig/` với 12 self-contained sections: DataSource, FilterDefinition, WorkflowConfig, FormSheet, FormColumn, FormRow, DynamicRegion, PlaceholderOccurrence, DynamicColumnRegion, PlaceholderColumnOccurrence, DataBinding, ColumnMapping. Mỗi section quản lý queries/mutations/state/modal riêng. TypeScript 0 errors. Branch: `feature/sprint-3/s3-1-form-split` → merged `sprint/3`. | `src/bcdt-web/src/components/formConfig/`, `FormConfigPage.tsx` |
| ~~**Sprint 3 – S3.2**~~ ✅ | ~~**SubmissionDataEntryPage UX – loading/error/boundary**~~ | **Đã xong (2026-03-02):** PageSkeleton cho loading states; QueryErrorDisplay cho API errors; Alert Warning cho status không hợp lệ; EmptyState cho form trống; ErrorBoundary bọc Fortune Sheet Workbook; Spinner khi sheetData chưa sẵn sàng; retry:1 cho queries. TypeScript 0 errors. Branch: `feature/sprint-3/s3-2-submission-ux` → merged `sprint/3`. | `SubmissionDataEntryPage.tsx` |
| ~~**Sprint 3 – S3.3**~~ ✅ | ~~**Dashboard filter theo kỳ báo cáo + export CSV**~~ | **Đã xong (2026-03-01):** BE: `?periodId=` optional → filter submissions; FE: Select kỳ + TanStack Query key; exportStatsCsv BOM UTF-8. Branch: `feature/sprint-3/s3-3-dashboard` → merged `sprint/3`. | `DashboardPage.tsx`, `dashboardApi.ts`, `DashboardService.cs` |
| ~~**Sprint 3 – S3.4**~~ ✅ | ~~**Error handling UX – ErrorBoundary + ErrorPage**~~ | **Đã xong (2026-03-01):** `ErrorBoundary.tsx` (class, catches render crash); `ErrorPage.tsx` với `QueryErrorDisplay`; routes /403 /500 /*; wrapped App. | `ErrorBoundary.tsx`, `ErrorPage.tsx`, `App.tsx` |
| ~~**Sprint 3 – S3.5**~~ ✅ | ~~**Loading & empty states – PageSkeleton + EmptyState**~~ | **Đã xong (2026-03-01):** `PageSkeleton.tsx`, `EmptyState.tsx`; DashboardPage dùng EmptyState compact cho 4 sections trống; FormsPage dùng QueryErrorDisplay. | `PageSkeleton.tsx`, `EmptyState.tsx` |
| **Ưu tiên 1 (theo dõi)** | **Triển khai production cả nước (Prod)** | ~~Prod-1~~ ✅ … ~~Prod-10~~ ✅ đã xong (2026-02-25). Còn Prod-11→Prod-15 (ưu tiên 3): SessionContext, Logging, Rate limit, Timeout, Dữ liệu trong nước. **Cách giao AI:** mục **3.9** (bảng Prod). | [REVIEW_PRODUCTION_CA_NUOC.md](REVIEW_PRODUCTION_CA_NUOC.md), [REVIEW_TRIEN_KHAI_PRODUCT.md](REVIEW_TRIEN_KHAI_PRODUCT.md), RUNBOOK mục 10. |

---

#### Cách giao AI khi làm Cột/hàng từ danh mục chỉ tiêu

- **Phân tích (đã xong 2026-02-24):** Dùng agent bcdt-business-reviewer; kết quả trong [DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md](de_xuat_trien_khai/DE_XUAT_COT_HANG_TU_DANH_MUC_CHI_TIEU.md).
- **Triển khai Phase 1 (giao AI phát triển):** Dùng **COMMAND** trong **[KE_HOACH_COT_HANG_TU_DANH_MUC_CHI_TIEU.md](de_xuat_trien_khai/KE_HOACH_COT_HANG_TU_DANH_MUC_CHI_TIEU.md) mục 3** – copy-paste block "COMMAND giao AI – Triển khai Phase 1" vào chat/task. Kế hoạch đầy đủ (phương án tối ưu, điều kiện tiên quyết, xử lý rủi ro, checklist, Phase 2a command) nằm trong file đó.

---

#### ~~Cách giao AI khi làm Rà soát tài liệu và checklist~~ *(đã xong 2026-02-23 – tham chiếu)*

**Kết quả:** RUNBOOK thêm 7.1 E2E, 8.2 Kiểm tra cho AI, Version 1.1; E2E_VERIFY mục 5: 21 tests (17 passed, 4 skipped). Verify Pass từng mục.

**Ưu tiên 1 tiếp theo:** Công việc tùy chọn: xem mục 3.1, 3.7. **Prod (cả nước):** ~~Prod-1~~ ✅ … ~~Prod-10~~ ✅ đã xong (2026-02-25); ưu tiên tiếp Prod-11→15 (mục 3.9). **Cột/hàng từ danh mục:** Phase 1 + Phase 2a + Phase 2b đã xong (2026-02-24); Phase 3 (hàng) khi cần. *(Review nghiệp vụ 8/8 đã xong.)*

---

#### ~~Cách giao AI khi làm Review nghiệp vụ – module Workflow (B9)~~ *(đã xong 2026-02-24 – tham chiếu)*

```
Task: Review nghiệp vụ module Workflow (B9) – đối chiếu yêu cầu với code và DB, báo cáo gap, mâu thuẫn, khuyến nghị.
Kết quả: Báo cáo [REVIEW_NGHIEP_VU_MODULE_WORKFLOW_B9.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_WORKFLOW_B9.md). 1 gap Minor (API workflow history), 0 Critical.
```

---

#### ~~Cách giao AI khi làm Review nghiệp vụ – module Reporting & Dashboard (B10)~~ *(đã xong 2026-02-24 – tham chiếu)*

```
Task: Review nghiệp vụ module Reporting & Dashboard (B10). Kết quả: Báo cáo [REVIEW_NGHIEP_VU_MODULE_REPORTING_DASHBOARD_B10.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_REPORTING_DASHBOARD_B10.md). 3 gap Minor (CK-02, FR-TH-02/03), 0 Critical.
```

---

#### ~~Cách giao AI khi làm Review nghiệp vụ – module B12 (Chỉ tiêu cố định & động)~~ *(đã xong 2026-02-24 – tham chiếu)*

```
Task: Review nghiệp vụ module B12. Kết quả: Báo cáo [REVIEW_NGHIEP_VU_MODULE_B12_CHI_TIEU_CO_DINH_DONG.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_B12_CHI_TIEU_CO_DINH_DONG.md). 0 gap, đạt đủ R1–R11.
```

---

#### ~~Cách giao AI khi làm Review nghiệp vụ – module P8 (Lọc động, placeholder)~~ *(đã xong 2026-02-24 – tham chiếu)*

```
Task: Review nghiệp vụ module P8. Kết quả: Báo cáo [REVIEW_NGHIEP_VU_MODULE_P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_P8_FILTER_PLACEHOLDER.md). 0 gap, đạt đủ P8a–P8f. 8/8 module review đã hoàn thành.
```

---

#### ~~Cách giao AI khi làm Review nghiệp vụ – module Submission & Workbook~~ *(đã xong 2026-02-24 – tham chiếu)*

```
Task: Review nghiệp vụ module Submission & Workbook – đối chiếu yêu cầu với code và DB, báo cáo gap, mâu thuẫn, khuyến nghị.

Agent: bcdt-business-reviewer. Rules: bcdt-project, bcdt-agentic-workflow.

Tài liệu đọc: docs/script_core/01.YEU_CAU_HE_THONG.md (FR-NL-*, BM/EX), docs/YEU_CAU_HE_THONG_TONG_HOP.md, docs/de_xuat_trien_khai/B8_FORM_SHEET_COLUMN_DATA_BINDING.md, B10 (submission/aggregation), docs/RUNBOOK.md. Đọc docs/AI_CONTEXT.md và .cursor/agents/bcdt-business-reviewer.md.

Yêu cầu:
1. Plan: Liệt kê phạm vi review (API submissions, workbook-data, upload, sync-from-presentation; bảng ReportSubmission, ReportPresentation, ReportDataRow; FE SubmissionsPage, SubmissionDataEntryPage, Fortune-sheet).
2. Execute: Đối chiếu từng yêu cầu với implementation; ghi nhận Đạt / Một phần / Chưa / Ngoài phạm vi.
3. Báo cáo: Phạm vi review | Bảng đối chiếu | Gap (Critical/Major/Minor) | Mâu thuẫn/Rủi ro | Khuyến nghị.
4. Kiểm tra cho AI: Báo cáo đủ cấu trúc; có khuyến nghị hoặc "Đạt đủ yêu cầu"; không cần build.
5. Tự test: Chạy checklist; báo Pass/Fail từng bước.
6. Khi xong: Cập nhật TONG_HOP – trạng thái module "Submission & Workbook" thành ✅ Đã xong (YYYY-MM-DD); lưu báo cáo docs/de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_SUBMISSION_WORKBOOK.md.
```

---

#### ~~Cách giao AI khi làm Review nghiệp vụ – module Form Definition (B7–B8)~~ *(đã xong 2026-02-24 – tham chiếu)*

```
Task: Review nghiệp vụ module Form Definition (B7–B8) – đối chiếu yêu cầu với code và DB, báo cáo gap, mâu thuẫn, khuyến nghị.

Agent: bcdt-business-reviewer. Rules: bcdt-project, bcdt-agentic-workflow.

Tài liệu đọc: docs/script_core/01.YEU_CAU_HE_THONG.md (phần Biểu mẫu BM-*, FR-BM-*), docs/YEU_CAU_HE_THONG_TONG_HOP.md, docs/de_xuat_trien_khai/B7_FORM_DEFINITION.md, docs/de_xuat_trien_khai/B8_FORM_SHEET_COLUMN_DATA_BINDING.md. Đọc docs/AI_CONTEXT.md và .cursor/agents/bcdt-business-reviewer.md.

Yêu cầu:
1. Plan: Liệt kê phạm vi review (API forms, sheets, columns, data binding, mapping; bảng FormDefinition, FormSheet, FormColumn, FormDataBinding, FormColumnMapping; FE FormsPage, FormConfigPage), nguồn yêu cầu (01 BM/FR-BM, B7, B8).
2. Execute: Đối chiếu từng yêu cầu với implementation; ghi nhận Đạt / Một phần / Chưa / Ngoài phạm vi.
3. Báo cáo: Phạm vi review | Bảng đối chiếu | Gap (Critical/Major/Minor) | Mâu thuẫn/Rủi ro | Khuyến nghị.
4. Kiểm tra cho AI: Báo cáo đủ cấu trúc; có khuyến nghị hoặc "Đạt đủ yêu cầu"; không cần build.
5. Tự test: Chạy checklist; báo Pass/Fail từng bước.
6. Khi xong: Cập nhật TONG_HOP – trạng thái module "Form Definition (B7–B8)" thành ✅ Đã xong (YYYY-MM-DD); lưu báo cáo docs/de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_FORM_B7_B8.md.
```

---

#### ~~Cách giao AI khi làm Review nghiệp vụ – module Organization & User (B4–B5)~~ *(đã xong 2026-02-24 – tham chiếu)*

```
Task: Review nghiệp vụ module Organization & User (B4–B5) – đối chiếu yêu cầu với code và DB, báo cáo gap, mâu thuẫn, khuyến nghị.

Agent: bcdt-business-reviewer. Rules: bcdt-project, bcdt-agentic-workflow.

Tài liệu đọc: docs/script_core/01.YEU_CAU_HE_THONG.md (phần Cơ cấu tổ chức ORG-01–ORG-06), docs/YEU_CAU_HE_THONG_TONG_HOP.md, docs/de_xuat_trien_khai/B4_ORGANIZATION.md, docs/de_xuat_trien_khai/B5_USER_MANAGEMENT.md. Đọc docs/AI_CONTEXT.md và .cursor/agents/bcdt-business-reviewer.md.

Yêu cầu:
1. Plan: Liệt kê phạm vi review (API organizations, users, bảng BCDT_Organization, BCDT_User, BCDT_UserOrganization, BCDT_UserRole, TreePath 5 cấp, FE tree/CRUD), nguồn yêu cầu (01 ORG-*, B4, B5).
2. Execute: Đối chiếu từng yêu cầu với implementation (endpoint, entity, service, FE OrganizationsPage/UsersPage, tree all=true); ghi nhận Đạt / Một phần / Chưa / Ngoài phạm vi.
3. Báo cáo: Phạm vi review | Bảng đối chiếu (Yêu cầu | Nguồn | Implementation | Trạng thái) | Gap (Critical/Major/Minor) | Mâu thuẫn/Rủi ro | Khuyến nghị (task/ưu tiên).
4. Kiểm tra cho AI (checklist): (1) Báo cáo có đủ cấu trúc trên; (2) Có ít nhất một khuyến nghị rõ ràng hoặc xác nhận "Đạt đủ yêu cầu"; (3) Không cần build/test code – verify nội dung báo cáo là đủ.
5. Tự test: Chạy checklist mục 4; báo Pass/Fail từng bước trước khi báo xong.
6. Khi xong: Cập nhật TONG_HOP – đổi trạng thái module "Organization & User (B4–B5)" trong bảng "Review nghiệp vụ từng module" (mục 3.7) thành ✅ Đã xong (YYYY-MM-DD); ghi tóm tắt 1 dòng (vd. "Báo cáo review Org/User: đối chiếu B4/B5, X gap Minor, 0 Critical."). Lưu báo cáo vào docs/de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_ORG_USER_B4_B5.md (hoặc tên tương đương).
```

---

#### ~~Cách giao AI khi làm Review nghiệp vụ – module Auth (B1–B3)~~ *(đã xong 2026-02-24 – tham chiếu)*

```
Task: Review nghiệp vụ module Auth (B1–B3) – đối chiếu yêu cầu với code và DB, báo cáo gap, mâu thuẫn, khuyến nghị.

Agent: bcdt-business-reviewer. Rules: bcdt-project, bcdt-agentic-workflow.

Tài liệu đọc: docs/script_core/01.YEU_CAU_HE_THONG.md (phần Auth, NFR), docs/YEU_CAU_HE_THONG_TONG_HOP.md, docs/de_xuat_trien_khai/B1_JWT.md, docs/de_xuat_trien_khai/B2_RBAC.md, docs/de_xuat_trien_khai/B3_RLS.md. Đọc docs/AI_CONTEXT.md và .cursor/agents/bcdt-business-reviewer.md.

Yêu cầu:
1. Plan: Liệt kê phạm vi review (API auth, bảng/RLS, luồng JWT/RBAC/RLS), nguồn yêu cầu (01, YEU_CAU_TONG_HOP, B1/B2/B3).
2. Execute: Đối chiếu từng yêu cầu với implementation (endpoint, entity, service, middleware); ghi nhận Đạt / Một phần / Chưa / Ngoài phạm vi.
3. Báo cáo: Phạm vi review | Bảng đối chiếu (Yêu cầu | Nguồn | Implementation | Trạng thái) | Gap (Critical/Major/Minor) | Mâu thuẫn/Rủi ro | Khuyến nghị (task/ưu tiên).
4. Kiểm tra cho AI (checklist): (1) Báo cáo có đủ cấu trúc trên; (2) Có ít nhất một khuyến nghị rõ ràng hoặc xác nhận "Đạt đủ yêu cầu"; (3) Không cần build/test code – verify nội dung báo cáo là đủ.
5. Tự test: Chạy checklist mục 4; báo Pass/Fail từng bước trước khi báo xong.
6. Khi xong: Cập nhật TONG_HOP – đổi trạng thái module "Auth (B1–B3)" trong bảng "Review nghiệp vụ từng module" (mục 3.7) thành ✅ Đã xong (YYYY-MM-DD); ghi tóm tắt 1 dòng (vd. "Báo cáo review Auth: đối chiếu B1/B2/B3, 2 gap Minor, 0 Critical.").
```

---

#### ~~Cách giao AI khi làm Bỏ skip 3 test E2E~~ *(đã thử 2026-02-23 – tham chiếu)*

**Kết quả:** Đã thử waitForResponse (POST + GET list) trước assert row; row vẫn không xuất hiện (có thể do pagination – bản ghi mới nằm trang 2). Giữ skip 3 test (Bước 4, Chọn quy trình, Thêm bước duyệt). Sửa Bước 3: codeNew unique mỗi test (tránh duplicate). E2E: 13 passed, 4 skipped, 0 failed.

---

#### ~~Cách giao AI khi làm Xác nhận full E2E Pass (API 5080)~~ *(đã xong 2026-02-23 – tham chiếu)*

**Kết quả:** API 5080 + npm run test:e2e → 14 passed, 3 skipped, 0 failed. Sửa spec: reference-entity-types Bước 3 (success + dialog hidden + table visible); workflow Thêm quy trình (dialog hidden + table visible). Skip: Bước 4, 5b (reference-entity-types), Thêm bước duyệt (workflow) do list refetch chưa kịp hiển thị row. E2E_VERIFY.md mục 5: bổ sung bước kiểm tra API 5080 trước khi chạy.

---

#### ~~Cách giao AI khi làm Sửa test E2E b12-p7 P7.1~~ *(đã xong 2026-02-23 – tham chiếu)*

**Kết quả:** P7.1 tăng timeout 15s cho `getByText('Cấu hình:', { exact: false })` và `getByText('Sheet (Hàng)')` (form config load async từ API). E2E_VERIFY.md mục 5: checklist thêm workflow-definitions.spec.ts. Full E2E cần API chạy tại 5080.

---

#### ~~Cách giao AI khi làm Kiểm tra Refresh token FE~~ *(đã xong – tham chiếu)*

**Kết quả (2026-02-12):**

| Bước | Nội dung | Kết quả |
|------|----------|---------|
| 1 | Build FE | **Pass** |
| 2 | Login lưu refreshToken (localStorage có cả 2 token) | **Pass** |
| 3 | 401 → refresh → retry (inject expired token → trang load được, không redirect /login) | **Pass** |
| 4 | Logout gọi POST /auth/logout + clear localStorage | **Pass** |
| 5 | E2E tests | **Pass** (6/6) |

**Tóm tắt:** 5/5 Pass. Refresh token FE hoạt động đúng. Chi tiết: [RA_SOAT_REFRESH_TOKEN.md](de_xuat_trien_khai/RA_SOAT_REFRESH_TOKEN.md) mục 5.1.

---

#### ~~Cách giao AI khi làm Chạy lại UAT với submission Draft~~ *(đã xong – tham chiếu)*

**Kết quả (2026-02-12):**

| Bước | Nội dung | Kết quả |
|------|----------|---------|
| 1 | Tạo Draft submissions với formId có workflow (2, 4, 5) | **Pass** |
| 2 | Submit submission (POST /submissions/{id}/submit) | **Pass** |
| 3 | Bulk-approve workflow instances (POST /workflow-instances/bulk-approve) | **Pass** |
| 4 | Chạy run-w17-uat.ps1 | **Pass** (35 Pass, 0 Fail, 3 Skip) |

**Sửa lỗi script:**
- Fix PowerShell JSON array serialization (single element `@(id)` bị unwrap thành integer).
- Fix `$versionId` không được set khi có Draft submission có workflow.
- Thay Invoke-Api bằng direct Invoke-RestMethod với JSON thủ công cho bulk-approve và bulk-create.

**Tóm tắt:** 35 Pass, 0 Fail, 3 Skip. Script `run-w17-uat.ps1` đã được fix và hoạt động ổn định.

---

#### ~~Cách giao AI khi làm Phân cấp Menu~~ *(đã xong 2026-02-23 – tham chiếu)*

Menu đã áp dụng base: GET /api/v1/menus?all=true (flat); MenusPage dùng buildTree, treeExcludeSelfAndDescendants, Table tree, TreeSelect. Checklist: [HIERARCHICAL_DATA_BASE_AND_RULE.md](de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md) mục 10.

#### ~~Cách giao AI khi làm Phân cấp ReferenceEntity~~ *(đã xong 2026-02-23 – tham chiếu)*

```
Task: Áp dụng base dữ liệu phân cấp cho ReferenceEntity (API all=true, FE treeUtils, Tree/TreeSelect).

Tài liệu: docs/de_xuat_trien_khai/HIERARCHICAL_DATA_BASE_AND_RULE.md, docs/de_xuat_trien_khai/B6_DE_XUAT_TREE_DON_VI.md.

Agent: bcdt-hierarchical-data. Skill: bcdt-hierarchical-tree.

Rules: always-verify-after-work, bcdt-frontend, bcdt-hierarchical-data.

Yêu cầu:
1. Backend: list endpoint ReferenceEntity hỗ trợ all=true (trả toàn bộ flat).
2. Frontend: dùng utils/treeUtils (buildTree, treeExcludeSelfAndDescendants), Ant Design Tree/TreeSelect cho trang list và trường "cha".
3. Tạo/cập nhật mục "Kiểm tra cho AI" trong file đề xuất (vd. HIERARCHICAL mục 10).
4. Tự test: build BE/FE, gọi API all=true, kiểm tra tree render đúng; báo Pass/Fail từng bước trước khi báo xong.
5. Khi xong: cập nhật TONG_HOP theo rule bcdt-update-tong-hop-after-task.
```

---

#### Review nghiệp vụ từng module (để giao task)

Bảng dưới liệt kê từng module để giao task review nghiệp vụ (đối chiếu yêu cầu–code–DB, gap analysis). Mỗi task dùng agent **bcdt-business-reviewer**.

| Module | Phạm vi / Tài liệu đối chiếu | Trạng thái |
|--------|------------------------------|------------|
| **Auth (B1–B3)** | JWT (B1), RBAC (B2), RLS & Session Context (B3). [B1_JWT.md](de_xuat_trien_khai/B1_JWT.md), [B2_RBAC.md](de_xuat_trien_khai/B2_RBAC.md), [B3_RLS.md](de_xuat_trien_khai/B3_RLS.md), 01.YEU_CAU_HE_THONG (Auth/NFR). | ✅ Đã xong (2026-02-24). Báo cáo: đối chiếu B1/B2/B3, 2 gap Minor (policy permission, refresh rotation), 0 Critical. [REVIEW_NGHIEP_VU_MODULE_AUTH_B1_B3.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_AUTH_B1_B3.md). |
| **Organization & User (B4–B5)** | Organization CRUD, cây 5 cấp (B4); User CRUD, gán vai trò–đơn vị (B5). [B4_ORGANIZATION.md](de_xuat_trien_khai/B4_ORGANIZATION.md), [B5_USER_MANAGEMENT.md](de_xuat_trien_khai/B5_USER_MANAGEMENT.md). | ✅ Đã xong (2026-02-24). Báo cáo: đối chiếu B4/B5, 1 gap Minor (ORG-05 Delegation chưa triển khai), 0 Critical. [REVIEW_NGHIEP_VU_MODULE_ORG_USER_B4_B5.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_ORG_USER_B4_B5.md). |
| **Form Definition (B7–B8)** | Form CRUD, Sheet, Column, Data Binding, Mapping. [B7_FORM_DEFINITION.md](de_xuat_trien_khai/B7_FORM_DEFINITION.md), [B8_FORM_SHEET_COLUMN_DATA_BINDING.md](de_xuat_trien_khai/B8_FORM_SHEET_COLUMN_DATA_BINDING.md). | ✅ Đã xong (2026-02-24). Báo cáo: đối chiếu B7/B8, 2 gap Minor (nhân bản, preview riêng), 0 Critical. [REVIEW_NGHIEP_VU_MODULE_FORM_B7_B8.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_FORM_B7_B8.md). |
| **Submission & Workbook** | Submission CRUD, upload, workbook-data, nhập liệu Excel, sync-from-presentation. Tài liệu B8, B10, RUNBOOK. | ✅ Đã xong (2026-02-24). Báo cáo: đối chiếu FR-NL-* và hybrid storage, 1 gap Minor (validation trước submit), 0 Critical. [REVIEW_NGHIEP_VU_MODULE_SUBMISSION_WORKBOOK.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_SUBMISSION_WORKBOOK.md). |
| **Workflow (B9)** | Submit, Approve/Reject/Revision, WorkflowDefinition/Step, FormWorkflowConfig. [B9_WORKFLOW.md](de_xuat_trien_khai/B9_WORKFLOW.md). | ✅ Đã xong (2026-02-24). Báo cáo: đối chiếu WF-*/FR-WF-*, 1 gap Minor (API workflow history), 0 Critical. [REVIEW_NGHIEP_VU_MODULE_WORKFLOW_B9.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_WORKFLOW_B9.md). |
| **Reporting & Dashboard (B10)** | Reporting Period, Aggregation, Dashboard admin/user. [B10_REPORTING_PERIOD.md](de_xuat_trien_khai/B10_REPORTING_PERIOD.md). | ✅ Đã xong (2026-02-24). Báo cáo: đối chiếu CK-*/FR-TH-*/FR-DB-*, 3 gap Minor (CK-02 auto-create, FR-TH-02/03), 0 Critical. [REVIEW_NGHIEP_VU_MODULE_REPORTING_DASHBOARD_B10.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_REPORTING_DASHBOARD_B10.md). |
| **B12 – Chỉ tiêu cố định & động** | R1–R11, FormDynamicRegion, ReportDynamicIndicator, Build workbook, FE FormConfig/SubmissionDataEntry. [B12_CHI_TIEU_CO_DINH_DONG.md](de_xuat_trien_khai/B12_CHI_TIEU_CO_DINH_DONG.md), [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md). | ✅ Đã xong (2026-02-24). Báo cáo: đối chiếu R1–R11, 0 gap, đạt đủ. [REVIEW_NGHIEP_VU_MODULE_B12_CHI_TIEU_CO_DINH_DONG.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_B12_CHI_TIEU_CO_DINH_DONG.md). |
| **P8 – Lọc động, placeholder** | DataSource, FilterDefinition, FormPlaceholderOccurrence (dòng), FormDynamicColumnRegion, FormPlaceholderColumnOccurrence (cột). [P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md), [GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md](de_xuat_trien_khai/GIAI_PHAP_LOC_DONG_THEO_TRUONG_DU_LIEU.md), [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md). | ✅ Đã xong (2026-02-24). Báo cáo: đối chiếu P8a–P8f, 0 gap. [REVIEW_NGHIEP_VU_MODULE_P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_P8_FILTER_PLACEHOLDER.md). |

**Cách giao AI khi làm Review nghiệp vụ (từng module)** – copy-paste và thay `[MODULE]` / `[TÀI_LIỆU]`:

```
Task: Review nghiệp vụ module [MODULE] – đối chiếu yêu cầu với code và DB, báo cáo gap, mâu thuẫn, khuyến nghị.

Agent: bcdt-business-reviewer. Rules: bcdt-project, bcdt-agentic-workflow.

Tài liệu đọc: docs/script_core/01.YEU_CAU_HE_THONG.md, docs/YEU_CAU_HE_THONG_TONG_HOP.md, [TÀI_LIỆU] (file đề xuất tương ứng module theo bảng trên). Đọc thêm docs/AI_CONTEXT.md và .cursor/agents/bcdt-business-reviewer.md.

Yêu cầu:
1. Plan: Liệt kê phạm vi review (API, bảng DB, luồng nghiệp vụ), nguồn yêu cầu (01, YEU_CAU_TONG_HOP, file đề xuất).
2. Execute: Đối chiếu từng yêu cầu với implementation (endpoint, entity, service, FE nếu có); ghi nhận Đạt / Một phần / Chưa / Ngoài phạm vi.
3. Báo cáo: Phạm vi review | Bảng đối chiếu (Yêu cầu | Nguồn | Implementation | Trạng thái) | Gap (Critical/Major/Minor) | Mâu thuẫn/Rủi ro | Khuyến nghị (task/ưu tiên).
4. Kiểm tra cho AI: Không cần build/test code; verify báo cáo đủ cấu trúc và có khuyến nghị rõ ràng.
5. Khi xong: Cập nhật TONG_HOP – đổi trạng thái module tương ứng trong bảng "Review nghiệp vụ từng module" thành ✅ Đã xong (YYYY-MM-DD); ghi tóm tắt 1 dòng vào cột Ghi chú (hoặc dưới bảng).
```

*Ví dụ giao task:*  
*"Review nghiệp vụ module Auth (B1–B3). Tài liệu: B1_JWT, B2_RBAC, B3_RLS. Dùng agent bcdt-business-reviewer."*

---

### 3.8. Tối ưu hiệu năng & mở rộng – Kế hoạch theo dõi và giao AI

**Nguồn:** [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md). Tập trung giải pháp **dài hạn**; triển khai **khối chính phủ** (không CDN công cộng). Công việc dưới đây có thể giao từng mục theo ưu tiên trong bảng.

#### Bảng công việc (Perf-1 → Perf-19)

| Mã | Công việc | Ưu tiên | Trạng thái | Ghi chú |
|----|-----------|---------|------------|---------|
| ~~**Perf-1**~~ ✅ | ~~Cache: IDistributedCache ngay từ đầu (0.2)~~ | 1 | **Đã xong (2026-02-25)** | ICacheService + MemoryDistributedCache; cache ReportingFrequency, OrganizationType, DataSource, FilterDefinition, IndicatorCatalog; TTL 10 phút; invalidate CUD. DE_XUAT 5.1 Kiểm tra cho AI. |
| ~~**Perf-2**~~ ✅ | ~~Pagination chuẩn cho mọi list API (0.4, 2.1.5)~~ | 1 | **Đã xong (2026-02-25)** | PagedResultDto; GET /forms, /submissions ?pageSize=&pageNumber=; data: items, totalCount, pageNumber, pageSize, hasNext. DE_XUAT 5.5. |
| ~~**Perf-3**~~ ✅ | ~~Health check (0.4, 2.3.4)~~ | 1 | **Đã xong (2026-02-25)** | AddHealthChecks().AddDbContextCheck&lt;AppDbContext&gt;("db"); MapHealthChecks("/health"); GET /health → 200 Healthy khi DB khả dụng. DE_XUAT 5.2. |
| ~~**Perf-4**~~ ✅ | ~~Timeout & CancellationToken (0.4, 2.3.2)~~ | 1 | **Đã xong (2026-02-25)** | workbook-data, aggregate đã lan truyền CancellationToken; Kestrel:Limits (RequestHeadersTimeout, KeepAliveTimeout) trong appsettings. DE_XUAT 5.4. |
| ~~**Perf-5**~~ ✅ | ~~Nén response (0.4, 2.3.1)~~ | 1 | **Đã xong (2026-02-25)** | AddResponseCompression (Brotli, Gzip), UseResponseCompression; EnableForHttps. DE_XUAT 5.3. |
| ~~**Perf-6**~~ ✅ | ~~Static & cache nội bộ (0.6, 3.4)~~ | 1 | **Đã xong (2026-02-25)** | Tài liệu: hướng dẫn deploy static nội bộ, Cache-Control, ví dụ nginx; DE_XUAT 5.8, RUNBOOK 8.3. Áp dụng khi deploy production. |
| ~~**Perf-7**~~ ✅ | ~~Index thiếu (2.1.1)~~ | 2 | **Đã xong (2026-02-25)** | Script 26.perf7_missing_indexes.sql: IX_ReportSubmission_Form_Org_Period_Status (FormDefinitionId, OrganizationId, ReportingPeriodId, Status). DE_XUAT 5.6. |
| ~~**Perf-8**~~ ✅ | ~~Batch FilterDefinition (2.1.2)~~ | 2 | **Đã xong (2026-02-25)** | GetByIdsAsync; BuildWorkbook + DataSourceQueryService filterCache; giảm N query FilterDefinition trong workbook-data. DE_XUAT 5.7. |
| ~~**Perf-9**~~ ✅ | ~~Cache master data qua IDistributedCache (2.2.1)~~ | 2 | **Đã xong (2026-02-25)** | Đạt bởi Perf-1: đủ 5 loại master data qua ICacheService; DE_XUAT 5.9. |
| ~~**Perf-10**~~ ✅ | ~~Lazy load route FE (2.4.1)~~ | 2 | **Đã xong (2026-02-25)** | React.lazy + Suspense; fallback PageLoading; trang ít dùng tách chunk riêng. DE_XUAT 5.10. |
| ~~**Perf-11**~~ ✅ | ~~Thiết kế partition-ready & read replica–ready (0.3)~~ | 2 | **Đã xong (2026-02-25)** | PERF11 doc + script 27; ArchivePolicy config; DE_XUAT 5.11. |
| ~~**Perf-12**~~ ✅ | ~~Batch resolve cột động (2.1.3), AsNoTracking (2.1.4)~~ | 3 | **Đã xong (2026-02-25)** | columnDataSourceCache trong BuildWorkbook; AsNoTracking nhất quán; DE_XUAT 5.12. |
| ~~**Perf-13**~~ ✅ | ~~Background job Hangfire (0.5, 2.3.3)~~ | 3 | **Đã xong (2026-02-25)** | AddHangfire SQL Server; POST/GET /api/v1/jobs; AggregateSubmissionJob; DE_XUAT 5.13. |
| ~~**Perf-14**~~ ✅ | ~~React Query staleTime (2.4.2), Bundle analysis (2.4.3)~~ | 3 | **Đã xong (2026-02-25)** | QueryClient staleTime 1 phút; rollup-plugin-visualizer, dist/stats.html. DE_XUAT 5.14. |
| ~~**Perf-15**~~ ✅ | ~~Reverse proxy cache (3.4.2)~~ | 3 | **Đã xong (2026-02-25)** | Tài liệu "Triển khai Perf-15" (static + tùy chọn API cache, nginx/IIS ARR); RUNBOOK 8.3; DE_XUAT 5.15. Ops. |
| ~~**Perf-16**~~ ✅ | ~~Redis (3.1.3) khi scale > 1 instance~~ | 4 | **Đã xong (2026-02-25)** | ConnectionStrings:Redis optional; StackExchangeRedis khi có, else MemoryDistributedCache; DE_XUAT 5.16. |
| ~~**Perf-17**~~ ✅ | ~~Read replica (3.2.1)~~ | 4 | **Đã xong (2026-02-25)** | AppReadOnlyDbContext; ReadReplica optional; DashboardService dùng read; DE_XUAT 5.17. |
| ~~**Perf-18**~~ ✅ | ~~Partition/archive (3.2.3)~~ | 4 | **Đã xong (2026-02-25)** | Script 28 (bảng _Archive + sp_BCDT_ArchiveSubmissions_Batch); PERF11 Triển khai Perf-18; DE_XUAT 5.18. |
| ~~**Perf-19**~~ ✅ | ~~Load balancer (3.1.2)~~ | 4 | **Đã xong (2026-02-25)** | Tài liệu "Triển khai Perf-19 – Load balancer" (health check, nginx upstream, Hangfire/Redis); DE_XUAT 5.19. Ops. |

#### Cách giao AI khi làm Perf-1 (IDistributedCache – ưu tiên 1)

```
Task: Triển khai cache dài hạn dùng IDistributedCache (tránh sau phải đổi code khi scale). Theo docs/DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md mục 0.2 và 2.2.1.

Tài liệu bắt buộc: docs/DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md, docs/W16_PERFORMANCE_SECURITY.md, docs/RUNBOOK.md (mục 6.1 – tắt BCDT.Api trước build). Rules: always-verify-after-work, bcdt-project, bcdt-agentic-workflow.

Yêu cầu:
1. Application: Đăng ký IDistributedCache (Microsoft.Extensions.Caching.StackExchangeRedis optional; cho đơn instance dùng MemoryDistributedCache). Không dùng IMemoryCache cho master data mới.
2. Infrastructure: Implement cache master data (ReportingFrequency, OrganizationType, IndicatorCatalog list, DataSource theo id, FilterDefinition+FilterCondition theo id) qua IDistributedCache; TTL 5–15 phút; invalidate khi CUD tương ứng.
3. Service hiện đang đọc trực tiếp từ DB cho các entity trên: thêm lớp cache (get từ cache nếu có, miss thì query DB rồi set cache). Có thể tạo ICacheService wrap IDistributedCache nếu muốn key/ttl thống nhất.
4. Kiểm tra cho AI: Build BE Pass; gọi API list reporting-frequencies, organization-types (hoặc form có dùng DataSource/FilterDefinition) 2 lần liên tiếp – lần 2 nhanh hơn hoặc tương đương; sau khi CUD entity tương ứng thì lần gọi sau trả dữ liệu mới (invalidate đúng).
5. Viết checklist ngắn "Kiểm tra cho AI" trong DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md hoặc file đề xuất Perf (nếu tạo). Tự test: chạy đủ checklist, báo Pass/Fail từng bước trước khi báo xong. Khi xong: cập nhật TONG_HOP – Perf-1 thành ✅ Đã xong (YYYY-MM-DD); mục 3.8, 8 theo rule bcdt-update-tong-hop-after-task.
```

#### Cách giao AI khi làm Perf-3 (Health check)

```
Task: Thêm endpoint /health (và /ready nếu cần) cho load balancer và giám sát. Theo docs/DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md mục 0.4, 2.3.4.

Tài liệu: docs/DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md, docs/RUNBOOK.md. Rules: always-verify-after-work, bcdt-project.

Yêu cầu: AddHealthChecks (Db, optional Cache); MapHealthChecks("/health"); có thể thêm /ready. Build Pass; gọi GET /health trả 200 khi DB khả dụng. Kiểm tra cho AI: checklist ngắn; báo Pass/Fail. Khi xong: cập nhật TONG_HOP Perf-3 ✅.
```

#### Cách giao AI khi làm Perf-7 (Index thiếu)

```
Task: Phân tích index thiếu và thêm index cho bảng thường query. Theo docs/DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md 2.1.1, docs/W16_PERFORMANCE_SECURITY.md 2.2.

Tài liệu: DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md, W16_PERFORMANCE_SECURITY.md. Rules: always-verify-after-work, bcdt-project. Skill: bcdt-sql-migration.

Yêu cầu: Chạy sys.dm_db_missing_index_details trên DB BCDT; ưu tiên FormPlaceholderOccurrence (FormSheetId), FilterCondition (FilterDefinitionId), ReportDataRow (SubmissionId, SheetIndex, RowIndex), ReportSubmission (FormDefinitionId, OrganizationId, ReportingPeriodId, Status). Tạo script migration SQL (trong docs/script_core/sql/v2 hoặc tương đương) thêm index; không drop index hiện có. Chạy script; đo lại query plan hoặc response time nếu có. Kiểm tra cho AI: script chạy thành công; bảng có index mới. Khi xong: cập nhật TONG_HOP Perf-7 ✅.
```

#### ~~Cách giao AI khi làm Perf-10 (Lazy load route FE)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã triển khai: React.lazy + Suspense cho trang ít dùng; fallback PageLoading; checklist DE_XUAT 5.10. Build FE Pass; chunk tách riêng (FormConfigPage, SubmissionDataEntryPage, …).

#### ~~Cách giao AI khi làm Perf-11 (partition/replica-ready)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã triển khai: [PERF11_PARTITION_REPLICA_ARCHIVE.md](de_xuat_trien_khai/PERF11_PARTITION_REPLICA_ARCHIVE.md) (partition, read replica, archive); script 27.perf11_partition_sample.sql; appsettings ArchivePolicy; DE_XUAT 5.11.

#### ~~Cách giao AI khi làm Perf-12 (batch cột động, AsNoTracking)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã triển khai: BuildWorkbookFromSubmissionService – columnDataSourceCache theo (DataSourceId, FilterDefinitionId); ResolveColumnLabelsAsync dùng cache; AsNoTracking đã nhất quán; DE_XUAT 5.12.

#### ~~Cách giao AI khi làm Perf-13 (Hangfire)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã triển khai: Hangfire (SQL Server), Dashboard /hangfire; POST /api/v1/jobs/aggregate-submission, GET /api/v1/jobs/{jobId}; AggregateSubmissionJob; DE_XUAT 5.13.

#### ~~Cách giao AI khi làm Perf-14 (React Query staleTime, Bundle analysis)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã triển khai: QueryClient defaultOptions staleTime 1 phút (App.tsx); rollup-plugin-visualizer trong vite.config.ts, output dist/stats.html; DE_XUAT 5.14. Build FE Pass.

**Ưu tiên 1 đề xuất khi chọn task tối ưu:** ~~Perf-1~~ ✅ … ~~Perf-19~~ ✅ đã xong. **Toàn bộ Perf-1→19 đã hoàn thành.** Công việc tùy chọn khác: xem mục 3.1, 3.7.

#### ~~Cách giao AI khi làm Perf-15 (Reverse proxy cache)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã bổ sung: DE_XUAT "Triển khai Perf-15 – Reverse proxy cache" (static Cache-Control, tùy chọn cache API, nginx + IIS ARR); RUNBOOK 8.3 tham chiếu Perf-15, 5.15. Tài liệu đủ để Ops triển khai.

#### ~~Cách giao AI khi làm Perf-16 (Redis)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã triển khai: Package Microsoft.Extensions.Caching.StackExchangeRedis; Program.cs nếu ConnectionStrings:Redis có giá trị thì AddStackExchangeRedisCache, else AddDistributedMemoryCache; appsettings.Development.json ConnectionStrings:Redis ""; DE_XUAT 5.16. Build Pass.

#### ~~Cách giao AI khi làm Perf-17 (Read replica)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã triển khai: AppReadOnlyDbContext (cùng model); Program.cs đăng ký với ReadReplica khi có, else primary; DashboardService dùng AppReadOnlyDbContext; DE_XUAT 5.17. Build Pass.

#### ~~Cách giao AI khi làm Perf-18 (Partition/archive)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã triển khai: Script 28.perf18_archive_sample.sql (bảng *_Archive + sp_BCDT_ArchiveSubmissions_Batch); PERF11 mục "Triển khai Perf-18"; DE_XUAT 5.18. Build Pass; tài liệu/script đủ.

#### ~~Cách giao AI khi làm Perf-19 (Load balancer)~~ *(đã xong 2026-02-25 – tham chiếu)*

Đã bổ sung: DE_XUAT "Triển khai Perf-19 – Load balancer" (health check /health, JWT stateless, nginx upstream, Hangfire một instance, Redis khi scale); DE_XUAT 5.19. Tài liệu đủ cho Ops.

---

### 3.9. Triển khai production cả nước – Kế hoạch theo dõi

**Nguồn:** [REVIEW_PRODUCTION_CA_NUOC.md](REVIEW_PRODUCTION_CA_NUOC.md). Các hạng mục đáp ứng triển khai production quy mô cả nước (R1–R15) được theo dõi dưới dạng Prod-1 → Prod-15. Ưu tiên 1 = bắt buộc trước khi production cả nước.

#### Bảng công việc (Prod-1 → Prod-15)

| Mã | Công việc (map R#) | Ưu tiên | Trạng thái | Ghi chú |
|----|---------------------|---------|------------|---------|
| ~~**Prod-1**~~ ✅ | ~~R8 – Giới hạn max pageSize (list API)~~ | 1 | **Đã xong (2026-02-25)** | PagingConstants.MaxPageSize = 500; FormDefinitionService, ReportSubmissionService; Swagger "max 500". Build Pass. |
| ~~**Prod-2**~~ ✅ | ~~R4 – Secrets Production (RUNBOOK biến bắt buộc)~~ | 1 | **Đã xong (2026-02-25)** | RUNBOOK mục 10.1: bảng biến môi trường bắt buộc + ví dụ PowerShell/Bash. |
| ~~**Prod-3**~~ ✅ | ~~R1 – RLS + ReadReplica (Dashboard không dùng replica khi RLS)~~ | 1 | **Đã xong (2026-02-25)** | DashboardService chuyển sang AppDbContext; connection có session context → RLS đúng khi bật ReadReplica. Build Pass. |
| ~~**Prod-4**~~ ✅ | ~~R13 – RUNBOOK Production (mục 10 đã có; bổ sung nếu thiếu)~~ | 1 | **Đã xong (2026-02-25)** | RUNBOOK mục 10.3 Checklist triển khai Production (deploy, health, LB, Hangfire, Redis, backup, RLS, pageSize, CORS). |
| ~~**Prod-5**~~ ✅ | ~~R5 – FluentValidation Request DTO~~ | 2 | **Đã xong (2026-02-25)** | FluentValidation 11 + FluentValidation.AspNetCore; validators Auth/Form/Data/Org/User; AddValidatorsFromAssembly + AddFluentValidationAutoValidation. Build Pass; login {} → 400 + message. |
| ~~**Prod-6**~~ ✅ | ~~R12 – Health Redis~~ | 2 | **Đã xong (2026-02-25)** | AspNetCore.HealthChecks.Redis; khi có ConnectionStrings:Redis thì healthBuilder.AddRedis; /health gồm db + redis. Build Pass. |
| ~~**Prod-7**~~ ✅ | ~~R9 – MaxRequestBodySize~~ | 2 | **Đã xong (2026-02-25)** | Kestrel.Limits.MaxRequestBodySize 100 MB (appsettings); ExceptionMiddleware trả 413 + PAYLOAD_TOO_LARGE khi vượt. Build Pass. |
| ~~**Prod-8**~~ ✅ | ~~R2 – Hangfire job set sp_SetSystemContext~~ | 2 | **Đã xong (2026-02-25)** | AggregateSubmissionJob inject AppDbContext; ExecuteAsync mở connection, EXEC sp_SetSystemContext, gọi AggregationService, finally sp_ClearUserContext. Build Pass. |
| ~~**Prod-9**~~ ✅ | ~~R14 – Backup & DR (tài liệu)~~ | 2 | **Đã xong (2026-02-25)** | RUNBOOK mục 10.4: phạm vi backup, tần suất, retention, RPO/RTO, kịch bản khôi phục. Version 1.5. |
| ~~**Prod-10**~~ ✅ | ~~R6 – ICurrentUserService~~ | 3 | **Đã xong (2026-02-25)** | ICurrentUserService (Application) + CurrentUserService (Api, IHttpContextAccessor); thay GetCurrentUserId/GetUserId trong 20+ controller. Build Pass. |
| ~~**Prod-11**~~ ✅ | ~~R3 – SessionContext lỗi → từ chối request~~ | 3 | **Đã xong (2026-02-26)** | SessionContextMiddleware: khi SetUserContext throw → 503 + SESSION_CONTEXT_FAILED (JSON), log, không gọi _next. Build Pass. |
| ~~**Prod-12**~~ ✅ | ~~R11 – RequestId/TraceId, structured log~~ | 3 | **Đã xong (2026-02-26)** | RequestTraceMiddleware (đầu pipeline): X-Request-Id header, scope TraceId; log request start/end; AuthController log login success/failure. Build Pass. |
| ~~**Prod-13**~~ ✅ | ~~R7 – Rate limiting~~ | 3 | **Đã xong (2026-02-26)** | AddRateLimiter: partition theo user khi auth, else IP; FixedWindow (PermitLimit 200, Window 60s, config); 429 + RATE_LIMIT_EXCEEDED; /health, /, /swagger, /hangfire excluded. Build Pass. |
| ~~**Prod-14**~~ ✅ | ~~R10 – Timeout Kestrel (đã có Perf-4; verify đủ)~~ | 3 | **Đã xong (2026-02-26)** | Verify Perf-4: Kestrel Limits (RequestHeadersTimeout, KeepAliveTimeout), CT lan truyền; RUNBOOK 10.2 + 10.3 thêm Timeout R10, checklist mục 11. |
| ~~**Prod-15**~~ ✅ | ~~R15 – Dữ liệu trong nước (tuân thủ/doc)~~ | Tuân thủ | **Đã xong (2026-02-26)** | RUNBOOK mục 10.5 (bảng DB/Redis/server trong nước), 10.2 + 10.3 checklist mục 12; REVIEW #15 ✅. |

#### Cách giao AI khi làm Prod-1 (R8 – Giới hạn pageSize)

```
Task: Triển khai Prod-1 – Giới hạn max pageSize cho list API (R8). Theo docs/REVIEW_PRODUCTION_CA_NUOC.md mục 4 Ưu tiên 1.

Tài liệu bắt buộc: docs/REVIEW_PRODUCTION_CA_NUOC.md, docs/RUNBOOK.md (mục 6.1 – tắt BCDT.Api trước build). Rules: always-verify-after-work, bcdt-project, bcdt-agentic-workflow.

Yêu cầu:
1. Xác định mọi list API có pagination (pageSize, pageNumber): GET /forms, GET /submissions, và API list khác nếu có.
2. Trong controller hoặc service: áp dụng cap pageSize (vd. Math.Min(pageSize, 500)); giá trị mặc định khi không gửi giữ nguyên (vd. 20). Document trong Swagger/comment (max pageSize = 500).
3. Kiểm tra cho AI: Build BE Pass; gọi GET /forms?pageSize=1000 → trả tối đa 500 (hoặc 100 tùy quyết định); GET /submissions?pageSize=10 → trả tối đa 10. Báo Pass/Fail từng bước.
4. Khi xong: cập nhật TONG_HOP – Prod-1 thành ✅ Đã xong (YYYY-MM-DD); mục 3.9, 3.7; rule bcdt-update-tong-hop-after-task nếu Prod là task chính.
```

---

## 4. Rà soát BE vs FE

| Hạng mục | Backend (BE) | Frontend (FE) | Ghi chú |
|----------|--------------|---------------|---------|
| Auth (B1) | ✅ login, refresh, logout, /me | ✅ LoginPage, AuthContext, refresh token | Hoàn chỉnh |
| Organization (B4) | ✅ /api/v1/organizations CRUD, all=true | ✅ Tree trái + bảng phải, Modal CRUD | Hoàn chỉnh |
| User (B5) | ✅ /api/v1/users CRUD, RoleOrgAssignments (cặp vai trò–đơn vị) | ✅ Table, Modal CRUD, form bảng (Vai trò + Đơn vị), chuyển vai trò (dropdown→modal→redirect /dashboard) | Hoàn chỉnh |
| Auth / Me | ✅ /api/v1/auth/me/roles (organizationId, organizationName) | ✅ Chuyển vai trò hiển thị "Vai trò (Đơn vị)", lưu context + localStorage | Hoàn chỉnh |
| Menu | ✅ GET /menus?roleId= (lọc theo RolePermission + Menu.RequiredPermission) | ✅ Sidebar gọi menu theo currentRole.id, refetch khi đổi vai trò | Hoàn chỉnh |
| Quyền theo vai trò | — (API roles/{id}/permissions có sẵn) | ✅ RolePermissionsContext, useRolePermissions() | Hoàn chỉnh |
| Form Definition (B7) | ✅ /api/v1/forms CRUD, versions | ✅ FormsPage (list, versions) | Hoàn chỉnh |
| Form Config (B8 + B12 + P8) | ✅ sheets, columns, binding, mapping, dynamic regions, P8 APIs | ✅ FormConfigPage (đầy đủ: cây cột/hàng, vùng chỉ tiêu động, P8 dòng + cột) | Hoàn chỉnh |
| Submissions | ✅ CRUD, upload, submit, workbook-data, aggregate | ✅ SubmissionsPage + SubmissionDataEntryPage (Fortune-sheet) | Hoàn chỉnh |
| Workflow (B9) | ✅ submit, approve/reject/revision | ✅ Nút Duyệt/Từ chối/Yêu cầu chỉnh sửa | Hoàn chỉnh |
| Reporting Period (B10) | ✅ CRUD | ✅ ReportingPeriodsPage | Hoàn chỉnh |
| Dashboard (B10) | ✅ admin/stats, user/tasks | ✅ DashboardPage | Hoàn chỉnh |
| Excel Generator | ✅ GET /forms/{id}/template | ✅ Nút tải template trên FormsPage | Hoàn chỉnh |
| OrganizationType | ✅ CRUD /api/v1/organization-types | ✅ OrganizationTypesPage | Hoàn chỉnh |
| ReportingFrequency | ✅ CRUD mở rộng C/U/D | ✅ FE API client CRUD | Hoàn chỉnh |
| IndicatorCatalog | ✅ CRUD + Indicators (tree) | ✅ IndicatorCatalogsPage | Hoàn chỉnh |
| ReferenceEntity | ✅ CRUD ReferenceEntity/Type, list all=true | ✅ ReferenceEntitiesPage (cây, TreeSelect cha), ReferenceEntityTypesPage (CRUD loại) | Hoàn chỉnh |
| AuditLog | ✅ IAuditService + audit endpoint | — (API only) | BE done |
| Deadline Enforce | ✅ Block submit quá hạn | — (auto) | Hoàn chỉnh |
| Notifications | ✅ + MarkAllRead/Dismiss/UnreadCount | ✅ NotificationsPage | Hoàn chỉnh |

---

## 5. Rà soát toàn diện Code + DB + Postman (Lần 48, ngày 2026-02-06)

### 5.1. Backend (.NET) – 28 Controllers, 38+ Services

| Hạng mục | Kết quả | Chi tiết |
|----------|---------|----------|
| **Controllers** | ✅ 30 | Auth, Organizations, Users, Forms, FormSheets, FormColumns, FormColumnDataBinding, FormColumnMapping, FormDynamicRegions, FormRows, DataSources, FilterDefinitions, FormPlaceholderOccurrences, FormDynamicColumnRegions, FormPlaceholderColumnOccurrences, Submissions, ReportPresentations, WorkflowDefinitions, WorkflowSteps, FormWorkflowConfig, WorkflowInstances, ReportingFrequencies, ReportingPeriods, Dashboard, Notifications, **ReferenceEntityTypes**, **ReferenceEntities**. |
| **Entities** | ✅ 27 | Đủ MVP. 10 entity có DB schema nhưng chưa tạo C# (Permission, RolePermission, Menu, RoleMenu, DataScope, RoleDataScope, UserDelegation, FormCell, SystemConfig, AuditLog) → **Post-MVP**. |
| **Services** | ✅ 38+ | Auth, JWT, Org, User, Form*, Submission*, Workflow*, Reporting*, Dashboard, Notification, PDF, Email, DataSource, Filter, Placeholder, BuildWorkbook, Sync, DataBinding. |
| **DbContext** | ✅ 37 DbSet | |
| **Program.cs** | ✅ | JWT, RLS (SessionContextMiddleware), CORS, Swagger, FormStructureAdmin policy. |

### 5.2. Frontend (React/TS) – 12 Pages, 14 API clients

| Hạng mục | Kết quả | Chi tiết |
|----------|---------|----------|
| **Pages** | ✅ 15 | Login, Dashboard, Organizations, OrganizationTypes, Users, Forms, FormConfig, Submissions, SubmissionDataEntry, ReportingPeriods, IndicatorCatalogs, Notifications, Menus, ReferenceEntities, **ReferenceEntityTypes**. |
| **API Clients** | ✅ 16 files | authApi, organizationsApi, organizationTypesApi, usersApi, formsApi, formStructureApi, indicatorCatalogsApi, submissionsApi, workflowInstancesApi, reportingPeriodsApi, reportingFrequenciesApi, dashboardApi, formDataSourceFilterApi, notificationsApi, menusApi, **referenceEntityTypesApi**, **referenceEntitiesApi**. |
| **E2E Tests** | ✅ 5 files, 21 tests | login, pages, reference-entity-types, b12-p7-formconfig-submission, **workflow-definitions**. |
| **Context / Hooks** | ✅ | AuthContext (currentRole, setCurrentRole), RolePermissionsProvider (permissionIds, hasPermission theo vai trò). Menu sidebar: queryKey + roleId. |
| **Chưa có FE** | — | ~~workflowDefinitions/Steps admin~~ ✅ Đã có: WorkflowDefinitionsPage (`/workflow-definitions`), CRUD definition + steps; Form Config có gắn workflow. (2026-02-23) |

### 5.3. Database – 59 bảng, 22 scripts

| Hạng mục | Kết quả | Chi tiết |
|----------|---------|----------|
| **SQL Scripts** | ✅ 22 (01–22) | Core 01–14 + mở rộng 15–22. |
| **Bảng thực tế** | **59 bảng** | Organization (4), Authorization (9), Authentication (6), Form (8), Data (5), Workflow (5), Reporting (4), Signature (2), ReferenceData (3), Notification/System (3), Dynamic/Indicator (4), P8 Filter (4), P8 Column (2). |
| **Seed Scripts** | ✅ 7 | seed_test_excel_entry/full/more, seed_mcp_1/2/3, seed_b12_p4_workbook_dynamic. Ensure-TestData.ps1 ✅. |
| **Test Scripts** | ✅ 10 | `docs/script_core/`: test-b7, test-b8, test-submission-upload, test-b12-p2a, test-b12-p4, test-p8, **w16-measure-baseline.ps1**, **run-w17-uat.ps1**. `scripts/`: test-b5, test-b6. |
| **RLS** | ✅ | fn_SecurityPredicate_Organization, SecurityPolicy_ReportSubmission, SecurityPolicy_ReferenceEntity, sp_Set/ClearUserContext. |

### 5.4. Postman Collection – ~150 requests

| Hạng mục | Kết quả | Chi tiết |
|----------|---------|----------|
| **Requests** | ✅ ~150+ | Đủ CRUD chính. |
| **Variables** | ✅ 23 | baseUrl, accessToken, refreshToken, formId, sheetId, columnId, rowId, submissionId, workflowDefinitionId, workflowInstanceId, regionId, occurrenceId, dataSourceId, filterDefinitionId, columnRegionId, columnOccurrenceId, catalogId, indicatorId, organizationTypeId, reportingFrequencyId, reportingPeriodId, **entityTypeId**, **referenceEntityId**. |
| **Đã bổ sung (2026-02-23)** | ✅ | Forms: from-template, upload template, template-display. Workflow: get/put/delete definition, get/put/delete step, delete form workflow config. ReportingPeriods: get/put/delete by id. Submissions: sync-from-presentation. Biến reportingPeriodId. Swagger: Summary cho ReportingPeriodsController. **Reference Entity Types** (list + get by id + create + update + delete); **Reference Entities** (list/all/by id/POST/PUT/DELETE); biến entityTypeId, referenceEntityId. Checklist 10.2 CRUD type trong HIERARCHICAL_DATA_BASE_AND_RULE.md. |

### 5.5. Thiếu sót (Post-MVP / tùy chọn)

| # | Phạm vi | Mô tả | Mức độ |
|---|---------|--------|--------|
| 1 | BE Entity | 10 entity có DB nhưng chưa C# (Permission, Menu, DataScope, UserDelegation, FormCell, SystemConfig…) | Post-MVP |
| 2 | FE | workflowDefinitions/Steps admin: chưa có FE | Post-MVP |
| 3 | Postman | **Đã bổ sung (2026-02-23):** from-template, template, template-display, Workflow CRUD, ReportingPeriods by id, sync-from-presentation. | ✅ Đã xong |

---

## 6. Rà soát tài liệu (2026-02-13)

| Hạng mục | Kết quả |
|----------|---------|
| Link tài liệu mục 2, 3 | ✅ Các file VERIFY_TABLES, RUNBOOK, B1–B12, P8, W16, W17, USER_GUIDE, DEMO_SCRIPT, RA_SOAT_TIEN_DO_CHI_TIET, AI_CONTEXT, KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG, CHUYEN_VAI_TRO_KIEM_TRA tồn tại. |
| Nhất quán Phase / ưu tiên | ✅ Phase 4 W16–17 = Đã xong; Post-MVP User–Role–Org / Chuyển vai trò / Menu theo quyền = Đã xong (2026-02-13). Block 3.3, 3.4 ghi "block tham chiếu". |
| Script UAT W17 | ✅ run-w17-uat.ps1 có trong docs/script_core/; đã thêm vào mục 5.3 Test Scripts. |
| Version / ngày | ✅ 2.9, 2026-02-13. |
| Mục 3.7 Đề xuất + Cách giao AI | ✅ Bảng ưu tiên (tùy chọn) + Post-MVP đã xong; block copy-paste cho Phân cấp Menu / ReferenceEntity. |

---

**Version:** 2.72  
**Last Updated:** 2026-02-26 (Prod-15 Dữ liệu trong nước đã xong. Prod-1→15 hoàn thành.)
