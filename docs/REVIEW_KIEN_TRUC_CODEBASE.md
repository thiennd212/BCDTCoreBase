# Review kiến trúc codebase – BCDT

Tài liệu **đánh giá kiến trúc** hiện tại của dự án BCDT: phân lớp backend, cấu trúc frontend, dependency, pattern, điểm mạnh và đề xuất cải thiện. Tham chiếu: [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md), [04.GIAI_PHAP_KY_THUAT.md](script_core/04.GIAI_PHAP_KY_THUAT.md), [02.KIEN_TRUC_TONG_QUAN.md](script_core/02.KIEN_TRUC_TONG_QUAN.md).

**Ngày review:** 2026-02-25

---

## 1. Tổng quan

| Thành phần | Công nghệ | Ghi chú |
|------------|-----------|---------|
| **Backend** | .NET 8 Web API | Kestrel, Swagger, JWT, CORS |
| **Frontend** | React 18 + TypeScript + Vite | Ant Design, Fortune-sheet (Excel), DevExtreme (một số màn) |
| **Database** | SQL Server | EF Core 8, RLS, session context |
| **Kiến trúc BE** | Phân lớp (Clean Architecture) | API → Application → Domain ← Infrastructure |

---

## 2. Backend – Phân lớp và dependency

### 2.1. Sơ đồ dependency (thực tế)

```
                    ┌─────────────────┐
                    │   BCDT.Domain    │  (Entities, không phụ thuộc layer khác)
                    └────────┬─────────┘
                             │
         ┌───────────────────┼───────────────────┐
         │                   │                   │
         ▼                   ▼                   ▼
┌─────────────────┐ ┌─────────────────┐ ┌─────────────────────────┐
│ BCDT.Application │ │ BCDT.Api        │ │ BCDT.Infrastructure     │
│ (Interfaces,     │ │ (Controllers,   │ │ (DbContext, Services    │
│  DTOs, Common,   │ │  Program,       │ │  impl, Excel, Sync,     │
│  Validators)     │ │  Middleware)    │ │  BuildWorkbook, ...)    │
└────────┬─────────┘ └────────┬────────┘ └────────────┬────────────┘
         │                    │                       │
         │                    │    ┌──────────────────┘
         │                    │    │ (Api đăng ký DI: interface → impl)
         │                    ▼    ▼
         │             Api tham chiếu Application + Infrastructure
         │             Application chỉ tham chiếu Domain
         │             Infrastructure tham chiếu Domain + Application
         └────────────────────┴────────────────────────────────────
```

- **Domain:** Không reference project nào. Chứa Entity theo module (Form, Data, Workflow, Organization, Authorization, …).
- **Application:** Chỉ reference **Domain**. Chứa interface service (I*Service), DTOs, Common (Result, ApiResponse, …), Validators.
- **Infrastructure:** Reference **Domain** + **Application**. Chứa AppDbContext, implement toàn bộ I*Service, các service đặc thù (BuildWorkbookFromSubmissionService, SyncFromPresentationService, DataBindingResolver, …).
- **Api:** Reference **Application** + **Infrastructure**. Controllers gọi I*Service; Program.cs đăng ký DI (interface → implementation), Middleware, Auth, CORS, Swagger.

**Đánh giá:** Đúng hướng Clean Architecture: Domain độc lập, Application định nghĩa use case và port (interface), Infrastructure là adapter (DB, file, external). Api là host composition root.

### 2.2. Cấu trúc thư mục backend (thực tế)

