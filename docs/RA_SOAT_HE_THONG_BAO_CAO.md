# Báo cáo rà soát hệ thống BCDT

**Ngày rà soát:** 2026-02-12  
**Phương pháp:** Rà soát đa nhóm (Backend, Frontend, Bảo mật, API, DB)

---

## 1. Tổng quan

| Nhóm rà soát | Phạm vi | Kết luận nhanh |
|--------------|---------|----------------|
| Backend – Auth & API | Controllers, Program.cs | JWT + policy FormStructureAdmin; AuthController AllowAnonymous đúng |
| Backend – Exception | API, Services | Result pattern; ít throw trực tiếp |
| Bảo mật – SQL | Infrastructure | DataSourceQueryService dùng parameterized; whitelist cột |
| Frontend – Lỗi API | apiClient, pages | Có getApiErrorMessage, 401/403/404 xử lý trong interceptor |
| API – Authorization | Controllers | Toàn bộ API (trừ Auth) có [Authorize] |

---

## 2. Chi tiết theo nhóm

### 2.1 Backend – Authentication & Authorization

**Đã có:**
- JWT với ValidateIssuer, ValidateAudience, ValidateLifetime, ClockSkew = 0
- OnTokenValidated: kiểm tra LastLogoutAt để revoke token sau khi logout
- Policy `FormStructureAdmin` cho các endpoint nhạy cảm (Permissions CRUD, Menus CRUD)
- AuthController: Login, Refresh, Logout có [AllowAnonymous]; Me có [Authorize]
- Các controller còn lại đều [Authorize] ở class level

**Vấn đề / Cần rà thêm:**
- Một số controller có thể thiếu policy theo role (chỉ [Authorize] chung)
- GetUserId() dùng `int.Parse(..., "0")` – nếu claim null trả 0, có thể gây lỗi logic ở service

**Đề xuất:** Rà từng nhóm API (User, Role, Form, Submission…) để gán policy tương ứng (vd: User.ManageUsers, Form.Edit).

---

### 2.2 Backend – Xử lý lỗi & Exception

**Đã có:**
- Result&lt;T&gt; pattern: service trả Result, controller map sang ApiErrorResponse + HTTP status (400, 404, 409)
- DataSourceQueryService: try/catch trả Result.Fail("QUERY_FAILED", ex.Message)
- ConnectionString thiếu thì throw InvalidOperationException lúc startup (hợp lý)

**Vấn đề:**
- Không thấy global exception middleware – nếu service/controller throw ngoài Result thì có thể trả 500 với stack trace (cần kiểm tra môi trường Production có ẩn chi tiết không)

**Đề xuất:** Thêm ExceptionMiddleware để bắt mọi exception, log và trả ApiErrorResponse thống nhất, không lộ stack trace ra client.

---

### 2.3 Bảo mật – SQL & Input

**Đã có:**
- DataSourceQueryService: table/view name validate regex `^[a-zA-Z0-9_]+$`, cột whitelist từ GetColumnsAsync, điều kiện WHERE dùng SqlParameter (parameterized)
- DataSourceService.GetColumnsAsync: dùng SqlQueryRaw với table name từ EF (parameterized)

**Vấn đề:**
- Không phát hiện raw SQL nối chuỗi trực tiếp từ user input

**Đề xuất:** Giữ quy ước: mọi truy vấn động phải qua whitelist + parameterized; code review khi thêm DataSource/SQL mới.

---

### 2.4 Frontend – Xử lý lỗi API

**Đã có:**
- getApiErrorMessage: ưu tiên errors[0].message từ backend, fallback 403/404/409/500/ERR_NETWORK
- getApiErrorStatus, getApiErrorCode, isApiNotFound, isApiConflict
- Interceptor: 401 → refresh token hoặc redirect login; lưu token vào localStorage
- Các page: onError dùng getApiErrorMessage + message.error()

**Vấn đề:**
- Sau khi refresh token fail, redirect login – cần xác nhận có clear token + state (user) để không lưu session cũ
- Một số trang có thể chưa disable nút submit khi đang gửi (loading) – rà từng trang nếu cần

**Đề xuất:** Kiểm tra AuthContext khi 401 (clear user, token) và kiểm tra các form có confirmLoading/loading gắn với mutation.

---

### 2.5 API – Nhất quán response & status code

**Đã có:**
- ApiSuccessResponse&lt;T&gt;, ApiErrorResponse (code, message)
- Controller trả 200/201/204/400/404/409 và BadRequest( ApiErrorResponse ) thống nhất

**Vấn đề:**
- Một số chỗ có thể trả BadRequest cho NOT_FOUND thay vì NotFound – đã từng được nêu trong rà soát trước; nên thống nhất NOT_FOUND → 404, CONFLICT → 409

---

### 2.6 Tính năng / Gap (từ rà soát nhanh)

| Mục | Trạng thái |
|-----|------------|
| Đổi mật khẩu (Profile) | Frontend có form, backend chưa có API (TODO trong ProfilePage) |
| Cài đặt user (Settings) | Chỉ UI, chưa lưu backend |
| Sidebar menu từ DB | Đã gọi /api/v1/menus; nếu trống cần kiểm tra dữ liệu BCDT_Menu |
| Role/Permission theo endpoint | Đa số API chỉ [Authorize], chưa gắn policy theo permission |

---

## 3. Đề xuất ưu tiên

1. ~~**Cao:** Thêm global ExceptionMiddleware (log + trả lỗi chuẩn, ẩn stack trace ở Production).~~ **✅ Đã làm:** `ExceptionMiddleware.cs`, đăng ký đầu pipeline.
2. ~~**Cao:** API đổi mật khẩu (backend) + ghép form Profile.~~ **✅ Đã làm:** `POST /api/v1/auth/change-password`, `authApi.changePassword`, ProfilePage gọi API.
3. ~~**Trung bình:** Rà và gán policy (theo permission) cho từng nhóm API.~~ **✅ Đã làm:** Policy `AdminManageUsers`, `AdminManageRoles`, `AdminManageOrg`; gán UsersController, RolesController, OrganizationsController, OrganizationTypesController.
4. ~~**Trung bình:** Thống nhất HTTP status (NOT_FOUND → 404, CONFLICT → 409) cho toàn bộ controller.~~ **✅ Đã làm:** GetById trong Users, Roles, Organizations, OrganizationTypes, ReportingFrequencies, Menus, Submissions trả NotFound khi `result.Code == ApiErrorCodes.NotFound`.
5. **Thấp:** Lưu cài đặt user (Settings) nếu có yêu cầu (backend + persistence).

---

## 4. Cách dùng báo cáo này

- Dùng làm checklist cho sprint: ưu tiên mục 3.1, 3.2 rồi 3.3–3.5.
- Cập nhật báo cáo sau mỗi đợt rà soát hoặc sau khi xử lý xong từng mục.
- Khi thêm API/SQL mới: kiểm tra lại mục 2.1 (auth/policy), 2.3 (SQL), 2.5 (status code).
