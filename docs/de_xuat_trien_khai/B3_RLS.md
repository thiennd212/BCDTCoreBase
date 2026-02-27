# Đề xuất triển khai B3 – RLS & Session Context (cho AI)

Tài liệu hướng dẫn AI triển khai **B3: RLS & Session Context** – middleware set UserId (và nếu cần IsSystemContext) lên session context để mọi truy vấn DB tuân thủ Row-Level Security.

**Tham chiếu:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [04.GIAI_PHAP_KY_THUAT.md](../script_core/04.GIAI_PHAP_KY_THUAT.md) mục **1.4 RLS & Session Context**, [12.row_level_security.sql](../script_core/sql/v2/12.row_level_security.sql) (sp_SetUserContext, sp_ClearUserContext).

---

## Agents, Skills và Rules áp dụng cho B3

### Agent nên dùng

| Agent | Khi nào dùng |
|-------|---------------|
| **bcdt-auth-expert** | Triển khai B3 (middleware session context). Chọn agent này khi giao task B3. |

### Rules áp dụng (Cursor rules)

| Rule | Mục đích |
|------|----------|
| **senior-fullstack-standards** | SOLID, Clean Architecture, error handling, async. |
| **bcdt-project** | Layer API → Application → Domain → Infrastructure; không đưa domain logic vào controller. |
| **bcdt-database** | SQL Server BCDT_*, parameterized query, **không bypass RLS**. |
| **always-verify-after-work** | Sau khi làm xong: build, chạy đủ test cases (mục 7.1), báo Pass/Fail từng bước. |

---

## 1. Mục tiêu B3

| Deliverable | Mô tả |
|-------------|--------|
| Middleware Session Context | Chạy **sau** `UseAuthentication()`, **trước** `UseAuthorization()`. Lấy UserId từ Claims (JWT đã validate); trên connection DB dùng cho request, gọi `EXEC sp_SetUserContext @UserId` (và `sp_ClearUserContext` khi kết thúc request hoặc khi có ngoại lệ). |
| Đảm bảo truy vấn dùng session context | Mọi truy vấn EF Core / Dapper trong request dùng **cùng connection** (hoặc scope) đã set session context. Không bypass RLS. |

---

## 2. Đặc tả kỹ thuật (theo 04.GIAI_PHAP_KY_THUAT 1.4)

1. Lấy **UserId** từ Claims (vd `ClaimTypes.NameIdentifier`) sau khi JWT được validate. Nếu request không có Bearer token (anonymous) thì **không** gọi sp_SetUserContext (hoặc set null) – tùy chính sách: có thể chỉ set khi đã auth.
2. (Tùy chọn) Lấy **OrganizationId** hoặc danh sách org từ Claims/service nếu RLS predicate cần – hiện RLS trong 12.row_level_security.sql dùng `SESSION_CONTEXT(N'UserId')` và `SESSION_CONTEXT(N'IsSystemContext')`.
3. Trên **connection** mà request dùng cho DB: gọi `EXEC sp_SetUserContext @UserId, @IsSystemContext` (IsSystemContext = 0 cho request user). Stored procedure đã có trong DB: [12.row_level_security.sql](../script_core/sql/v2/12.row_level_security.sql).
4. Đảm bảo mọi truy vấn trong request dùng **cùng connection/scope** đã set session context (vd mở connection một lần per request, set context, rồi dùng cho toàn bộ DbContext/commands trong request).

**Lưu ý:** Session context gắn với connection; connection phải **mở** trước khi gọi `sp_SetUserContext`. Có thể gói trong scope per-request (middleware mở connection, set context, gọi next, cuối request clear context và đóng/dispose).

---

## 3. Kiến trúc gợi ý

- **BCDT.Api:** Middleware (vd `SessionContextMiddleware` hoặc dùng filter/action filter) đăng ký sau `UseAuthentication()`, trước `UseAuthorization()`.
- **Vị trí gọi sp_SetUserContext:** Trong middleware: resolve `HttpContext` → lấy User (Claims) → UserId; resolve `AppDbContext` (hoặc `IDbConnection`/scoped connection) → mở connection → `ExecuteSqlRawAsync("EXEC sp_SetUserContext @p0, 0", userId)` (hoặc Dapper/ADO). Khi request kết thúc (hoặc trong finally): gọi `sp_ClearUserContext` nếu cần.
- **EF Core:** Có thể dùng `DbContext.Database.GetDbConnection()` mở connection, set context, rồi để DbContext dùng connection đó cho request (đảm bảo single connection per request khi dùng scoped DbContext).

---

## 4. Bảng DB / stored procedure liên quan