| Layer | Thư mục chính | Ghi chú |
|-------|----------------|---------|
| **Api** | `Controllers/ApiV1/` (28 controller), `Middleware/`, `Program.cs`, `appsettings.*` | Route base `/api/v1/`; không có Hubs/Extensions riêng (có thể bổ sung sau). |
| **Application** | `Common/`, `DTOs/` (Form, Data, Workflow, User, Auth, Organization, …), `Services/` (interface theo module), `Validators/` | DTOs và Services nhóm theo nghiệp vụ (Form, Data, Workflow, …), khớp tài liệu 10 module. |
| **Domain** | `Entities/` (Form, Data, Workflow, Organization, Authorization, Authentication, ReportingPeriod, ReferenceData, Notification), `SystemConfig` | Entity map bảng BCDT_*; không có Enums/Interfaces tách thư mục (có thể nằm lẫn hoặc ít). |
| **Infrastructure** | `Persistence/AppDbContext.cs`, `Services/` (implementation + service đặc thù: BuildWorkbook, SyncFromPresentation, DataBindingResolver, DataSourceQuery, …), `Services/Data/`, `Services/Workflow/`, `Services/Organization/`, … | Không tách Repositories; service inject **AppDbContext** trực tiếp. |

### 2.3. Data access – Repository & Unit of Work

- **Tài liệu (bcdt-project):** "Repository + Unit of Work for EF Core".
- **Thực tế:** Không có lớp Repository/UnitOfWork; mỗi service (trong Infrastructure) inject **AppDbContext** và dùng DbSet trực tiếp (LINQ, SaveChanges).
- **Đánh giá:** Đơn giản hóa hợp lý cho quy mô hiện tại; dễ đọc, ít lớp. Nhược điểm: unit test service cần mock DbContext hoặc dùng in-memory provider; khi query phức tạp hoặc tách read/write có thể cân nhắc thêm Repository hoặc CQRS-lite (query dùng Dapper như đã có trong DataSourceQueryService).

---

## 3. API layer

### 3.1. Convention

- **Base path:** `/api/v1/`.
- **Controller:** Đặt trong `Controllers/ApiV1/`, tên `*Controller`, kế thừa `ControllerBase`.
- **Response:** Dùng `ApiResponse<T>`, `Result<T>` (Application.Common); exception xử lý tập trung (ExceptionMiddleware).
- **Auth:** JWT Bearer; `[Authorize]`, `[Authorize(Roles = "...")]` hoặc policy; session context (UserId, OrganizationId) set trước khi gọi service để RLS đúng.

### 3.2. Điểm mạnh

- RESTful resource rõ (forms, submissions, workflow-definitions, …).
- Version API ngay từ đầu (`/api/v1/`).
- DI nhất quán: controller chỉ nhận I*Service, không phụ thuộc Infrastructure cụ thể.
- CORS, Swagger cấu hình tập trung trong Program.cs.

### 3.3. Đề xuất (tùy chọn)

- Cân nhắc tách endpoint rất nặng (vd. workbook-data, aggregate) sang controller riêng hoặc minimal API nếu cần pipeline khác (timeout, cache).
- Middleware thứ tự: Authentication → set session context (RLS) → Authorization → endpoint; đảm bảo tài liệu RUNBOOK/kiến trúc ghi rõ thứ tự này.

---

## 4. Application layer

### 4.1. Interface & DTO

- **Interface:** Mỗi use case/aggregate có I*Service trong Application, method async với CancellationToken, trả về `Result<T>` hoặc DTO.
- **DTO:** Request/Response/Dto đặt trong `DTOs/<Module>/`; naming nhất quán (Create*Request, Update*Request, *Dto).
- **Common:** Result, ApiResponse, PagedList (nếu có) hỗ trợ thống nhất lỗi và format API.

### 4.2. Điểm mạnh

- Application không biết DB hay EF; chỉ gọi interface → dễ thay implementation (test, tối ưu).
- Nhóm theo module giúp tìm DTO/interface theo nghiệp vụ (Form, Data, Workflow, …).
- FluentValidation (Validators) có thể đặt trong Application để reuse rule.

### 4.3. Đề xuất (tùy chọn)

- CQRS-lite: tách rõ Command (Create/Update/Delete) và Query (GetById, GetList) nếu list/query phức tạp (filter, sort, Dapper).
- Validators: đảm bảo mọi Request DTO có validator và được gọi (filter tự động hoặc trong controller).

