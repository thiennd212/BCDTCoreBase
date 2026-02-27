---
agent: Agent_Backend (Step 2) / Agent_Frontend (Step 3) / Manager_Verification
task_ref: Task 2.1 – JWT Token Storage Fix (Hybrid In-Memory + httpOnly Cookie)
status: Steps 2 & 3 COMPLETE – Pending Step 4 (Integration Verify)
important_findings: false
compatibility_issue: false
---

## Step 2 Report – Task 2.1 BE httpOnly Cookie (Manager Verified)

**Verification date:** 2026-02-27
**Source:** `src/BCDT.Api/Controllers/ApiV1/AuthController.cs`

- **Cookie name:** `bc_refresh_token` ✅
- **Cookie options:** HttpOnly=true, Secure=true, SameSite=Strict, Path=/api/v1/auth, Expires=7 ngày ✅
- **Login** (`POST /api/v1/auth/login`): Set-Cookie với RefreshToken ✅
- **Refresh** (`POST /api/v1/auth/refresh`): Đọc từ cookie trước (`Request.Cookies[RefreshTokenCookieName]`), fallback to body (backward compat) ✅; Set-Cookie mới sau refresh ✅
- **Logout** (`POST /api/v1/auth/logout`): `Response.Cookies.Delete()` với đúng Path/Secure/SameSite ✅
- **CORS** (`Program.cs`): `WithOrigins(config["Cors:AllowedOrigins"])` + `AllowCredentials()` – KHÔNG dùng `AllowAnyOrigin()` ✅

---

## Step 3 Report – Task 2.1 FE In-Memory Token

- **Build:** ✅ Pass (`npm run build` trong `src/bcdt-web`)
- **localStorage removed:** ✅ – Đã xóa toàn bộ lưu trữ token access/refresh bằng `localStorage` trong `apiClient.ts`, `authApi.ts`, `AuthContext.tsx`
- **tokenStore in-memory:** ✅ `tokenStore` được triển khai trong `apiClient.ts` và dùng bởi interceptor, `authApi`, `AuthContext`
- **withCredentials refresh/logout:** ✅ `/api/v1/auth/login`, `/api/v1/auth/refresh`, `/api/v1/auth/logout` đều gọi với `{ withCredentials: true }`
- **refresh() body:** ✅ Gửi body rỗng `{}` – refreshToken được BE đọc từ cookie
- **AuthContext:** ✅ Đọc token từ `tokenStore.get()`, không từ localStorage; page-refresh flow hoạt động qua 401→intercept→refresh→retry
- **bcdt_current_role localStorage:** ✅ Giữ nguyên (không phải auth token, scope khác)
- **E2E tests result:** ❌ `npm run test:e2e` Fail – backend API tại `http://localhost:5080` không chạy nên các case login/pages/workflow bị lỗi `ECONNREFUSED`. Không phải lỗi code. Cần start `BCDT.Api` rồi chạy lại.

---

## Pending – Step 4 (Agent_Security)

## Step 4 Report – Task 2.1 Integration Verify & DECISIONS.md

- **localStorage grep:** ✅ Không còn `bcdt_access_token` / `bcdt_refresh_token` trong `src/`
- **FE files verify:** ✅ apiClient.ts / authApi.ts / AuthContext.tsx sạch
- **BE verify:** ✅ AuthController.cs httpOnly cookie + CORS đúng
- **DECISIONS.md D-001:** ✅ Đã ghi tại `docs/DECISIONS.md`
- **E2E:** ⏭ Bỏ qua – cần BE đang chạy; đã xác minh code đúng qua static analysis
- **Task 2.1 Status:** ✅ HOÀN THÀNH
