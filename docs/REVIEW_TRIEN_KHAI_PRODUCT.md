# Review triển khai product – Kiến trúc và các thành phần

Đánh giá **chuyên sâu** codebase BCDT cho **triển khai production** (product), bao gồm kiến trúc tổng thể, từng layer, thành phần hạ tầng, và các rủi ro/gap cần xử lý trước khi lên product.

**Tham chiếu:** [REVIEW_KIEN_TRUC_CODEBASE.md](REVIEW_KIEN_TRUC_CODEBASE.md), [04.GIAI_PHAP_KY_THUAT.md](script_core/04.GIAI_PHAP_KY_THUAT.md), [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md).

**Ngày:** 2026-02-24

---

## 1. Kiến trúc tổng thể

### 1.1. Sơ đồ phân lớp (Clean Architecture)

```
                    ┌─────────────────────────────────────┐
                    │           BCDT.Domain                │
                    │  (Entities, không phụ thuộc gì)      │
                    └──────────────────┬──────────────────┘
                                       │
        ┌──────────────────────────────┼──────────────────────────────┐
        │                              │                              │
        ▼                              ▼                              ▼
┌───────────────┐            ┌─────────────────┐            ┌─────────────────────┐
│ BCDT.Application│            │   BCDT.Api      │            │ BCDT.Infrastructure  │
│ • I*Service    │            │ • Controllers   │            │ • AppDbContext       │
│ • DTOs         │◄───────────│ • Middleware    │───────────►│ • AppReadOnlyDbContext│
│ • Result, Common│            │ • Program.cs   │   DI       │ • *Service (impl)    │
│ • Validators   │            │ • Auth, CORS   │            │ • Jobs (Hangfire)     │
└───────────────┘            └────────┬────────┘            │ • Cache, Excel, Sync │
        │                              │                     └──────────┬──────────┘
        │                              │                                │
        └──────────────────────────────┼────────────────────────────────┘
                                       │
                    ┌──────────────────┴──────────────────┐
                    │  SQL Server (primary + optional        │
                    │  ReadReplica), Redis (optional),      │
                    │  Hangfire storage (SQL Server)        │
                    └──────────────────────────────────────┘
```

- **Domain:** Chỉ chứa entity (POCO), không reference project nào. Đúng chuẩn.
- **Application:** Chỉ reference Domain. Định nghĩa I*Service, DTOs, Result; không biết DB hay HTTP.
- **Infrastructure:** Reference Domain + Application. Implement toàn bộ service, DbContext, Hangfire job, cache.
- **Api:** Reference Application + Infrastructure. Composition root (DI), Controllers, Middleware.

**Đánh giá:** Dependency direction đúng; phù hợp mở rộng và test (có thể mock I*Service).

### 1.2. Luồng request HTTP (thứ tự middleware)

```
Request → ExceptionMiddleware (bắt exception)
        → ResponseCompression
        → [Dev] Swagger
        → UseHttpsRedirection
        → UseCors
        → UseAuthentication (JWT, OnTokenValidated kiểm tra LastLogoutAt)
        → SessionContextMiddleware (set sp_SetUserContext trên connection AppDbContext)
        → UseAuthorization (policy FormStructureAdmin, AdminManageUsers, …)
        → MapControllers
```

**Lưu ý production:**

- **SessionContextMiddleware** chỉ set session context trên **connection của AppDbContext**. Mọi truy vấn dùng **AppDbContext** trong request đó dùng chung connection đã set UserId → RLS đúng.
- **AppReadOnlyDbContext** dùng connection **khác** (read replica hoặc primary). Middleware **không** set session context trên connection này → xem mục 4.1 (Rủi ro RLS khi dùng Read Replica).

### 1.3. Đăng ký DI (Program.cs) – tóm tắt

| Thành phần | Lifetime | Ghi chú |
|------------|----------|---------|
| AppDbContext, AppReadOnlyDbContext | Scoped | Đúng; mỗi request một scope. |
| Toàn bộ I*Service → *Service | Scoped | Đúng. |
| ICacheService → DistributedCacheService | **Singleton** | IDistributedCache (Redis/Memory) là singleton; DistributedCacheService không giữ state request → chấp nhận được. |
| Hangfire (storage + server) | Singleton / theo host | AddHangfireServer chỉ khi Hangfire:ServerEnabled = true. |
| JwtBearer, CORS, HealthChecks | Singleton | Chuẩn ASP.NET Core. |

