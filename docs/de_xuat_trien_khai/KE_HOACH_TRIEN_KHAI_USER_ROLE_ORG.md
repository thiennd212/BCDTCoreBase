# Kế hoạch triển khai User–Role–Org phân quyền chức năng

**Mục đích:** Triển khai theo tài liệu [CACH_XU_LY_USER_ROLE_ORG_PHAN_QUYEN_CHUC_NANG.md](CACH_XU_LY_USER_ROLE_ORG_PHAN_QUYEN_CHUC_NANG.md) theo từng phase, **không làm ảnh hưởng** đến hành vi hiện tại (client cũ, user đã có role toàn hệ thống).

**Tham chiếu:** DANH_GIA_THIET_KE_PHAN_QUYEN_VA_ROLE.md, B2_RBAC.md, B5_USER_MANAGEMENT.md.

---

## 1. Rà soát hiện trạng

### 1.1. Đã có (giữ nguyên / tận dụng)

| Thành phần | Hiện trạng |
|------------|------------|
| **BCDT_UserRole** | Có cột `OrganizationId` (NULL). Entity C# có sẵn. |
| **BCDT_UserOrganization** | User–Org đã dùng; RLS dùng UserId + bảng này. |
| **AuthService.GetUserRoleCodesAsync** | Lấy toàn bộ role của user (không lọc org). Dùng khi login để đưa role vào JWT. |
| **JWT** | Chứa UserId, Username, danh sách Role codes. Không có OrganizationId. |
| **Policy "FormStructureAdmin"** | `RequireRole("SYSTEM_ADMIN", "FORM_ADMIN")` – kiểm tra role từ JWT. Nhiều controller dùng. |
| **UserService Create/Update** | Nhận `RoleIds`, `OrganizationIds` tách rời. Ghi UserRole với **OrganizationId = null** luôn. |
| **UserDto / CreateUserRequest / UpdateUserRequest** | RoleIds, OrganizationIds, PrimaryOrganizationId. Không có cặp (RoleId, OrganizationId). |
| **SessionContextMiddleware** | Set UserId lên DB session (RLS). Không đọc header. |
| **BCDT_Role** | Có trong DB + seed; entity Role có trong ứng dụng. Chưa có API CRUD hay trang FE quản lý vai trò. |
| **BCDT_Permission, BCDT_RolePermission** | Có trong DB + seed. Ứng dụng **chưa** có entity C# / DbSet / API / FE quản lý quyền. |
| **FE** | UsersPage gán RoleIds + OrganizationIds. apiClient không gửi X-Organization-Id. Không có trang Vai trò, không có màn gán quyền cho vai trò. |

### 1.2. Cần thêm / thay đổi (theo giải pháp)

| Thành phần | Yêu cầu |
|------------|--------|
| **Effective roles theo org** | Service lấy Role.Code từ UserRole theo (UserId, OrganizationId): `OrganizationId IS NULL OR OrganizationId = @CurrentOrgId`. |
| **Header X-Organization-Id** | Middleware đọc header, set CurrentOrganizationId vào HttpContext.Items (và có thể cache effective roles). |
| **Authorization theo effective roles** | Policy kiểm tra quyền dựa trên effective roles (từ DB) thay vì role trong JWT. |
| **Persistence (UserRole.OrganizationId)** | DTO + UserService cho phép gửi/lưu cặp (RoleId, OrganizationId?). |
| **API danh sách ngữ cảnh** | GET /api/v1/auth/me/contexts (hoặc mở rộng /auth/me) trả về danh sách (Role, Organization) của user. |
| **FE** | Gửi header; selector "Vai trò @ Đơn vị"; khi đổi ngữ cảnh load lại dữ liệu; form user gán cặp (Vai trò, Đơn vị). |
| **Quản lý vai trò** | API CRUD Role (list, get, create, update); FE trang “Vai trò” (xem, thêm, sửa). Hiện chỉ có seed, không có API/FE. |
| **Quản lý quyền** | Entity Permission, RolePermission (map từ DB); API list permissions, get/set permissions theo role; FE giao diện gán quyền cho từng vai trò. |

---

## 2. Nguyên tắc không ảnh hưởng công việc cũ

