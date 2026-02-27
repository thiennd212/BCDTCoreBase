# Rà soát: Refresh Token – Backend có, Frontend chưa dùng

**Ngày:** 2026-02-03  
**Mục đích:** Rà soát kỹ việc chưa có refresh token trên frontend; backend đã có đầy đủ.

---

## 1. Backend – Đã có đầy đủ (B1)

| Thành phần | Trạng thái | Ghi chú |
|------------|------------|---------|
| **POST /api/v1/auth/login** | ✅ | Trả `LoginResponse`: `accessToken`, **refreshToken**, `expiresIn`, `user`. |
| **POST /api/v1/auth/refresh** | ✅ | Body `RefreshRequest { refreshToken }`; trả `RefreshResponse`: `accessToken`, `expiresIn`, `user`. Validate BCDT_RefreshToken (chưa revoke, chưa hết hạn). |
| **POST /api/v1/auth/logout** | ✅ | Body `RefreshRequest`; set `RevokedAt` cho bản ghi RefreshToken. |
| **BCDT_RefreshToken** | ✅ | Entity, DbSet, AuthService lưu/đọc/revoke. |
| **RefreshTokenExpiryDays** | ✅ | 7 ngày (AuthService). |
| **JWT ExpiryMinutes** | ✅ | Access token hết hạn theo config (vd 60 phút). |

**Kết luận backend:** Theo [B1_JWT.md](B1_JWT.md), B1 đã triển khai đủ login + refresh + logout; API trả refreshToken khi login và chấp nhận refresh khi gửi refreshToken.

---

## 2. Frontend – Chưa dùng refresh token

| Thành phần | Hiện trạng | Thiếu |
|------------|------------|--------|
| **auth.types.ts** | ✅ Có `LoginResponse.refreshToken` | — |
| **authApi.login** | Chỉ `setStoredToken(data.accessToken)` | **Không lưu** `data.refreshToken`. |
| **authApi** | Chỉ `login`, `me` | **Không có** `refresh()`. |
| **apiClient** | Lưu/clear access token; on 401 → clear + redirect /login | **Không thử** gọi `/auth/refresh` trước khi redirect. |
| **AuthContext** | State: token, user; logout chỉ clear localStorage | **Không lưu** refreshToken; **logout không gọi** POST /auth/logout (không revoke refresh token). |

**Hậu quả:**

- Access token hết hạn (vd sau 60 phút) → bất kỳ request nào (vd GET /organizations) → 401 → **redirect /login ngay**, dù refresh token còn hạn (7 ngày).
- Người dùng phải đăng nhập lại dù session backend vẫn hợp lệ.
- Logout chỉ xóa token ở FE, refresh token vẫn còn hiệu lực trên server (không thu hồi).

---

## 3. Đề xuất bổ sung Frontend

1. **Lưu refresh token:** Sau login lưu `refreshToken` (vd `localStorage` key `bcdt_refresh_token` hoặc chỉ trong memory). Cập nhật `apiClient` (get/set/clear refresh token) và `AuthContext.login` gọi `setStoredRefreshToken(data.refreshToken)`.
2. **authApi.refresh:** Thêm `refresh(): Promise<RefreshResponse>` gọi POST `/api/v1/auth/refresh` với body `{ refreshToken: getStoredRefreshToken() }`; trên success gọi `setStoredToken(data.accessToken)` (RefreshResponse có thể không trả refreshToken mới nếu backend không rotate).
3. **apiClient interceptor (401):** Trước khi clear + redirect: **thử** gọi `authApi.refresh()` (không dùng apiClient để tránh loop, hoặc dùng axios instance riêng không intercept); nếu refresh thành công → cập nhật access token, **retry** request gốc; nếu refresh thất bại hoặc không có refreshToken → clear token + redirect /login.
4. **Logout:** AuthContext.logout gọi POST `/api/v1/auth/logout` với body `{ refreshToken }` (trước khi clear), rồi clear cả access và refresh token; nếu API logout fail (vd mất mạng) vẫn clear local và redirect /login.

---

## 4. Tóm tắt

| Hạng mục | Backend | Frontend |
|----------|---------|----------|
| Refresh token | ✅ Có (login trả, /refresh, /logout revoke) | ❌ Chưa lưu, chưa gọi refresh, 401 → redirect ngay |
| Hành vi khi access token hết hạn | — | Hiện: redirect /login. Mong muốn: thử refresh → retry; không được mới redirect. |

**Công việc tiếp theo:** Bổ sung FE theo mục 3 (lưu refreshToken, authApi.refresh, interceptor 401 try-refresh-then-redirect, logout gọi API revoke).

---

## 5. Trạng thái triển khai FE (cập nhật sau rà soát)

| Thành phần | Trạng thái |
|------------|------------|
| Lưu refreshToken khi login | ✅ Đã bổ sung (authApi.login → setStoredRefreshToken) |
| authApi.refresh() | ✅ Đã bổ sung |
| apiClient interceptor 401 → refresh → retry | ✅ Đã bổ sung |
| AuthContext logout → POST /auth/logout | ✅ Đã bổ sung |
| clearStoredRefreshToken khi loadUser fail / logout | ✅ Đã bổ sung |

