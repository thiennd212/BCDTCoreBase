# Báo cáo Review nghiệp vụ – Module Auth (B1–B3)

**Ngày:** 2026-02-24  
**Agent:** bcdt-business-reviewer  
**Phạm vi:** JWT (B1), RBAC (B2), RLS & Session Context (B3).

---

## 1. Phạm vi review

- **Yêu cầu nguồn:** 01.YEU_CAU_HE_THONG (ORG-02, ORG-03, ORG-04; NFR-SEC-01, NFR-SEC-02, NFR-SEC-03; Khía cạnh 23–25), YEU_CAU_HE_THONG_TONG_HOP, B1_JWT.md, B2_RBAC.md, B3_RLS.md.
- **Implementation:** AuthController, AuthService, IJwtService, SessionContextMiddleware, 12.row_level_security.sql (sp_SetUserContext, sp_ClearUserContext, fn_SecurityPredicate_Organization, SecurityPolicy), BCDT_User, BCDT_RefreshToken, BCDT_UserRole, BCDT_Role.

---

## 2. Bảng đối chiếu (Yêu cầu ↔ Implementation)

| # | Yêu cầu | Nguồn | Implementation | Trạng thái |
|---|---------|-------|-----------------|------------|
| 1 | Đăng nhập (username + password), trả access_token, refresh_token, user info | B1_JWT | POST /api/v1/auth/login, AuthService.LoginAsync, BCrypt verify, BCDT_RefreshToken lưu token, LoginResponse (AccessToken, RefreshToken, ExpiresIn, User) | **Đạt** |
| 2 | Refresh token → access_token mới | B1_JWT | POST /api/v1/auth/refresh, AuthService.RefreshAsync, kiểm tra RevokedAt/ExpiresAt, trả RefreshResponse | **Đạt** |
| 3 | Logout thu hồi refresh_token | B1_JWT | POST /api/v1/auth/logout, AuthService.LogoutAsync, set RevokedAt + RevokedByIp | **Đạt** |
| 4 | JWT có claim UserId, Username | B1_JWT | IJwtService.GenerateAccessToken(userId, username, roleCodes); SessionContextMiddleware đọc ClaimTypes.NameIdentifier | **Đạt** |
| 5 | 5 vai trò (SYSTEM_ADMIN, FORM_ADMIN, UNIT_ADMIN, DATA_ENTRY, VIEWER) | 01 (ORG-03), B2_RBAC | BCDT_Role, seed 14; GetUserRoleCodesAsync từ BCDT_UserRole + BCDT_Role | **Đạt** |
| 6 | Role trong JWT (login/refresh) | B2_RBAC | AuthService Login/Refresh gọi GetUserRoleCodesAsync, truyền vào GenerateAccessToken | **Đạt** |
| 7 | [Authorize], [Authorize(Roles = "...")], 403 khi thiếu quyền | B2_RBAC | AuthController: Me, MeRoles, ChangePassword [Authorize]; nhiều controller khác [Authorize] hoặc policy; 401/403 chuẩn | **Đạt** |
| 8 | Policy theo permission (tùy chọn) | B2_RBAC | FormStructureAdmin policy có trong codebase; Permission-based có thể dùng Requirement/Handler | **Một phần** (policy theo role đủ MVP) |
| 9 | RLS: SESSION_CONTEXT('UserId'), IsSystemContext | B3_RLS, 12.row_level_security.sql | fn_SecurityPredicate_Organization dùng SESSION_CONTEXT(N'UserId'), (N'IsSystemContext'); SecurityPolicy_ReportSubmission, SecurityPolicy_ReferenceEntity | **Đạt** |
| 10 | Middleware set UserId lên session context trước truy vấn | B3_RLS | SessionContextMiddleware sau UseAuthentication; mở connection, EXEC sp_SetUserContext @UserId, 0; finally sp_ClearUserContext | **Đạt** |
| 11 | Me (user hiện tại từ JWT) | B1_JWT | GET /api/v1/auth/me [Authorize], GetUserInfoAsync(userId) | **Đạt** |
| 12 | Me/roles (danh sách vai trò để chuyển vai trò FE) | Post-MVP | GET /api/v1/auth/me/roles, UserRoleItemDto (organizationId, organizationName) | **Đạt** |
| 13 | NFR-SEC-01 Authentication (JWT + extensible) | 01 (NFR-SEC-01) | JWT đầy đủ; SSO/LDAP/2FA = Later (Khía cạnh 26) | **Đạt** (MVP) |
| 14 | NFR-SEC-02 Authorization (RBAC + Policy) | 01 (NFR-SEC-02) | RBAC qua Role trong JWT + [Authorize(Roles)]; policy FormStructureAdmin | **Đạt** |
| 15 | NFR-SEC-03 Data isolation (RLS) | 01 (NFR-SEC-03) | RLS bật, predicate Organization + DataScope All | **Đạt** |

---

## 3. Gap

| Mức độ | Mô tả |
|--------|--------|
| **Minor** | Policy theo **Permission** (B2 tùy chọn): hiện chủ yếu [Authorize(Roles = "...")]; kiểm tra quyền chi tiết (vd Form.View, Submission.Submit) từ BCDT_RolePermission chưa thống nhất trên mọi endpoint. Menu đã lọc theo RequiredPermission + RolePermission (Post-MVP). |
| **Minor** | Refresh token **rotation**: B2/B1 không bắt buộc rotate refresh token sau mỗi lần refresh; hiện RefreshAsync trả access_token mới nhưng giữ nguyên refresh_token. Tài liệu B1 cho phép "nếu rotate: revoke cũ, tạo mới" – tùy chọn. |

Không có gap **Critical** hoặc **Major** đối với phạm vi B1–B3 và NFR-SEC-01/02/03 trong MVP.

---

## 4. Mâu thuẫn / Rủi ro

- **Không phát hiện mâu thuẫn** giữa tài liệu B1/B2/B3 và code (endpoint, luồng, bảng DB, RLS).
- **Rủi ro nhỏ:** Connection mở trong SessionContextMiddleware dùng chung DbContext; nếu request dùng thêm Dapper/connection riêng cần đảm bảo cùng connection đã set context hoặc gọi sp_SetUserContext trên connection đó. Hiện EF Core dùng chung connection → ổn.

---

## 5. Khuyến nghị

| Ưu tiên | Khuyến nghị |
|---------|--------------|
| **P2** | (Tùy chọn) Chuẩn hóa policy theo Permission cho các endpoint nhạy cảm (vd Form config, Submission submit) dùng IAuthorizationHandler + PermissionRequirement, đồng bộ với Menu (RequiredPermission). |
| **P2** | (Tùy chọn) Refresh token rotation: khi RefreshAsync tạo refresh_token mới, revoke token cũ (RevokedAt, ReplacedByToken), trả refresh_token mới trong response để FE cập nhật. |
| **P3** | Giữ nguyên checklist "Kiểm tra cho AI" trong B1_JWT, B2_RBAC, B3_RLS; khi sửa Auth tiếp tục chạy đủ bước và báo Pass/Fail. |

**Kết luận:** Module Auth (B1–B3) **đạt đủ yêu cầu MVP** theo 01.YEU_CAU_HE_THONG và file đề xuất B1/B2/B3. Gap chỉ ở mức Minor (policy theo permission chi tiết, refresh rotation); không ảnh hưởng nghiệm thu Phase 1.