- **Tương thích ngược:** User hiện tại có UserRole toàn bộ với `OrganizationId = null`. Khi **không gửi** header (hoặc gửi 0): CurrentOrgId = 0 → effective roles = các role có `OrganizationId IS NULL` → **trùng với toàn bộ role hiện tại** → hành vi giống cũ.
- **Triển khai từng bước:** Mỗi phase có thể deploy riêng; phase sau dựa trên phase trước.
- **Không xóa/chặn luồng cũ:** Giữ login/JWT như cũ; chỉ **bổ sung** cách tính quyền (effective roles) khi có header. Client cũ không gửi header → vẫn dùng effective roles với CurrentOrgId=0 → vẫn đủ quyền như hiện tại.
- **Data hiện có:** Không migration bắt buộc. UserRole hiện tại toàn bộ OrganizationId=null → vẫn đúng với “role toàn hệ thống”. Khi nào admin gán “role tại đơn vị” qua form mới thì mới có dòng UserRole có OrganizationId khác null.

---

## 3. Kế hoạch triển khai theo phase

### Phase 1: Backend – Dịch vụ effective roles + đọc header (không đổi authorization)

**Mục tiêu:** Có sẵn EffectiveRoleService và CurrentOrganizationId trong request; **chưa** dùng để authorize. Mọi endpoint vẫn dùng policy cũ (JWT role). Hành vi không đổi.

| Bước | Nội dung | Rủi ro với cũ |
|------|----------|-----------------|
| 1.1 | Thêm interface `IEffectiveRoleService` với `GetEffectiveRoleCodes(userId, organizationId)`. Logic: query UserRole + Role, điều kiện `UserId`, `IsActive`, `OrganizationId IS NULL OR OrganizationId = @organizationId`. | Không. Chỉ thêm service. |
| 1.2 | Implement trong Infrastructure, đăng ký DI. | Không. |
| 1.3 | Middleware (hoặc filter) chạy sau Authentication: đọc header `X-Organization-Id`. Parse int; nếu không có/không hợp lệ → 0. Set `HttpContext.Items["CurrentOrganizationId"]` = giá trị đó. | Không. Client cũ không gửi header → 0 → effective roles = role global (null) = toàn bộ role hiện tại. |
| 1.4 | (Tùy chọn) Trong middleware: nếu đã auth, gọi EffectiveRoleService với (UserId, CurrentOrgId), set kết quả vào `HttpContext.Items["EffectiveRoleCodes"]` để tránh gọi nhiều lần trong request. | Không. |

**Kết quả Phase 1:** Backend có thể trả lời “effective roles cho (user, org)” và biết “current org” từ header; **authorization vẫn 100% theo JWT role**. Kiểm tra: gọi API như cũ (không header) → vẫn 200/403 như trước.

---

### Phase 2: Backend – Authorization theo effective roles (vẫn tương thích cũ)

**Mục tiêu:** Policy kiểm tra quyền theo **effective roles** (từ DB + CurrentOrgId) thay vì role trong JWT. Vì hiện tại mọi UserRole đều OrganizationId=null, khi CurrentOrgId=0 effective roles = toàn bộ role → **hành vi giống hệt cũ**.

| Bước | Nội dung | Rủi ro với cũ |
|------|----------|-----------------|
| 2.1 | Tạo Requirement + Handler (vd. `OrgScopedRoleRequirement` với params role codes; Handler lấy UserId từ Claims, CurrentOrgId từ HttpContext.Items, gọi IEffectiveRoleService, so khớp role). | Không. |
| 2.2 | Đăng ký policy (vd. giữ tên "FormStructureAdmin"): dùng requirement mới thay cho `RequireRole(...)`. Hoặc tạo policy mới "FormStructureAdminByOrg" và chuyển dần endpoint sang policy mới. **Đề xuất:** thay luôn implementation của "FormStructureAdmin" bằng handler mới (effective roles). Khi không header: CurrentOrgId=0 → effective = role có OrgId null = toàn bộ → không đổi hành vi. | Không, nếu logic effective roles đúng (OrgId null hoặc = CurrentOrgId). |
| 2.3 | Đảm bảo mọi endpoint đang dùng `[Authorize(Policy = "FormStructureAdmin")]` không đổi attribute; chỉ đổi cách policy được thỏa. | Không. |

