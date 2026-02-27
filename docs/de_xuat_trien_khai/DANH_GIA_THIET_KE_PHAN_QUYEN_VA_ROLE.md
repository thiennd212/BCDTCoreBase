# Đánh giá thiết kế phân quyền – Vai trò, quyền, phân quyền theo đơn vị

**Mục đích:** Đối chiếu yêu cầu “một người dùng có thể có 1 hoặc nhiều vai trò trong 1 hoặc nhiều đơn vị, ở mỗi vai trò khác nhau (cùng hoặc khác đơn vị) có thể được phân quyền khác nhau” với thiết kế hiện tại (DB, BE, FE).

**Tham chiếu:** B2_RBAC.md, B5_USER_MANAGEMENT.md, 02.authorization.sql, 03.DATABASE_SCHEMA.md, TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md.

---

## 1. Yêu cầu tóm tắt

| Yêu cầu | Mô tả |
|--------|--------|
| Nhiều vai trò / user | Một user có thể có nhiều vai trò (SYSTEM_ADMIN, FORM_ADMIN, UNIT_ADMIN, DATA_ENTRY, VIEWER). |
| Nhiều đơn vị / user | Một user có thể thuộc nhiều đơn vị (UserOrganization). |
| Vai trò theo đơn vị | Cùng user: vai trò A tại đơn vị X, vai trò B tại đơn vị Y (hoặc vai trò C “toàn hệ thống” không gắn đơn vị). |
| Phân quyền khác nhau theo vai trò | Mỗi vai trò có thể có bộ quyền (Permission) khác nhau; có thể mở rộng phạm vi dữ liệu (DataScope) theo vai trò. |
| Quản lý vai trò/quyền | CRUD vai trò, gán quyền cho vai trò, gán vai trò (theo đơn vị) cho user. |

---

## 2. Thiết kế hiện tại

### 2.1 Cơ sở dữ liệu (schema SQL)

| Bảng | Trạng thái | Ghi chú |
|------|------------|--------|
| **BCDT_Role** | ✅ Có | Code, Name, Level, IsSystem, IsActive. Seed 5 role. |
| **BCDT_UserRole** | ✅ Có | UserId, RoleId, **OrganizationId (NULL = toàn hệ thống)**, ValidFrom, ValidTo, IsActive, GrantedBy, GrantedAt, Revoked*. |
| **BCDT_UserOrganization** | ✅ Có | UserId, OrganizationId, IsPrimary, JoinedAt, LeftAt. User thuộc 1 hoặc nhiều đơn vị. |
| **BCDT_Permission** | ✅ Có (script) | Code, Name, Module, Action. **Chưa có entity C# / DbSet.** |
| **BCDT_RolePermission** | ✅ Có (script) | RoleId, PermissionId. **Chưa có entity C# / DbSet.** |
| **BCDT_Menu** | ✅ Có (script) | Menu phân cấp. **Chưa có entity C# / DbSet.** |
| **BCDT_RoleMenu** | ✅ Có (script) | RoleId, MenuId. **Chưa có entity C# / DbSet.** |
| **BCDT_DataScope** | ✅ Có (script) | Phạm vi dữ liệu (Self, Unit, Branch, All). **Chưa có entity C# / DbSet.** |
| **BCDT_RoleDataScope** | ✅ Có (script) | RoleId, DataScopeId. **Chưa có entity C# / DbSet.** |
| **BCDT_UserDelegation** | ✅ Có (script) | Ủy quyền tạm thời. **Chưa có entity C# / DbSet.** |

**Kết luận DB:** Schema đã hỗ trợ “vai trò theo đơn vị” (UserRole.OrganizationId) và đủ bảng cho Permission, RolePermission, Menu, DataScope (theo script). Ứng dụng chưa map đủ bảng này vào EF.

### 2.2 Backend (C#, EF, API)

| Thành phần | Trạng thái | Chi tiết |
|------------|------------|----------|
| **Entity Role, UserRole** | ✅ Có | Domain + DbContext. UserRole có OrganizationId. |
| **Entity Permission, RolePermission, Menu, DataScope, …** | ❌ Chưa | TONG_HOP ghi nhận Post-MVP. |
| **AuthService – lấy role** | ⚠️ Một phần | GetUserRoleCodesAsync lấy **tất cả** Role.Code của user (UserRole join Role), **không** lọc theo OrganizationId. JWT chỉ nhận danh sách role code, **không** có ngữ cảnh đơn vị. |
| **UserService – gán UserRole** | ⚠️ Chưa dùng đơn vị | Create/Update user: gán RoleIds và OrganizationIds **tách rời**. Khi tạo UserRole luôn set **OrganizationId = null** (role “toàn hệ thống”), không hỗ trợ “role tại đơn vị X”. |
| **DTO User / CreateUser / UpdateUser** | ⚠️ Đơn giản | RoleIds, OrganizationIds, PrimaryOrganizationId. Không có cấu trúc “danh sách (RoleId, OrganizationId?)” cho từng cặp role–đơn vị. |
| **Authorization** | ⚠️ Chỉ role-based | Một policy: FormStructureAdmin = RequireRole(SYSTEM_ADMIN, FORM_ADMIN). Không có policy theo Permission hay DataScope. |
| **API quản lý** | ❌ Thiếu | Không có RolesController, PermissionsController, RolePermissionController. Không có API CRUD vai trò, gán quyền cho vai trò. |