**Rủi ro DI:** OnTokenValidated (JWT) gọi `GetRequiredService<AppDbContext>()` trong pipeline. Scope là request scope → cùng DbContext với request. Nhưng lúc đó **SessionContextMiddleware chưa chạy** (middleware chạy sau Authentication). Vì vậy query `User.LastLogoutAt` chạy trên connection **chưa** set UserId. Bảng `BCDT_User` hiện không áp dụng RLS → không sai dữ liệu. Nếu sau này bật RLS trên User, cần set session context trước khi có bất kỳ query nào (hoặc dùng connection không RLS cho bảng User).

---

## 2. Thành phần API (BCDT.Api)

### 2.1. Controllers

- **Số lượng:** 35 controller trong `Controllers/ApiV1/`.
- **Route:** Base `/api/v1/`; REST theo resource (forms, submissions, workflow-definitions, …).
- **Auth:** Hầu hết `[Authorize]`; một số endpoint `[Authorize(Roles = "...")]` hoặc policy (FormStructureAdmin, AdminManageUsers, …).
- **Response:** Thống nhất `ApiSuccessResponse<T>` / `ApiErrorResponse`; service trả `Result<T>`, controller map sang HTTP (200, 400, 404, 409).

### 2.2. Trùng lặp GetCurrentUserId / GetUserId

- Nhiều controller có method riêng: `GetCurrentUserId()`, `GetUserId(ClaimsPrincipal)` với tên và kiểu trả về khác nhau (`int?` vs `int`), fallback `-1` hoặc `0`.
- **RolesController, PermissionsController:** Dùng `int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0")` → có thể throw nếu claim lạ; userId = 0 khi thiếu claim gây lỗi logic/audit.
- **Đề xuất:** Tạo `ICurrentUserService` (Application), implement ở Api; controller chỉ inject và dùng. Dùng TryParse; nếu không có userId hợp lệ thì trả 401, không gọi service.

### 2.3. Middleware

| Middleware | Vị trí | Chức năng |
|------------|--------|------------|
| ExceptionMiddleware | Đầu pipeline | Bắt mọi exception; log; trả JSON thống nhất; Production không lộ stack trace. |
| SessionContextMiddleware | Sau Authentication, trước Authorization | Mở connection AppDbContext; gọi sp_SetUserContext(@UserId); sau request gọi sp_ClearUserContext. |

**SessionContextMiddleware – chi tiết:**

- Chỉ chạy khi `User.Identity?.IsAuthenticated == true` và có claim NameIdentifier hợp lệ.
- Dùng `db.Database.GetDbConnection()` (AppDbContext là Scoped → mỗi request một DbContext và một connection). Mở connection nếu chưa mở; set context; sau đó `_next(context)`. Trong finally clear context. Nếu SetUserContext ném exception, middleware vẫn gọi _next (request chạy tiếp nhưng không có RLS) → **rủi ro:** request vẫn có thể đọc/ghi nếu app không từ chối. Cân nhắc khi set context lỗi thì trả 500 hoặc 401 thay vì tiếp tục.

---

## 3. Thành phần Application (BCDT.Application)

### 3.1. Interface (I*Service)

- Khoảng 38+ interface, nhóm theo module (Form, Data, Workflow, Organization, User, Auth, ReportingPeriod, Dashboard, Notification, Role, Permission, Menu, ReferenceEntity, SystemConfig, Cache).
- Method async với CancellationToken; trả về `Result<T>` hoặc DTO.

### 3.2. DTOs

- Nhóm thư mục theo module: DTOs/Form, DTOs/Data, DTOs/Workflow, DTOs/User, DTOs/Auth, …
- Naming: *Dto, Create*Request, Update*Request, *Response. Nhất quán.

### 3.3. Common

- `Result<T>` (IsSuccess, Data, Code, Message); `Result.Ok`, `Result.Fail`.
- `PagedResultDto<T>` (Items, TotalCount, PageNumber, PageSize, HasNext).
- `ApiErrorCodes` (NotFound, ValidationFailed, …).

### 3.4. Validation

- **Hiện trạng:** Không có FluentValidation hay Validator tập trung (không có file *Validator*.cs trong Application).
- **Rủi ro product:** Input từ client chưa được validate chuẩn hóa (length, format, bắt buộc); dễ thiếu hoặc không nhất quán giữa các API.
- **Đề xuất:** Thêm FluentValidation cho Create/Update Request DTO quan trọng; đăng ký và gọi validator (filter hoặc trong controller) trước khi gọi service.

---

## 4. Thành phần Infrastructure

### 4.1. Persistence – AppDbContext và AppReadOnlyDbContext

- **AppDbContext:** 37+ DbSet; dùng cho mọi ghi và đọc có RLS (submission, presentation, workflow, organization, user, …). Connection được set session context bởi SessionContextMiddleware.
- **AppReadOnlyDbContext:** Cùng model với AppDbContext; connection string = ReadReplica nếu cấu hình, không thì trỏ primary. **Chỉ DashboardService** dùng AppReadOnlyDbContext.