---

## 5. Domain layer

### 5.1. Entity

- Entity map 1-1 với bảng BCDT_* (FormDefinition, ReportSubmission, WorkflowInstance, …), nhóm thư mục theo module (Form, Data, Workflow, Organization, Authorization, Authentication, ReportingPeriod, ReferenceData, Notification).
- Không phụ thuộc EF hay Application: chỉ POCO với property.

### 5.2. Điểm mạnh

- Domain thuần, dễ đọc; mapping và cấu hình EF nằm trong Infrastructure (Fluent API hoặc Configuration class).
- Tên bảng/entity thống nhất tiền tố BCDT_.

### 5.3. Đề xuất (tùy chọn)

- Enums cho Status (Draft, Submitted, Approved, …) có thể chuyển từ string sang enum trong Domain nếu muốn type-safe mạnh hơn.
- Value object (vd. địa chỉ, khoảng thời gian) nếu nghiệp vụ phức tạp hơn.

---

## 6. Infrastructure layer

### 6.1. Persistence & service

- **AppDbContext:** DbSet cho toàn bộ entity; cấu hình trong Persistence (Fluent API).
- **Services:** Mỗi I*Service có một implementation; service phức tạp (BuildWorkbookFromSubmissionService, SyncFromPresentationService, DataSourceQueryService, DataBindingResolver) nằm trong Infrastructure vì phụ thuộc DB/EF/Dapper.
- **Hybrid storage:** ReportPresentation (JSON), ReportDataRow (relational), ReportSummary (pre-calc) đúng với tài liệu Hybrid 2-Layer; SaveOrchestrator / sync-from-presentation thể hiện thứ tự ghi và transaction (04.GIAI_PHAP_KY_THUAT).

### 6.2. Điểm mạnh

- Tất cả chi tiết DB, Excel, PDF, notification (mock email) gói trong Infrastructure; Application chỉ gọi interface.
- DataBindingResolver (7 loại), BuildWorkbookFromSubmissionService (form structure + B12 + P8), SyncFromPresentationService tách rõ trách nhiệm.
- Dapper dùng trong DataSourceQueryService cho query động/filter → phù hợp CQRS-lite cho read.

### 6.3. Đề xuất (tùy chọn)

- Transaction: đảm bảo mọi ghi đa bảng (vd. sync presentation + data row + summary) nằm trong một transaction (DbContext.Database.BeginTransaction hoặc TransactionScope) và tài liệu hóa.
- Cache: IMemoryCache cho dữ liệu ít đổi (ReportingFrequency, DataSource metadata, FilterDefinition) đã được đề cập trong W16; triển khai trong Infrastructure, interface có thể đặt trong Application nếu cần abstract.

---

## 7. Frontend (bcdt-web)

### 7.1. Cấu trúc (thực tế)

- **Vite + React 18 + TypeScript.** Thư mục `src/`: `main.tsx`, `App.tsx`, `api/` (client axios, từng module *Api.ts), `context/` (AuthContext, RolePermissionsContext), `pages/` (trang theo route), `components/` (AppLayout, ProtectedRoute, PageLoading, TableActions, …), `hooks/`, `types/`, `theme/`, `constants/`.
- **Routing:** React Router; route bảo vệ qua ProtectedRoute (auth + loading).
- **State:** React Query (TanStack Query) cho server state; Auth + Role qua context.
- **UI:** Ant Design chính; Fortune-sheet cho màn nhập liệu Excel; DevExtreme có thể dùng ở một số màn (theo package.json).

### 7.2. Điểm mạnh

- Tách api client theo resource (formsApi, submissionsApi, …), dễ bảo trì.
- Menu và quyền theo currentRole (role–org); RolePermissionsContext cung cấp hasPermission.
- Trang nhất quán: list (Table/Card) + modal form + filter; constants (MODAL_FORM, table actions) thống nhất.

### 7.3. Đề xuất (tùy chọn)