**Kết luận BE:** Logic và API hiện tại **chưa** dùng OrganizationId trong UserRole; user có nhiều role và nhiều đơn vị nhưng “vai trò theo từng đơn vị” chưa được lưu hay dùng khi authorize. Phân quyền chi tiết (Permission, DataScope) chưa có trong code.

### 2.3 Frontend

| Thành phần | Trạng thái |
|------------|------------|
| **Trang Users** | ✅ Có | Gán RoleIds, OrganizationIds khi tạo/sửa user. Không có giao “role tại đơn vị X/Y”. |
| **Trang quản lý Vai trò (Role)** | ❌ Không có | Không có màn CRUD vai trò. |
| **Trang quản lý Quyền (Permission)** | ❌ Không có | Không có màn quyền, gán quyền cho vai trò. |
| **Trang phân quyền (Role–Org cho User)** | ❌ Không có | Không có màn “user X: tại đơn vị A vai trò R1, tại đơn vị B vai trò R2”. |

---

## 3. Khoảng trống so với yêu cầu

| Yêu cầu | Hiện trạng | Gap |
|--------|------------|-----|
| 1 user – nhiều vai trò | ✅ UserRole nhiều dòng, JWT có nhiều role | Đạt. |
| 1 user – nhiều đơn vị | ✅ UserOrganization nhiều dòng | Đạt. |
| Vai trò theo đơn vị | Schema có UserRole.OrganizationId | BE luôn ghi OrganizationId = null; JWT không có ngữ cảnh đơn vị; FE không có UI gán “role tại đơn vị”. |
| Phân quyền khác nhau theo vai trò | DB có Permission, RolePermission | Chưa có entity/API/FE; authorization chỉ dựa trên role code. |
| Phạm vi dữ liệu theo vai trò (DataScope) | DB có DataScope, RoleDataScope | Chưa có trong code; RLS/session có thể mở rộng sau. |
| Quản lý vai trò (CRUD Role) | Chỉ seed, không API | Thiếu API + FE quản lý vai trò. |
| Quản lý quyền (Permission, gán cho Role) | Chỉ script SQL | Thiếu entity, API, FE. |
| Gán (Role, Organization) cho User | Chỉ gán “danh sách role” + “danh sách đơn vị” tách nhau | Thiếu mô hình “từng cặp (RoleId, OrganizationId?)” và UI tương ứng. |

---

## 4. Đánh giá tóm tắt

- **Điểm mạnh**
  - Schema DB đã có UserRole.OrganizationId, Permission, RolePermission, Menu, DataScope, RoleDataScope (theo script).
  - User đã có nhiều role (JWT) và nhiều đơn vị (UserOrganization).
  - Đã có policy theo role (FormStructureAdmin) và [Authorize].

- **Điểm thiếu so với yêu cầu**
  1. **Vai trò theo đơn vị:** Ứng dụng chưa dùng UserRole.OrganizationId (luôn null), chưa có JWT/context “đơn vị hiện tại + vai trò trong đơn vị đó”, chưa có FE để gán “role tại đơn vị”.
  2. **Quyền chi tiết (Permission):** Bảng có trong DB nhưng chưa có entity, service, API, FE; authorization chưa kiểm tra theo Permission.
  3. **Quản lý vai trò/quyền:** Thiếu CRUD vai trò, thiếu gán quyền cho vai trò, thiếu màn phân quyền (role–org cho user).

---

## 5. Đề xuất hướng mở rộng (thứ tự ưu tiên)

| Bước | Nội dung | Mức độ |
|------|----------|--------|
| 1 | **Dùng UserRole.OrganizationId:** DTO/API User cho phép gửi danh sách (RoleId, OrganizationId?). UserService ghi OrganizationId vào UserRole; AuthService/JWT có thể (tùy chọn) đưa “role trong đơn vị” vào claim hoặc session (vd. OrganizationId hiện tại + roles trong org đó). | Cần cho “phân quyền theo đơn vị”. |
| 2 | **API + FE quản lý vai trò (Role):** CRUD Role (ít nhất Code, Name, IsActive); FE trang “Vai trò”. | Cơ bản cho vận hành. |
| 3 | **Entity + API Permission, RolePermission:** Map bảng BCDT_Permission, BCDT_RolePermission; API đọc quyền theo role; (tùy chọn) policy kiểm tra Permission. | Phân quyền chi tiết. |
| 4 | **FE phân quyền user:** Form user cho phép gán từng cặp (Role, Đơn vị) thay vì hai danh sách tách rời. | UX đúng yêu cầu. |
| 5 | **DataScope / RLS:** Dùng BCDT_DataScope, BCDT_RoleDataScope cho phạm vi dữ liệu (self/unit/branch/all); tích hợp session/RLS. | Mở rộng sau. |

---

## 6. Kết luận

- **Thiết kế DB:** Phù hợp với yêu cầu “vai trò trong 1 hoặc nhiều đơn vị” và “phân quyền theo vai trò” (Permission, RolePermission, DataScope đã có trong script).
- **Thiết kế BE/FE hiện tại:** Chưa đủ cho yêu cầu đó: chưa dùng vai trò theo đơn vị (OrganizationId trong UserRole), chưa có quản lý vai trò/quyền và chưa có phân quyền chi tiết (Permission). Cần bổ sung theo các bước ở mục 5 để đáp ứng đầy đủ “một người dùng có thể có 1 hoặc nhiều vai trò trong 1 hoặc nhiều đơn vị, ở mỗi vai trò khác nhau trong cùng hoặc khác đơn vị sẽ có thể được phân quyền khác nhau”.

---

**Version:** 1.0  
**Ngày:** 2026-02-11
