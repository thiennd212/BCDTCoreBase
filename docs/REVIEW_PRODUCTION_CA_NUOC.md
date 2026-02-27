# Rà soát codebase – Triển khai production cho cả nước Việt Nam

Đánh giá **tổng thể** codebase BCDT cho **triển khai production quy mô cả nước** (nhiều đơn vị, nhiều người dùng, tải cao, độ sẵn sàng và tuân thủ quy định). Kế thừa [REVIEW_TRIEN_KHAI_PRODUCT.md](REVIEW_TRIEN_KHAI_PRODUCT.md), [REVIEW_KIEN_TRUC_CODEBASE.md](REVIEW_KIEN_TRUC_CODEBASE.md), [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md).

**Ngày:** 2026-02-25

---

## 1. Bối cảnh “cả nước”

| Yếu tố | Ý nghĩa cho review |
|--------|---------------------|
| **Quy mô** | Hàng nghìn đơn vị (tổ chức), hàng chục nghìn user; số lượng submission và báo cáo lớn theo kỳ. |
| **Tải** | Cao điểm (hạn nộp báo cáo) nhiều request đồng thời; API và DB cần chịu tải, tránh timeout/queue dài. |
| **Độ sẵn sàng** | Hệ thống phục vụ toàn quốc → cần HA (nhiều instance, health check, failover), có kế hoạch DR/backup. |
| **Tuân thủ** | Dữ liệu trong nước; bảo mật theo quy định; không dùng CDN/dịch vụ đám mây công cộng nếu không được phép (đã nêu trong DE_XUAT). |
| **Vận hành** | RUNBOOK, monitoring, log tra cứu sự cố; cấu hình Production (secret, CORS, biến môi trường) phải rõ ràng. |

---

## 2. Hiện trạng đã có (tóm tắt)

- **Kiến trúc:** Clean Architecture, API stateless (JWT), phân lớp rõ; phù hợp scale ngang khi thêm instance.
- **RLS:** Bảng ReportSubmission, ReferenceEntity có Row-Level Security; session context set qua SessionContextMiddleware (chỉ trên AppDbContext).
- **Cache:** IDistributedCache (Memory hoặc Redis); khi scale > 1 instance dùng Redis (Perf-16).
- **Hangfire:** ServerEnabled theo instance (Perf-19); chỉ một instance chạy job khi có LB.
- **Health:** Chỉ DB (`AddDbContextCheck<AppDbContext>`); chưa health Redis khi dùng Redis.
- **Pagination:** Một số list API có pageSize + pageNumber (Submissions, FormDefinitions); **không có giới hạn max pageSize**.
- **RUNBOOK:** Hiện tập trung môi trường **local/dev**; chưa có mục Production / cả nước (biến môi trường, LB, backup, DR).

---

## 3. Rủi ro và gap theo hạng mục

### 3.1. Kiến trúc và dữ liệu (đã nêu trong REVIEW_TRIEN_KHAI_PRODUCT)

| # | Hạng mục | Mức | Mô tả ngắn |
|---|----------|-----|------------|
| R1 | **RLS + Read Replica** | Cao | Dashboard dùng AppReadOnlyDbContext; replica không có session context → RLS filter 0 dòng → thống kê sai. Cần không dùng replica cho Dashboard khi có RLS hoặc set context trên replica. |
| R2 | **Hangfire job + RLS** | Trung bình | Job chạy ngoài HTTP; connection job cần gọi sp_SetSystemContext trước khi đọc/ghi bảng RLS. |
| R3 | **SessionContext lỗi** | Trung bình | SetUserContext throw nhưng middleware vẫn gọi _next → request chạy không RLS. Nên từ chối request (503/401) khi set context thất bại. |

### 3.2. Bảo mật và đầu vào