**Kết quả Phase 2:** Phân quyền chức năng đã theo (user, role, org). Client cũ (không gửi header) vẫn hoạt động như trước. Kiểm tra: không header → quyền như cũ; gửi header org không có role → 403 (nếu đã có UserRole theo org thì tùy dữ liệu).

---

### Phase 3: Backend – API User nhận và lưu cặp (RoleId, OrganizationId)

**Mục tiêu:** Create/Update User có thể nhận **danh sách cặp (RoleId, OrganizationId?)**; UserService ghi đúng OrganizationId vào UserRole. **Giữ tương thích** với request cũ (chỉ RoleIds + OrganizationIds).

| Bước | Nội dung | Rủi ro với cũ |
|------|----------|-----------------|
| 3.1 | DTO: Thêm (hoặc mở rộng) `CreateUserRequest` / `UpdateUserRequest`: thêm property kiểu `List<UserRoleOrgItem>` với `RoleId`, `OrganizationId?`. Giữ nguyên `RoleIds`, `OrganizationIds` (deprecated hoặc dùng làm fallback). | Có thể giữ backward compatible: nếu request gửi **cặp** thì dùng cặp; nếu chỉ gửi RoleIds + OrganizationIds thì suy ra như cũ (mỗi role gán với OrganizationId = null). |
| 3.2 | UserService Create: Nếu có danh sách cặp → ghi UserRole từng cặp với OrganizationId tương ứng. Nếu không (chỉ RoleIds) → giữ logic cũ (OrganizationId = null). | Không. Request cũ vẫn tạo UserRole với OrgId null. |
| 3.3 | UserService Update: Sync UserRole từ danh sách cặp (xóa những không còn, thêm mới). Nếu request chỉ có RoleIds (không có cặp) → sync như cũ (role với OrganizationId null). | Không. |
| 3.4 | UserDto / GetById: Trả về danh sách cặp (RoleId, OrganizationId?) thay vì chỉ RoleIds (và OrganizationIds tách). Hoặc trả về cả hai (roleIds + roleOrgPairs) để FE cũ vẫn đọc RoleIds. | FE cũ đọc RoleIds vẫn được nếu DTO vẫn có RoleIds (có thể derive từ cặp). |

**Kết quả Phase 3:** Admin có thể gán “vai trò tại đơn vị” qua API; request cũ (chỉ RoleIds + OrganizationIds) vẫn tạo/sửa user như hiện tại (role toàn hệ thống).

---

### Phase 4: Backend – API danh sách ngữ cảnh (vai trò – đơn vị) cho user

**Mục tiêu:** FE có thể lấy danh sách “cặp (Vai trò, Đơn vị)” của user đăng nhập để hiển thị bộ chọn ngữ cảnh.

| Bước | Nội dung | Rủi ro với cũ |
|------|----------|-----------------|
| 4.1 | Endpoint `GET /api/v1/auth/me/contexts` (hoặc mở rộng `GET /auth/me`): trả về mảng phần tử { RoleCode, RoleName, OrganizationId, OrganizationName, IsGlobal }. Query từ UserRole + Role + Organization (join), filter UserId = current user. | Không. Chỉ thêm endpoint. |
| 4.2 | (Tùy chọn) Mở rộng response `/auth/me`: thêm field `contexts` chứa danh sách trên để FE không cần gọi thêm request. | Không. Có thể chỉ thêm field. |

**Kết quả Phase 4:** FE có dữ liệu để render dropdown “Vai trò @ Đơn vị” và biết org nào user được phép chọn.

---

### Phase 5: Frontend – Gửi header và chuyển ngữ cảnh

**Mục tiêu:** FE gửi `X-Organization-Id`; user có ≥2 cặp thì chọn ngữ cảnh; khi đổi ngữ cảnh thì load lại dữ liệu.