**Rủi ro quan trọng (Production):**

- RLS áp dụng cho `BCDT_ReportSubmission` (và ReferenceEntity) qua `fn_SecurityPredicate_Organization(OrganizationId)`, predicate dùng `SESSION_CONTEXT(N'UserId')`.
- **SessionContextMiddleware chỉ set context trên connection của AppDbContext.** Connection của AppReadOnlyDbContext (replica) **không** được set UserId.
- Khi **ReadReplica** được cấu hình, DashboardService (GetAdminStatsAsync, GetUserTasksAsync) truy vấn ReportSubmission qua AppReadOnlyDbContext. Trên connection đó SESSION_CONTEXT(N'UserId') là NULL → predicate RLS không khớp điều kiện user → **filter trả 0 dòng**. Kết quả: **Dashboard admin stats = 0** (sai dữ liệu), **user tasks** có thể thiếu (nếu query dùng bảng có RLS).
- **Kết luận:** Khi bật ReadReplica, Dashboard đọc qua replica sẽ **sai** (under-reporting). Cần hoặc (1) set session context trên connection ReadOnly trước khi query (phức tạp vì replica thường connection khác), hoặc (2) **không dùng ReadOnly cho Dashboard** (dùng AppDbContext cho Dashboard khi đã bật RLS), hoặc (3) tách endpoint Dashboard đọc từ primary khi có RLS.

### 4.2. Services – inject DbContext

- Hầu hết service inject **AppDbContext** (Scoped). Một service (DashboardService) inject **AppReadOnlyDbContext**.
- Không có service nào inject cả hai DbContext trong cùng request cho cùng mục đích RLS; chỉ cần lưu ý replica không có session context như trên.

### 4.3. Cache – ICacheService

- **DistributedCacheService** implement ICacheService; dùng IDistributedCache (Redis hoặc Memory). Serialize JSON UTF-8; TTL mặc định 10 phút.
- **Đăng ký:** Singleton. IDistributedCache (StackExchangeRedis) được đăng ký singleton → không vấn đề.
- Cache dùng cho: ReportingFrequency, OrganizationType, DataSource, FilterDefinition, IndicatorCatalog (master data). Invalidate khi CUD tương ứng.

### 4.4. Hangfire

- Storage: SQL Server (cùng connection string primary).
- **Hangfire:ServerEnabled:** false trên instance chỉ làm API → chỉ một instance chạy job (tránh trùng job). Đúng với mục tiêu LB.
- Job mẫu: **AggregateSubmissionJob** (AutomaticRetry 2 lần). AggregationService inject AppDbContext (Scoped); Hangfire job chạy ngoài HTTP request → connection của job **không** qua SessionContextMiddleware. Script có **sp_SetSystemContext** (12.row_level_security.sql) set `SESSION_CONTEXT(N'IsSystemContext', 1)` để RLS cho phép đọc/ghi. Cần gọi sp_SetSystemContext (hoặc tương đương) trên connection mà job dùng trước khi gọi AggregationService, nếu không RLS có thể chặn truy cập bảng ReportSubmission/ReportDataRow/ReportSummary.

### 4.5. DataSourceQueryService – query động

- Dùng Dapper/raw SQL với **parameterized** (SqlParameter); tên bảng whitelist regex `^[a-zA-Z0-9_]+$`; cột whitelist từ metadata. Không nối chuỗi SQL từ input → an toàn SQL injection.

---

## 5. Thành phần Domain (BCDT.Domain)

- Entity theo module (Form, Data, Workflow, Organization, Authorization, Authentication, ReportingPeriod, ReferenceData, Notification).
- Không phụ thuộc EF hay Application. Đúng vai trò domain thuần.

---

## 6. Thành phần Frontend (bcdt-web)

- **Stack:** React 18, TypeScript, Vite, Ant Design, Fortune-sheet (Excel), React Query.
- **Cấu trúc:** api/ (client theo resource), context/ (AuthContext, RolePermissionsContext), pages/, components/, hooks/, utils/, types/, constants/, theme/.
- **Auth:** JWT lưu trong state + localStorage; refresh token; menu và quyền theo currentRole (role–org).
- **Routing:** React Router; ProtectedRoute; lazy load nhiều trang (Perf-10).
- **React Query:** staleTime 1 phút (Perf-14).

**Production:** Cần cấu hình baseURL API theo môi trường (env); CORS phải khớp origin frontend thật.

---

## 7. Hạ tầng và cấu hình

### 7.1. Database

