# Báo cáo Review nghiệp vụ – Module Organization & User (B4–B5)

**Ngày:** 2026-02-24  
**Agent:** bcdt-business-reviewer  
**Phạm vi:** Organization CRUD, cây 5 cấp (B4); User CRUD, gán vai trò–đơn vị (B5).

---

## 1. Phạm vi review

- **Yêu cầu nguồn:** 01.YEU_CAU_HE_THONG (ORG-01 đến ORG-06), YEU_CAU_HE_THONG_TONG_HOP, B4_ORGANIZATION.md, B5_USER_MANAGEMENT.md.
- **Implementation:** OrganizationsController, OrganizationTypesController, UsersController; IOrganizationService, IUserService; BCDT_Organization, BCDT_OrganizationType, BCDT_User, BCDT_UserRole, BCDT_UserOrganization; FE OrganizationsPage, OrganizationTypesPage, UsersPage; auth/me/roles (chuyển vai trò).

---

## 2. Bảng đối chiếu (Yêu cầu ↔ Implementation)

| # | Yêu cầu | Nguồn | Implementation | Trạng thái |
|---|---------|-------|----------------|------------|
| 1 | 5 cấp tổ chức (Bộ → Tỉnh → Cấp 3 → Cấp 4 → Cấp 5) | ORG-01, B4 | BCDT_Organization (ParentId, TreePath, Level); BCDT_OrganizationType (Level 1–5, ParentTypeId); API filter parentId, organizationTypeId; list hỗ trợ all=true (flat) | **Đạt** |
| 2 | CRUD đơn vị (list, get by id, POST, PUT, DELETE soft) | B4 | GET /api/v1/organizations (parentId, organizationTypeId, includeInactive, all), GET /{id}, POST, PUT, DELETE; policy AdminManageOrg | **Đạt** |
| 3 | Phân quyền theo đơn vị (user chỉ thấy data đơn vị mình) | ORG-02 | RLS (fn_SecurityPredicate_Organization, SessionContext UserId); B3 middleware set context; API list theo session | **Đạt** (thuộc Auth/RLS) |
| 4 | 5 vai trò (SystemAdmin, FormAdmin, UnitAdmin, DataEntry, Viewer) | ORG-03 | BCDT_Role, seed; JWT roles; policy AdminManageOrg, AdminManageUsers | **Đạt** (thuộc Auth B2) |
| 5 | Row-Level Security cách ly dữ liệu đơn vị | ORG-04 | 12.row_level_security.sql; SecurityPolicy_ReportSubmission, SecurityPolicy_ReferenceEntity; sp_SetUserContext | **Đạt** (thuộc B3) |
| 6 | Ủy quyền tạm thời (Delegation) | ORG-05 | BCDT_UserDelegation có trong schema (02.authorization); chưa có API/UI ủy quyền tạm thời | **Chưa** (gap Minor) |
| 7 | Multi-org user (1 user thuộc nhiều đơn vị) | ORG-06 | BCDT_UserOrganization; UserRole có OrganizationId; CreateUserRequest/UpdateUserRequest RoleOrgAssignments (cặp vai trò–đơn vị); UserDto.RoleOrgAssignments; auth/me/roles trả (roleId, organizationId, organizationName) | **Đạt** |
| 8 | API organization-types CRUD | B4 (cây 5 cấp) | OrganizationTypesController: GET list, GET {id}, POST, PUT, DELETE; FormStructureAdmin / AdminManageOrg | **Đạt** |
| 9 | FE tree đơn vị + bảng + Modal CRUD | B4, TONG_HOP 4 | OrganizationsPage (tree trái + bảng phải, Modal CRUD); organizationsApi (all=true); treeUtils buildTree | **Đạt** |
| 10 | API users CRUD + gán role/org | B5 | GET /api/v1/users (organizationId, includeInactive), GET {id}, POST, PUT, DELETE; CreateUserRequest/UpdateUserRequest RoleIds, OrganizationIds, RoleOrgAssignments; sync UserRole, UserOrganization | **Đạt** |
| 11 | FE Users: bảng, Modal CRUD, form Vai trò + Đơn vị | B5, TONG_HOP 4 | UsersPage (table, Modal CRUD); form bảng (Vai trò + Đơn vị); usersApi | **Đạt** |
| 12 | Chuyển vai trò (dropdown → modal → redirect /dashboard) | Post-MVP, TONG_HOP 4 | auth/me/roles; FE chuyển vai trò hiển thị "Vai trò (Đơn vị)", lưu context + localStorage, redirect /dashboard | **Đạt** |

---

## 3. Gap

| Mức độ | Mô tả |
|--------|--------|
| **Minor** | **ORG-05 Delegation (Ủy quyền tạm thời):** Bảng BCDT_UserDelegation đã có trong schema (02.authorization.sql) nhưng chưa có API (tạo/hủy ủy quyền, FromUserId/ToUserId, ValidFrom/ValidTo) và chưa có UI. Yêu cầu nghiệp vụ 01 có ORG-05; có thể xếp Post-MVP nếu MVP không bắt buộc ủy quyền. |

Không có gap **Critical** hoặc **Major** đối với B4, B5 và ORG-01/02/03/04/06 trong MVP.

---

## 4. Mâu thuẫn / Rủi ro

- **Không phát hiện mâu thuẫn** giữa tài liệu B4/B5 và code (endpoint, DTO, bảng DB, FE).
- **Rủi ro nhỏ:** Policy AdminManageOrg, AdminManageUsers – cần đảm bảo chỉ role phù hợp (vd SYSTEM_ADMIN, FORM_ADMIN, UNIT_ADMIN) được gán; đã có trong seed và B2.

---

## 5. Khuyến nghị

| Ưu tiên | Khuyến nghị |
|---------|-------------|
| **P2** | (Tùy chọn) Triển khai ORG-05 Delegation: API POST/GET/DELETE ủy quyền (UserDelegation), middleware hoặc logic “act as” khi có delegation hợp lệ; FE màn quản lý ủy quyền. Có thể tạo file đề xuất de_xuat_trien_khai/B5_DELEGATION.md khi làm. |
| **P3** | Giữ checklist "Kiểm tra cho AI" trong B4_ORGANIZATION.md, B5_USER_MANAGEMENT.md; khi sửa Org/User tiếp tục chạy đủ bước và báo Pass/Fail. |

**Kết luận:** Module Organization & User (B4–B5) **đạt đủ yêu cầu MVP** cho ORG-01, ORG-02, ORG-03, ORG-04, ORG-06 và đặc tả B4/B5. Gap duy nhất ở mức Minor (ORG-05 Delegation chưa triển khai); không ảnh hưởng nghiệm thu Phase 1.