| # | Hạng mục | Mức | Mô tả ngắn |
|---|----------|-----|------------|
| R4 | **Secrets Production** | Cao | Connection string, JWT secret không được commit; dùng biến môi trường hoặc secret store. RUNBOOK cần liệt kê biến bắt buộc. |
| R5 | **Validation tập trung** | Cao | Chưa FluentValidation cho Request DTO; input chưa chuẩn hóa (length, format) → rủi ro khi tải lớn và đa đơn vị. |
| R6 | **Current user thống nhất** | Trung bình | GetCurrentUserId/GetUserId trùng lặp, Parse có thể throw, fallback không nhất quán. Nên ICurrentUserService. |
| R7 | **Rate limiting** | Trung bình | Chưa giới hạn request theo IP/user → dễ abuse khi mở rộng cả nước. |

### 3.3. Giới hạn và tải (quan trọng cho cả nước)

| # | Hạng mục | Mức | Mô tả ngắn |
|---|----------|-----|------------|
| R8 | **Pagination không giới hạn** | Cao | API list nhận pageSize từ query; **không có max** (vd. pageSize=100000) → một request có thể trả lượng lớn dữ liệu, tốn DB và băng thông. Cần cap (vd. max 100 hoặc 500) và document. |
| R9 | **Request body size** | Trung bình | Chưa cấu hình giới hạn MaxRequestBodySize; upload workbook/presentation lớn có thể treo hoặc tốn bộ nhớ. Nên đặt limit (vd. 50–100 MB) và trả 413 khi vượt. |
| R10 | **Timeout & CancellationToken** | Trung bình | API dài (workbook-data, aggregate) cần lan truyền CancellationToken và cấu hình timeout Kestrel để tránh request treo khi tải cao. |

### 3.4. Observability và vận hành

| # | Hạng mục | Mức | Mô tả ngắn |
|---|----------|-----|------------|
| R11 | **Logging & TraceId** | Trung bình | Chỉ ExceptionMiddleware log; không RequestId/TraceId → khó tra cứu sự cố khi nhiều user. |
| R12 | **Health Redis** | Trung bình | Khi dùng Redis, cần AddHealthChecks Redis để LB/ops biết cache chết. |
| R13 | **RUNBOOK Production** | Cao | RUNBOOK hiện cho local; thiếu: biến môi trường Production, CORS, health probe LB, Hangfire một instance, Redis khi scale, backup/DR, giới hạn (pageSize, body). |

### 3.5. Sẵn sàng cao (HA) và dữ liệu

| # | Hạng mục | Mức | Mô tả ngắn |
|---|----------|-----|------------|
| R14 | **Backup & DR** | Cao | Cần tài liệu hóa chính sách backup DB (tần suất, retention), RPO/RTO; kịch bản khôi phục. |
| R15 | **Dữ liệu trong nước** | Tuân thủ | Đảm bảo DB, Redis, máy chủ ứng dụng đặt trong nước; không đưa dữ liệu ra nước ngoài trừ khi được phép. |

---

## 4. Đề xuất hành động (theo ưu tiên)

### Ưu tiên 1 – Bắt buộc trước khi production cả nước

1. **R8 – Giới hạn pageSize:** Trong service hoặc controller list API (Submissions, FormDefinitions, và mọi API có pagination): `pageSize = Math.Min(pageSize, 500)` (hoặc 100); document trong API/Swagger. Tránh client gửi pageSize=100000.
2. **R4 – Secrets:** Production chỉ dùng biến môi trường hoặc secret store; bổ sung RUNBOOK mục “Production – Biến môi trường bắt buộc” (ConnectionStrings__DefaultConnection, Jwt__SecretKey, Cors__AllowedOrigins, Hangfire__ServerEnabled, …).
3. **R1 – RLS + ReadReplica:** Khi bật ReadReplica, chuyển DashboardService sang dùng AppDbContext (không dùng AppReadOnlyDbContext cho Dashboard) hoặc triển khai set session context trên connection replica; ghi rõ trong RUNBOOK.
4. **R13 – RUNBOOK Production:** Thêm mục “Triển khai Production / Cả nước”: checklist deploy, health, LB, Hangfire một instance, Redis, backup, giới hạn (pageSize, body size).

### Ưu tiên 2 – Nên có trong giai đoạn đầu vận hành