- **Primary:** Bắt buộc ConnectionStrings:DefaultConnection.
- **ReadReplica:** Tùy chọn; khi có thì AppReadOnlyDbContext dùng replica. Lưu ý RLS với replica (mục 4.1).
- **RLS:** Bảng ReportSubmission, ReferenceEntity có security policy; predicate dùng SESSION_CONTEXT(N'UserId') và (tùy) IsSystemContext.

### 7.2. Redis

- Tùy chọn; khi có ConnectionStrings:Redis thì dùng StackExchangeRedisCache; không thì MemoryDistributedCache. Hỗ trợ Sentinel/Cluster qua connection string (xem DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG).

### 7.3. Health check

- Chỉ **AddDbContextCheck&lt;AppDbContext&gt;("db")**. Khi bật Redis, nên thêm health check Redis để LB/ops biết cache chết.

### 7.4. Config

- appsettings.json (base); appsettings.Development.json. Không có appsettings.Production.json trong repo → Production dùng base + override bằng biến môi trường hoặc secret store. **Production không được commit connection string / JWT secret.**

---

## 8. Tóm tắt rủi ro và gap cho production

| # | Hạng mục | Mức | Mô tả |
|---|----------|-----|--------|
| 1 | **RLS + Read Replica** | **Cao** | Dashboard dùng AppReadOnlyDbContext; connection replica không có session context → RLS filter trả 0 dòng → Dashboard admin/user stats sai khi bật ReadReplica. Cần sửa: set context trên replica hoặc không dùng replica cho Dashboard. |
| 2 | **Validation tập trung** | Cao | Không có FluentValidation; validation rải rác. Cần validator cho Request DTO và gắn vào pipeline. |
| 3 | **Current user thống nhất** | Trung bình | GetCurrentUserId/GetUserId trùng lặp; Parse có thể throw; fallback -1/0 không nhất quán. Cần ICurrentUserService. |
| 4 | **Logging & correlation** | Trung bình | Chỉ ExceptionMiddleware log; không RequestId/TraceId; service hầu như không log. Khó tra cứu sự cố. |
| 5 | **Secrets** | Cao | Production phải dùng env hoặc secret store; không lưu trong config commit. |
| 6 | **Health Redis** | Trung bình | Khi dùng Redis, cần thêm health check Redis. |
| 7 | **Hangfire job + RLS** | Trung bình | Job chạy ngoài request; connection job cần set session context (vd. IsSystemContext) nếu đọc/ghi bảng RLS. |
| 8 | **SessionContext lỗi** | Trung bình | Nếu SetUserContext throw, middleware vẫn gọi _next; request có thể chạy không RLS. Cân nhắc từ chối request khi set context thất bại. |

---

## 9. Đề xuất hành động (theo ưu tiên)

1. **RLS + ReadReplica:** Khi có ReadReplica, không dùng AppReadOnlyDbContext cho Dashboard (chuyển DashboardService sang AppDbContext), hoặc triển khai set session context trên connection ReadOnly trước khi query (phức tạp hơn). Document rõ trong RUNBOOK.
2. **Secrets:** Production dùng biến môi trường hoặc Key Vault; document biến bắt buộc (ConnectionStrings__DefaultConnection, Jwt__SecretKey, …).
3. **Validation:** Thêm FluentValidation cho Create/Update DTO; đăng ký và gọi trong pipeline.
4. **ICurrentUserService:** Một abstraction lấy UserId (và optional OrganizationId); TryParse; thay thế mọi GetCurrentUserId/GetUserId trong controller.
5. **Logging:** Middleware gắn RequestId/TraceId; log request (path, user, status); log lỗi nghiệp vụ ở service quan trọng.
6. **Health:** Thêm health check Redis khi ConnectionStrings:Redis có giá trị.
7. **Hangfire + RLS:** Đảm bảo job (AggregateSubmissionJob, …) khi mở connection set IsSystemContext hoặc UserId phù hợp (sp_SetUserContext) trước khi gọi service dùng DbContext.
8. **SessionContext failure:** Khi SetUserContext ném exception, trả 500 hoặc 401 thay vì tiếp tục request.

---

## 10. Tham chiếu

- [REVIEW_KIEN_TRUC_CODEBASE.md](REVIEW_KIEN_TRUC_CODEBASE.md)
- [04.GIAI_PHAP_KY_THUAT.md](script_core/04.GIAI_PHAP_KY_THUAT.md) – Hybrid storage, RLS, SaveOrchestrator
- [12.row_level_security.sql](script_core/sql/v2/12.row_level_security.sql) – fn_SecurityPredicate_Organization, SecurityPolicy_ReportSubmission
- [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md) – Redis Sentinel/Cluster, Hangfire ServerEnabled, health