| Bước | Nội dung | Rủi ro với cũ |
|------|----------|-----------------|
| 5.1 | apiClient: Đọc “current organization id” từ AuthContext (hoặc storage). Mỗi request thêm header `X-Organization-Id: {id}` (nếu đã chọn; nếu chưa có thể không gửi hoặc 0). | Client cũ / session cũ không có state org → không gửi hoặc 0 → backend xử lý như hiện tại. |
| 5.2 | Sau login (hoặc load user): Gọi API lấy danh sách ngữ cảnh. Nếu 1 cặp → tự set làm current; nếu ≥2 → hiển thị dropdown “Vai trò @ Đơn vị”. | Không. |
| 5.3 | Khi user chọn cặp khác: Cập nhật state/storage, invalidate cache (hoặc redirect dashboard / reload trang) để load lại dữ liệu theo ngữ cảnh mới. | Không. |
| 5.4 | Hiển thị “Đang làm việc: [Vai trò @ Đơn vị]” trên layout. | Không. |

**Kết quả Phase 5:** Ứng dụng đã dùng đúng (user, role, org) cho phân quyền và hiển thị; đổi ngữ cảnh thì dữ liệu load lại đúng.

---

### Phase 6: Frontend – Form User gán cặp (Vai trò, Đơn vị)

**Mục tiêu:** Màn quản lý user cho phép gán từng cặp (Vai trò, Đơn vị) thay vì hai list tách.

| Bước | Nội dung | Rủi ro với cũ |
|------|----------|-----------------|
| 6.1 | UsersPage: Form tạo/sửa user nhận danh sách cặp (RoleId, OrganizationId?). UI: bảng hoặc danh sách “Vai trò + Đơn vị” (dropdown từng cặp), nút thêm/xóa dòng. Cho phép chọn “Toàn hệ thống” (OrganizationId null). | Có thể giữ tương thích: nếu API vẫn nhận RoleIds + OrganizationIds thì FE cũ gửi như cũ; FE mới gửi roleOrgPairs. Hoặc chuyển hẳn sang roleOrgPairs, khi load user hiện tại trả về cặp → FE hiển thị đúng. |
| 6.2 | Khi load user: Map response (roleOrgPairs hoặc RoleIds/OrganizationIds) sang state form. Khi submit: gửi roleOrgPairs theo API mới. | Không. |

**Kết quả Phase 6:** Admin có thể gán “User X: tại đơn vị A vai trò R1, tại đơn vị B vai trò R2”. Dữ liệu đúng với mô hình (User, Role, Org).

---

### Phase 7: Quản lý vai trò (Role) – Backend API + Frontend

**Mục tiêu:** CRUD vai trò (ít nhất Code, Name, Description, IsActive); FE có trang “Vai trò” để xem/sửa/thêm vai trò. Hiện tại chỉ có seed Role, không có API/FE quản lý.

| Bước | Nội dung | Rủi ro với cũ |
|------|----------|-----------------|
| 7.1 | **Backend:** API `GET /api/v1/roles` (list), `GET /api/v1/roles/{id}` (chi tiết), `POST /api/v1/roles`, `PUT /api/v1/roles/{id}`, (tùy chọn) `DELETE` hoặc vô hiệu hóa. Service + Controller + DTO (RoleDto, CreateRoleRequest, UpdateRoleRequest). Validate Code unique, IsSystem role không cho xóa/sửa Code. | Không. Chỉ thêm endpoint. Role hiện dùng trong UserRole/Policy không đổi. |
| 7.2 | **Frontend:** Trang “Vai trò” (RolesPage): bảng danh sách, modal hoặc form tạo/sửa (Code, Name, Mô tả, IsActive). Gọi API roles. Phân quyền: chỉ user có role SYSTEM_ADMIN (hoặc policy tương đương) mới vào được. | Không. |

**Kết quả Phase 7:** Admin có thể xem, thêm, sửa vai trò (trừ vai trò hệ thống bảo vệ). Phù hợp với đề xuất mở rộng “API + FE quản lý vai trò” trong DANH_GIA_THIET_KE.

---

### Phase 8: Quản lý quyền (Permission) và gán quyền cho vai trò – Backend + Frontend

**Mục tiêu:** Bảng BCDT_Permission, BCDT_RolePermission đã có trong DB (và seed); ứng dụng chưa có entity/API/FE. Cần map entity, API đọc/sửa quyền theo vai trò, FE giao diện gán quyền cho từng vai trò.