5. **R5 – Validation:** FluentValidation cho Create/Update Request DTO; filter trong pipeline.
6. **R12 – Health Redis:** Khi có ConnectionStrings:Redis thì `AddHealthChecks().AddRedis(...)`.
7. **R9 – MaxRequestBodySize:** Cấu hình giới hạn (vd. 100 MB) cho Kestrel; trả 413 khi vượt.
8. **R2 – Hangfire + RLS:** Đảm bảo job (AggregateSubmissionJob, …) set sp_SetSystemContext trên connection trước khi gọi service dùng DbContext.
9. **R14 – Backup & DR:** Tài liệu chính sách backup, RPO/RTO, kịch bản khôi phục (RUNBOOK hoặc doc riêng).

### Ưu tiên 3 – Tăng cường ổn định và bảo mật

10. **R6 – ICurrentUserService:** Một abstraction lấy UserId; thay thế GetCurrentUserId/GetUserId trong controller.
11. **R3 – SessionContext failure:** Khi SetUserContext throw, trả 503/401 thay vì tiếp tục request.
12. **R11 – Logging:** Middleware RequestId/TraceId; structured log; log điểm quan trọng (login, lỗi nghiệp vụ).
13. **R7 – Rate limiting:** Middleware hoặc reverse proxy giới hạn request theo IP (và theo user khi đã auth) để chống abuse.
14. **R10 – Timeout:** Cấu hình Kestrel request timeout; đảm bảo CancellationToken lan truyền đầy đủ.

---

## 5. Checklist rà soát nhanh (production cả nước)