| Thành phần | Mô tả |
|------------|--------|
| **sp_SetUserContext** | `@UserId INT, @IsSystemContext BIT = 0`. Gọi `sp_set_session_context N'UserId', @UserId` và `N'IsSystemContext', @IsSystemContext`. Đã có trong 12.row_level_security.sql. |
| **sp_ClearUserContext** | Xóa session context (UserId, IsSystemContext = NULL). Gọi khi kết thúc request hoặc on error. |
| RLS predicates | Dùng `SESSION_CONTEXT(N'UserId')` và `SESSION_CONTEXT(N'IsSystemContext')` trong 12.row_level_security.sql. |

---

## 5. Thứ tự triển khai gợi ý

1. Tạo middleware (vd `SessionContextMiddleware`) hoặc filter: đọc UserId từ `HttpContext.User` (sau auth); nếu có UserId thì mở connection từ DbContext, gọi `sp_SetUserContext`, lưu connection/scope để request dùng, khi response xong hoặc exception gọi `sp_ClearUserContext`.
2. Đăng ký middleware trong `Program.cs`: sau `UseAuthentication()`, trước `UseAuthorization()`.
3. Đảm bảo DbContext dùng đúng connection đã set context (vd mở connection trong middleware và set vào HttpContext/scope cho DbContext dùng, hoặc dùng execution strategy/custom connection mở sớm).
4. Kiểm tra: gọi một endpoint đã auth (vd `/api/v1/auth/me` hoặc endpoint đọc bảng có RLS) và xác nhận không lỗi; có thể kiểm tra trong DB (vd tạm log hoặc query SESSION_CONTEXT trong stored procedure test).

---

## 6. Kiểm tra sau khi triển khai

| Bước | Hành động | Kỳ vọng |
|------|-----------|---------|
| 1 | Build | Build succeeded. |
| 2 | Chạy API; gọi GET `/api/v1/auth/me` với Bearer token hợp lệ | 200, response có user. (Endpoint này dùng DbContext; nếu middleware set context đúng, truy vấn user sẽ chạy trong session đã set UserId.) |
| 3 | Gọi request **không** có Bearer token tới endpoint cần auth | 401. (Không set session context cho anonymous.) |
| 4 | (Tùy chọn) Trong DB hoặc log: xác nhận sp_SetUserContext được gọi khi có request auth | Không lỗi; RLS predicate dùng SESSION_CONTEXT(N'UserId') có giá trị. |

---

## 7.1. Kiểm tra cho AI (tự chạy và báo kết quả)

**AI sau khi triển khai B3 (hoặc khi được yêu cầu kiểm tra B3) nên chạy lần lượt các bước dưới đây và báo Pass/Fail.**

1. **Build**
   - Lệnh: `dotnet build src/BCDT.Api/BCDT.Api.csproj`
   - Kỳ vọng: Build succeeded. Nếu build Fail do file lock bởi BCDT.Api: tắt process BCDT.Api rồi build lại (theo rule always-verify-after-work).

2. **API đang chạy**
   - Khởi động API (vd `dotnet run --project src/BCDT.Api/BCDT.Api.csproj --launch-profile http`). Base URL: `http://localhost:5080`.

3. **Request có auth – session context được set**
   - Login: `Invoke-RestMethod -Uri "http://localhost:5080/api/v1/auth/login" -Method POST -Body '{"username":"admin","password":"Admin@123"}' -ContentType "application/json"`.
   - Me với Bearer token: GET `/api/v1/auth/me` với header `Authorization: Bearer <accessToken>`.
   - Kỳ vọng: Login 200, Me 200 và trả về user. (Me dùng DbContext; nếu middleware set UserId lên session context đúng, truy vấn không lỗi.)

4. **Request không auth**
   - Gọi GET `/api/v1/auth/me` **không** gửi header Authorization.
   - Kỳ vọng: 401 Unauthorized.

5. **Postman collection (nếu có thay đổi API)**
   - Cập nhật `docs/postman/BCDT-API.postman_collection.json` nếu B3 thêm/sửa endpoint; xác thực JSON parse (theo rule Postman collection).

**Báo kết quả:** Liệt kê từng bước (1–5) kèm **Pass** hoặc **Fail** (và lỗi nếu có). Ví dụ: "1. Build: Pass. 2. API: Pass. 3. Login + Me: Pass. 4. Me không token: 401 Pass. 5. Postman: Pass."

---

## 8. Lưu ý cho AI

- **Không** bypass RLS (không set IsSystemContext = 1 cho request user thường; chỉ background job dùng sp_SetSystemContext khi cần).
- Connection phải **mở** trước khi gọi `sp_SetUserContext`; đảm bảo mọi truy vấn trong request dùng cùng connection/scope.
- Nếu dùng EF Core: cần đảm bảo DbContext dùng connection đã set context (vd mở connection trong middleware và cấu hình DbContext dùng connection đó cho request, hoặc execution strategy mở connection sớm và set context trước khi execute).

---

**Version:** 1.0  
**Ngày:** 2026-02-04