| Bước | Nội dung | Rủi ro với cũ |
|------|----------|-----------------|
| 8.1 | **Backend – Entity:** Thêm entity `Permission`, `RolePermission` (Domain + DbContext). Map đúng bảng BCDT_Permission, BCDT_RolePermission. | Không. Chỉ thêm DbSet và config. |
| 8.2 | **Backend – API:** `GET /api/v1/permissions` (list theo module hoặc toàn bộ). `GET /api/v1/roles/{id}/permissions` (danh sách PermissionId đã gán cho role). `PUT /api/v1/roles/{id}/permissions` (body: list PermissionId; sync RolePermission). Policy: chỉ SYSTEM_ADMIN (hoặc role tương đương). | Không. Authorization hiện vẫn theo role; chưa bắt buộc kiểm tra Permission trong policy (có thể bổ sung sau). |
| 8.3 | **Frontend:** Trong trang Vai trò (hoặc màn riêng): với mỗi vai trò có nút “Phân quyền” / “Gán quyền”. Mở modal/drawer: danh sách quyền (nhóm theo Module), checkbox chọn quyền cho role đó; lưu qua PUT roles/{id}/permissions. | Không. |

**Kết quả Phase 8:** Admin có thể xem danh sách quyền và gán/bỏ quyền cho từng vai trò. Dữ liệu RolePermission dùng sau này cho phân quyền chi tiết (policy kiểm tra Permission) nếu cần.

**Lưu ý:** Sau Phase 8, có thể (tùy chọn) bổ sung policy kiểm tra Permission thay vì chỉ Role code (vd. `RequirePermission("Form.Create")`). Đây là bước mở rộng, không bắt buộc cho “quản lý quyền” cơ bản.

---

## 4. Tóm tắt thứ tự và phụ thuộc

```
Phase 1 (BE: service + header)           → không đổi hành vi
    ↓
Phase 2 (BE: policy effective roles)    → tương thích vì UserRole hiện toàn bộ OrgId null
    ↓
Phase 3 (BE: DTO + UserService cặp)     → backward compatible request cũ
    ↓
Phase 4 (BE: API /me/contexts)          → chỉ thêm endpoint
    ↓
Phase 5 (FE: header + selector + reload) → hoạt động với BE đã có Phase 1–4
    ↓
Phase 6 (FE: form user cặp)              → hoạt động với BE Phase 3

Phase 7 (BE+FE: quản lý vai trò – CRUD Role)  → độc lập với 1–6; có thể triển khai song song hoặc sau Phase 3
    ↓
Phase 8 (BE+FE: quản lý quyền + gán quyền cho vai trò)  → cần Phase 7 (API roles có sẵn)
```

**Thứ tự gợi ý:** Phase 1–6 theo thứ tự (User–Role–Org + ngữ cảnh + form user). **Quản lý vai trò (Phase 7)** có thể làm song song sau khi có Phase 2 hoặc 3. **Quản lý quyền (Phase 8)** làm sau Phase 7.

**Kiểm tra sau mỗi phase:** Build, test API (Postman/curl): không header → quyền như cũ; có header (khi đã có dữ liệu UserRole theo org) → quyền theo đơn vị. RLS không đổi, chỉ phân quyền chức năng (endpoint/menu) theo effective roles.

---

## 5. Checklist rủi ro “ảnh hưởng công việc cũ”

| Kiểm tra | Cách xác nhận |
|----------|----------------|
| User hiện tại (chỉ có UserRole OrgId=null) | Sau Phase 2, không gửi header → vẫn vào được endpoint FormStructureAdmin. |
| Client không gửi X-Organization-Id | CurrentOrgId = 0 → effective roles = role có OrgId null = toàn bộ role. |
| CreateUser/UpdateUser chỉ gửi RoleIds + OrganizationIds | Phase 3 vẫn xử lý được (fallback logic cũ). |
| RLS, SessionContextMiddleware | Không đổi; vẫn chỉ set UserId. |
| JWT, login, refresh | Không đổi. |

---

**Version:** 1.1  
**Ngày:** 2026-02-11
