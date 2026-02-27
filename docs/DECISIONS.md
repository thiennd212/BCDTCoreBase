## D-001 – JWT Token Storage: Hybrid In-Memory + httpOnly Cookie

**Ngày quyết định:** 2026-02-27
**Người quyết định:** Manager Agent (Sprint 1 Security Review)
**Trạng thái:** Implemented ✅

### Bối cảnh
Access token và refresh token ban đầu lưu bằng `localStorage` – dễ bị XSS đọc trộm.

### Quyết định
Áp dụng Option A – Hybrid:
- **Access token:** Lưu in-memory (`tokenStore` module-level variable trong `apiClient.ts`). Mất khi F5 nhưng tự refresh qua cookie.
- **Refresh token:** Lưu trong httpOnly cookie `bc_refresh_token` (HttpOnly, Secure, SameSite=Strict, Path=/api/v1/auth). Server set/delete qua `Response.Cookies`.

### Lý do chọn Option A thay vì Option B (full cookie)
- Option B (cả access token trong cookie) yêu cầu thay đổi lớn hơn ở middleware và CORS preflight.
- Option A đủ bảo mật: access token chỉ sống trong RAM tab hiện tại, không bị XSS đọc qua localStorage.

### Trade-offs
- F5 → access token mất → 1 lần refresh tự động (transparent với user).
- Multiple tabs: mỗi tab có access token riêng trong memory, dùng chung refresh cookie.

### Files thay đổi
- `src/BCDT.Api/Controllers/ApiV1/AuthController.cs` – BE cookie logic
- `src/bcdt-web/src/api/apiClient.ts` – tokenStore + interceptor
- `src/bcdt-web/src/api/authApi.ts` – withCredentials
- `src/bcdt-web/src/context/AuthContext.tsx` – đọc từ tokenStore