**Kết luận:** FE Refresh token đã triển khai đủ theo mục 3. **Báo cáo AI tự test (2026-02-05):** Bước 1 (Build FE) Pass; Bước 5 (E2E) Pass 6/6. Bước 2–4 (Local Storage, 401→refresh→retry, Logout Network) cần kiểm tra thủ công (mở app + DevTools) – xem báo cáo dưới mục 5.1.

---

## 5.1. Kiểm tra cho AI (Refresh token FE – tự chạy và báo Pass/Fail)

**AI khi được yêu cầu kiểm tra Refresh token FE chạy lần lượt và báo Pass/Fail.**

1. **Build FE**
   - Lệnh: `npm run build` trong `src/bcdt-web`
   - Kỳ vọng: Build succeeded.

2. **Login lưu refreshToken**
   - Mở app, đăng nhập (admin / Admin@123). Mở DevTools → Application → Local Storage → kiểm tra có key `bcdt_refresh_token` và có giá trị (chuỗi token).
   - Kỳ vọng: Có cả `bcdt_access_token` và `bcdt_refresh_token`.

3. **401 → refresh → retry (mô phỏng)**
   - Sau khi login, xóa access token trong Local Storage (giữ nguyên refresh token). Thao tác gây request có auth (vd chuyển trang Organizations hoặc Users). Kỳ vọng: Không redirect về /login ngay; request thành công (trang load được) vì interceptor đã gọi refresh và retry.
   - Hoặc: giảm JWT expiry xuống 1 phút, đợi hết hạn rồi thao tác – kỳ vọng tương tự.

4. **Logout gọi backend**
   - Đăng nhập, mở DevTools Network. Bấm Đăng xuất. Kỳ vọng: Có request POST `/api/v1/auth/logout` với body chứa `refreshToken` (status 200 hoặc 204). Sau đó Local Storage không còn access token và refresh token.

5. **E2E (tùy chọn)**
   - Chạy `npm run test:e2e` trong `src/bcdt-web` (backend đang chạy). Kỳ vọng: Các test hiện có vẫn Pass (login, redirect, org, user, protected, logout).

**Báo kết quả:** Liệt kê từng bước (1–5) kèm **Pass** hoặc **Fail**. Chỉ khi chạy đủ và báo Pass mới coi "AI đã tự test Refresh token FE và pass hết các case".

---

### Kết quả chạy checklist (2026-02-05)

| Bước | Nội dung | Kết quả | Ghi chú |
|------|----------|---------|--------|
| 1 | Build FE (`npm run build` trong `src/bcdt-web`) | **Pass** | Build succeeded. |
| 2 | Login lưu refreshToken (Local Storage có `bcdt_access_token`, `bcdt_refresh_token`) | **Cần kiểm tra thủ công** | Mở app → đăng nhập admin/Admin@123 → DevTools → Application → Local Storage. Code đã gọi `setStoredRefreshToken(data.refreshToken)` trong `authApi.login`. |
| 3 | 401 → refresh → retry (xóa access token, thao tác → không redirect /login, trang load được) | **Cần kiểm tra thủ công** | Xóa `bcdt_access_token` trong Local Storage, giữ `bcdt_refresh_token`, chuyển trang hoặc F5; kỳ vọng interceptor gọi refresh và retry thành công. |
| 4 | Logout gọi backend (Network có POST `/api/v1/auth/logout`, body có `refreshToken`) | **Cần kiểm tra thủ công** | Đăng nhập → DevTools Network → Đăng xuất; kiểm tra request logout. Code đã gọi `authApi.logout()` trong `AuthContext.logout`. |
| 5 | E2E (`npm run test:e2e`) | **Pass** | 6 passed (login form, login redirect, protected redirect, logout redirect, trang đơn vị, trang user). Backend cần chạy khi chạy E2E. |

**Tóm tắt:** Bước 1 và 5 **Pass** (tự động). Bước 2, 3, 4 cần người dùng mở app và DevTools để xác nhận; logic code đã triển khai đủ theo mục 3.

---

### Kết quả kiểm tra thủ công (2026-02-12)

| Bước | Nội dung | Kết quả | Ghi chú |
|------|----------|---------|--------|
| 1 | Build FE (`npm run build` trong `src/bcdt-web`) | **Pass** | Build succeeded (37.86s). |
| 2 | Login lưu refreshToken (Local Storage có `bcdt_access_token`, `bcdt_refresh_token`) | **Pass** | Login admin/Admin@123 → localStorage có cả 2 token. |
| 3 | 401 → refresh → retry | **Pass** | Inject expired token → trigger 401 → POST `/api/v1/auth/refresh` được gọi → access token được làm mới → trang load được, không redirect về /login. |
| 4 | Logout gọi backend + clear localStorage | **Pass** | Click "Đăng xuất" → POST `/api/v1/auth/logout` được gọi → localStorage bị clear (cả access và refresh token đều null). |
| 5 | E2E (`npm run test:e2e`) | **Pass** | (chạy lần trước, 6/6 passed). |

**Tóm tắt:** Tất cả 5 bước **Pass**. Tính năng Refresh token trên frontend đã triển khai đủ và hoạt động đúng.