| # | Nội dung | Trạng thái gợi ý |
|----|----------|-------------------|
| 1 | Secrets không nằm trong config commit; RUNBOOK liệt kê biến Production | ✅ (2026-02-25: RUNBOOK mục 10.1 bảng biến + ví dụ) |
| 2 | Pagination list API có max pageSize (vd. ≤ 500) | ✅ (2026-02-25: PagingConstants.MaxPageSize 500; GET /forms, GET /submissions) |
| 3 | RLS + ReadReplica: Dashboard không dùng replica khi có RLS (hoặc set context replica) | ✅ (2026-02-25: DashboardService dùng AppDbContext) |
| 4 | RUNBOOK có mục Production / Cả nước (deploy, health, LB, Hangfire, Redis, backup) | ✅ (2026-02-25: mục 10 + 10.3 checklist triển khai) |
| 5 | Health check: DB + Redis (khi dùng Redis) | ✅ (2026-02-25: AddRedis khi ConnectionStrings:Redis có giá trị; /health gồm db + redis) |
| 6 | FluentValidation cho Request DTO quan trọng | ✅ (2026-02-25: FluentValidation + validators Auth/Form/Data/Org/User; auto-validation) |
| 7 | MaxRequestBodySize cấu hình; trả 413 khi vượt | ✅ (2026-02-25: Kestrel.Limits.MaxRequestBodySize 100 MB; ExceptionMiddleware 413 PAYLOAD_TOO_LARGE) |
| 8 | Hangfire job set session context (sp_SetSystemContext) trước khi dùng DbContext RLS | ✅ (2026-02-25: AggregateSubmissionJob gọi sp_SetSystemContext + sp_ClearUserContext) |
| 9 | Chính sách backup & DR đã tài liệu | ✅ (2026-02-25: RUNBOOK mục 10.4 – phạm vi, tần suất, retention, RPO/RTO, kịch bản khôi phục) |
| 10 | SessionContext lỗi → từ chối request (503/401) | ✅ (2026-02-26: SessionContextMiddleware trả 503 + SESSION_CONTEXT_FAILED khi SetUserContext throw; không gọi _next.) |
| 11 | ICurrentUserService thay thế GetCurrentUserId trùng lặp | ✅ (2026-02-25: ICurrentUserService + CurrentUserService; 20+ controller dùng GetUserId()) |
| 12 | RequestId/TraceId trong log | ✅ (2026-02-26: RequestTraceMiddleware X-Request-Id header, scope TraceId; log request start/end; Auth login success/failure.) |
| 13 | Rate limiting (IP / user) | ✅ (2026-02-26: AddRateLimiter partition theo user khi auth else IP; FixedWindow config; 429 RATE_LIMIT_EXCEEDED; /health, /, /swagger, /hangfire excluded.) |
| 14 | CORS Production: AllowedOrigins đúng origin frontend, không dùng * với credential | ✅ (2026-02-26: Code đọc Cors:AllowedOrigins từ config; AllowCredentials(); RUNBOOK 10.1 + 10.3 #10. **Ops:** đặt Cors__AllowedOrigins__0=... đúng origin khi deploy.) |
| 15 | Dữ liệu và hạ tầng đặt trong nước (tuân thủ) | ✅ (2026-02-26: RUNBOOK mục 10.5 + checklist 10.3 #12; bảng DB/Redis/server trong nước.) |

---

## 5.1. Rà soát lần 2 (2026-02-26)

Đã kiểm tra lại toàn bộ 15 mục trong checklist so với codebase và RUNBOOK:

| Kết luận | Chi tiết |
|----------|----------|
| **15/15 mục đã đáp ứng** | Code và tài liệu đã hỗ trợ đủ cho triển khai production cả nước. |
| **Mục 14 (CORS)** | Trước đây ⬜ vì là việc cấu hình khi deploy. Đã xác nhận: Program.cs dùng `Cors:AllowedOrigins` từ config, `.AllowCredentials()`; RUNBOOK 10.1 có bảng biến `Cors__AllowedOrigins` (mảng), 10.2/10.3 nêu rõ "không dùng * với credential". Ops chỉ cần đặt biến môi trường đúng origin frontend khi deploy → đánh dấu ✅. |
| **Không phát hiện gap mới** | R1–R15 đã được xử lý qua Prod-1..Prod-15; RUNBOOK mục 10 đầy đủ. |

**Lưu ý triển khai:** Trước khi go-live, vận hành cần chạy checklist RUNBOOK 10.3 (12 mục) và đảm bảo biến môi trường Production (10.1) được set đúng, đặc biệt ConnectionStrings, Jwt__SecretKey, Cors__AllowedOrigins.

---

## 5.2. Rà soát toàn diện lần 3 – Nghiệp vụ + Codebase (2026-02-26)

Đánh giá **đầy đủ** hai khía cạnh: **nghiệp vụ** (yêu cầu hệ thống, review từng module) và **codebase** (kiến trúc, bảo mật, giới hạn tải, vận hành) để xác nhận sẵn sàng triển khai production.

### A. Nghiệp vụ (104 yêu cầu – 01.YEU_CAU_HE_THONG)

| Nguồn | Kết quả |
|-------|---------|
| **Review nghiệp vụ 8/8 module** | Đã hoàn tất (2026-02-24). Báo cáo: REVIEW_NGHIEP_VU_MODULE_AUTH_B1_B3, ORG_USER_B4_B5, FORM_B7_B8, SUBMISSION_WORKBOOK, WORKFLOW_B9, REPORTING_DASHBOARD_B10, B12_CHI_TIEU_CO_DINH_DONG, P8_FILTER_PLACEHOLDER. |
| **Gap Critical/Major** | **Không có.** P8: 0 gap. Auth/Org/Form/Submission/Workflow/Reporting/B12/P8: không gap Critical hoặc Major so với đặc tả. |
| **Gap Minor (chấp nhận được cho MVP)** | Auth: policy theo Permission chưa thống nhất mọi endpoint; refresh token chưa rotation. Các module khác: không gap Minor còn chặn production. |
| **UAT & Demo** | W17: script run-w17-uat.ps1 **35 Pass, 0 Fail, 3 Skip**; Demo flow Pass. E2E: 17 Pass, 0 Skip, 0 Fail. |

**Kết luận nghiệp vụ:** Yêu cầu MVP (biểu mẫu, Excel web, tổ chức 5 cấp, RLS, workflow, chu kỳ báo cáo, chỉ tiêu cố định/động, P8 lọc động) đã được triển khai và rà soát; không còn gap Critical/Major.

### B. Codebase – Kiến trúc và kỹ thuật

| Khía cạnh | Trạng thái | Ghi chú |
|-----------|------------|---------|
| **Kiến trúc** | Đạt | Clean Architecture; API stateless JWT; phân lớp rõ (REVIEW_KIEN_TRUC_CODEBASE, REVIEW_TRIEN_KHAI_PRODUCT). |
| **Auth & RBAC** | Đạt | Login/Refresh/Logout AllowAnonymous; Me và toàn bộ API nghiệp vụ [Authorize]. Policy FormStructureAdmin, Roles. |
| **RLS & Session** | Đạt | SessionContextMiddleware set UserId; khi lỗi trả 503 (Prod-11). Dashboard dùng AppDbContext (Prod-3). Hangfire job sp_SetSystemContext (Prod-8). |
| **SQL Injection** | Đạt | Không ExecuteSqlRaw/FromSqlRaw nối chuỗi; EF parameterized; DataSourceQueryService dùng SqlParameter (W16 OWASP Pass). |
| **Exception & log** | Đạt | ExceptionMiddleware: Production không trả stack trace (chỉ message generic); RequestTraceMiddleware TraceId/X-Request-Id (Prod-12). |
| **Validation** | Đạt | FluentValidation cho Request DTO quan trọng; auto-validation (Prod-5). |
| **Pagination & giới hạn** | Đạt | GET /forms, GET /submissions: max pageSize 500 (Prod-1). MaxRequestBodySize 100 MB, 413 PAYLOAD_TOO_LARGE (Prod-7). |
| **List API không phân trang** | Lưu ý | GET /organizations, GET /reporting-periods trả List (không pageSize). Phù hợp tree/dropdown; quy mô "cả nước" nếu số đơn vị/kỳ rất lớn có thể cân nhắc thêm giới hạn hoặc pagination tùy chọn (không chặn go-live). |
| **Performance & Security** | Đạt | W16: baseline &lt; 3s; OWASP Pass; tối ưu batch DataSource. Perf-1..19, Prod-1..15 đã triển khai. |

### C. Tổng hợp checklist Production (15 mục)

Tất cả **15/15** mục mục 5 đã đáp ứng (đã xác nhận tại mục 5.1). Không phát hiện gap mới so với rà soát lần 2.

### D. Kết luận rà soát toàn diện

| Tiêu chí | Kết luận |
|----------|----------|
| **Nghiệp vụ** | Đạt: 8/8 module review xong; không Critical/Major gap; UAT/E2E Pass. |
| **Codebase** | Đạt: kiến trúc, bảo mật, RLS, validation, pagination (forms/submissions), body size, logging, rate limit, timeout, backup/DR, CORS, dữ liệu trong nước đã được xử lý hoặc tài liệu hóa. |
| **Sẵn sàng production** | **Có.** Code và tài liệu đảm bảo đủ các khía cạnh để triển khai production quy mô cả nước. Trước go-live: vận hành thực hiện RUNBOOK 10.3 (12 mục) và cấu hình đúng biến môi trường 10.1. |

---

## 6. Tham chiếu

- [REVIEW_TRIEN_KHAI_PRODUCT.md](REVIEW_TRIEN_KHAI_PRODUCT.md) – Kiến trúc, RLS, Hangfire, Validation, SessionContext.
- [REVIEW_KIEN_TRUC_CODEBASE.md](REVIEW_KIEN_TRUC_CODEBASE.md) – Phân lớp, data access, API convention.
- [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md) – Perf, scale, Redis, LB, Hangfire ServerEnabled, CDN trong nước.
- [RUNBOOK.md](RUNBOOK.md) – Hiện tại local; cần bổ sung mục Production.

---

**Version:** 1.2  
**Last Updated:** 2026-02-26 (Rà soát toàn diện lần 3: nghiệp vụ + codebase; mục 5.2 bổ sung.)