- Types: đảm bảo DTO/type trùng với backend (có thể sinh từ OpenAPI/Swagger nếu cần).
- Lazy load route (React.lazy) cho trang ít dùng để giảm bundle.
- E2E (Playwright) và test component (Vitest) đã có; duy trì và mở rộng khi thêm tính năng.

---

## 8. Cross-cutting

### 8.1. Bảo mật

- JWT + refresh token; session context (UserId, OrganizationId) set mỗi request để RLS áp dụng đúng.
- Không hardcode secret; connection string và JWT secret trong config (appsettings.Development.json không commit).
- API [Authorize]; role/policy kiểm tra trước khi gọi service.

### 8.2. Lỗi và logging

- ExceptionMiddleware xử lý lỗi tập trung, trả về format thống nhất.
- Logging: dùng ILogger; cấu hình level trong appsettings.

### 8.3. Hybrid storage & RLS

- Kiến trúc Hybrid 2-Layer (Presentation + DataRow + Summary) và thứ tự ghi/transaction đã được mô tả trong 04.GIAI_PHAP_KY_THUAT; implementation khớp.
- RLS và session context đã được nêu trong tài liệu và RUNBOOK; cần đảm bảo mọi truy vấn đọc/ghi đều chạy trong connection đã set context.

---

## 9. Tóm tắt đánh giá

| Tiêu chí | Đánh giá | Ghi chú |
|----------|----------|---------|
| **Phân lớp Clean Architecture** | Đạt | Domain độc lập; Application định nghĩa port; Infrastructure adapter; Api composition root. |
| **Dependency direction** | Đạt | Api → App + Infra; Application → Domain; Infrastructure → Domain + Application. |
| **Naming & convention** | Đạt | BCDT_*, /api/v1/, Result<T>, DTO nhất quán. |
| **Repository / UoW** | Không dùng | Service dùng DbContext trực tiếp; đơn giản, phù hợp quy mô; có thể bổ sung khi cần tách read/write hoặc test. |
| **Hybrid storage & RLS** | Đạt | Đúng thiết kế 2-layer; session context và RLS được áp dụng. |
| **API design** | Đạt | RESTful, version, auth, CORS, Swagger. |
| **Frontend structure** | Đạt | Api client, context, pages, components rõ ràng; React Query + Auth. |
| **Test & docs** | Khá | E2E, Postman; tài liệu CẤU_TRÚC, GIẢI_PHÁP_KỸ_THUẬT, RUNBOOK đầy đủ. |

---

## 10. Đề xuất cải thiện (ưu tiên thấp, tùy roadmap)

1. **Repository/UnitOfWork:** Chỉ thêm nếu cần unit test service dễ hơn hoặc tách read model (Dapper) rõ ràng; hiện tại có thể giữ nguyên.
2. **CQRS-lite:** Mở rộng mô hình query (Dapper, view) cho list/filter nặng; giữ command trong service hiện tại.
3. **Cache:** Áp dụng IMemoryCache cho master data ít đổi (đã nêu trong W16) trong Infrastructure.
4. **OpenAPI client:** Sinh TypeScript client từ Swagger để đồng bộ FE type với API.
5. **Cập nhật CẤU_TRÚC_CODEBASE.md:** Bổ sung "Không dùng Repository/UoW; service inject DbContext"; cập nhật số bảng (59), số controller (28) nếu tài liệu còn ghi số cũ.

---

## 11. Tham chiếu

- [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md) – Cấu trúc thư mục và quy ước.
- [04.GIAI_PHAP_KY_THUAT.md](script_core/04.GIAI_PHAP_KY_THUAT.md) – Hybrid storage, RLS, SaveOrchestrator, Data Binding.
- [02.KIEN_TRUC_TONG_QUAN.md](script_core/02.KIEN_TRUC_TONG_QUAN.md) – Stack, URL, môi trường.
- [.cursor/rules/bcdt-project.mdc](../.cursor/rules/bcdt-project.mdc) – Naming, pattern.
