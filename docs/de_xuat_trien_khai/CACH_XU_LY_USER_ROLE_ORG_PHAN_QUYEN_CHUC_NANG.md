# Cách xử lý User–Role–Org làm khóa phân quyền chức năng

**Mục đích:** Mô tả cách dùng bộ ba (User, Role, Organization) để phân quyền **chức năng** (endpoint/action): user chỉ được thực hiện thao tác khi có **vai trò tương ứng trong đơn vị ngữ cảnh**.

---

## 1. Nguyên tắc

- **Khóa phân quyền chức năng:** `(UserId, RoleId, OrganizationId)`.
  - **BCDT_UserRole:** mỗi dòng = user có vai trò RoleId tại đơn vị OrganizationId (hoặc NULL = “toàn hệ thống”).
  - Khi kiểm tra quyền: chỉ tính **vai trò hiệu lực trong đơn vị ngữ cảnh** (current org).

- **Đơn vị ngữ cảnh (current organization):**
  - Mỗi request API gắn với **một** đơn vị ngữ cảnh (header `X-Organization-Id`).
  - FE: khi user “đang làm việc tại đơn vị X”, mọi request gửi kèm `X-Organization-Id: X`.
  - Nếu không gửi (hoặc 0): coi là “global” – chỉ tính các UserRole có `OrganizationId IS NULL`.

- **Vai trò hiệu lực (effective roles):**
  - Với `(UserId, CurrentOrgId)`:
    - Lấy tất cả Role.Code từ **BCDT_UserRole** join **BCDT_Role** với điều kiện:
      - `UserId = @UserId`
      - `IsActive = 1`
      - `OrganizationId IS NULL` **hoặc** `OrganizationId = @CurrentOrgId`
    - Đây là danh sách role dùng để kiểm tra [Authorize] / policy (phân quyền chức năng).

- **RLS (phân quyền dữ liệu):** Giữ nguyên như hiện tại (UserId + UserOrganization + TreePath). RLS không cần OrganizationId trong session nếu predicate chỉ dùng UserId và UserOrganization.

---

## 2. Luồng xử lý

```
1. Request tới API (có JWT, có thể có header X-Organization-Id).
2. Authentication: JWT → UserId (và có thể giữ role trong JWT chỉ để tương thích).
3. Resolve ngữ cảnh đơn vị: CurrentOrgId = header X-Organization-Id (hoặc 0 nếu không gửi).
4. Resolve vai trò hiệu lực: EffectiveRoles = service.GetEffectiveRoleCodes(UserId, CurrentOrgId).
5. Authorization: Policy/Requirement kiểm tra "EffectiveRoles có chứa role yêu cầu không" (vd. FORM_ADMIN).
6. Nếu có → cho phép; không → 403 Forbidden.
```

---

## 3. Triển khai kỹ thuật (tóm tắt)

| Thành phần | Nội dung |
|------------|----------|
| **Header** | `X-Organization-Id: {id}` (optional). 0 hoặc không gửi = chỉ tính role global (OrganizationId NULL). |
| **Service** | `IEffectiveRoleService.GetEffectiveRoleCodes(userId, organizationId)` – query UserRole + Role, trả về list Role.Code. |
| **Authorization** | Custom `AuthorizationHandler` (vd. `OrgScopedRoleRequirement`): lấy UserId từ Claims, CurrentOrgId từ header (hoặc HttpContext.Items set bởi middleware), gọi EffectiveRoleService, kiểm tra role yêu cầu nằm trong effective roles. |
| **Policy** | Đăng ký policy dùng requirement trên (vd. "FormStructureAdmin" = RequireEffectiveRole("SYSTEM_ADMIN", "FORM_ADMIN")). |
| **Persistence** | CreateUser/UpdateUser nhận danh sách cặp (RoleId, OrganizationId?). UserService ghi vào BCDT_UserRole với OrganizationId tương ứng. |
| **FE** | (1) Gửi header `X-Organization-Id` bằng đơn vị user đang chọn. (2) Màn quản lý user: gán từng cặp (Vai trò, Đơn vị) thay vì hai list tách. |

---

## 4. Bảo mật khi dùng header X-Organization-Id

**Header do client gửi** – trình duyệt/ứng dụng có thể gửi bất kỳ giá trị nào. Nếu backend **tin và dùng trực tiếp** header để quyết định quyền hoặc trả dữ liệu thì sẽ **lỗ hổng** (user giả mạo `X-Organization-Id: 999` để truy cập đơn vị 999).

**Cách dùng an toàn (không lỗi bảo mật):**

| Nguyên tắc | Cách làm |
|------------|----------|
| **Không tin header để cấp quyền** | Backend **không** coi “có gửi X-Organization-Id = 999” là “user được quyền đơn vị 999”. Chỉ dùng header như **ngữ cảnh đang chọn** (current org). |
| **Luôn tra cứu từ DB** | Vai trò hiệu lực lấy từ **BCDT_UserRole** với `UserId` (từ JWT, không từ header) và `OrganizationId` = giá trị header. Nếu user **không** có bản ghi UserRole nào với (UserId, OrgId) tương ứng → effective roles chỉ còn role global (OrganizationId NULL) → không có quyền đặc biệt của đơn vị đó. Kẻ tấn công gửi org khác chỉ nhận được **ít quyền hơn hoặc 403**, không nhận thêm quyền. |
| **Phân quyền dữ liệu vẫn theo RLS** | RLS lọc theo **UserId** (session context) và **BCDT_UserOrganization** (user thuộc đơn vị nào, cây đơn vị). RLS **không** dùng X-Organization-Id để mở khóa dữ liệu. Dù client gửi org nào, user chỉ thấy/sửa dữ liệu đơn vị mà họ thuộc (UserOrganization + TreePath). |
| **Validate nếu cần** | Tùy nghiệp vụ, có thể thêm bước: nếu endpoint “chỉ được gọi trong đơn vị user thuộc”, kiểm tra `CurrentOrgId` (từ header) có nằm trong danh sách đơn vị user được phép (từ UserOrganization) không; nếu không → 403. |

**Kết luận:** Đưa `X-Organization-Id` lên header **không gây lỗi bảo mật** nếu:

1. **UserId** luôn lấy từ **JWT** (đã xác thực), không từ header.
2. **Quyền chức năng** (effective roles) luôn tính từ **DB** (UserRole) theo cặp (UserId, OrganizationId); header chỉ cung cấp OrganizationId để tra cứu.
3. **Quyền dữ liệu** (ai thấy dữ liệu gì) do **RLS** quyết định theo UserId và UserOrganization, không theo header.

**Cần tránh:** Dùng `X-Organization-Id` để “chọn luôn” dữ liệu trả về (vd. `WHERE OrganizationId = @HeaderOrgId`) mà không ràng buộc với UserId/UserOrganization/RLS – khi đó user có thể đổi header để đọc dữ liệu đơn vị khác. Trong thiết kế này, dữ liệu đã được RLS lọc theo user nên an toàn; header chỉ ảnh hưởng **vai trò hiệu lực** (menu/nút/endpoint nào được phép), không thay thế RLS.

---

## 5. Quy tắc nghiệp vụ

- **OrganizationId NULL trong UserRole:** Role đó áp dụng cho **mọi đơn vị** (global). Khi tính effective roles tại bất kỳ CurrentOrgId nào, vẫn luôn gồm các role có OrganizationId NULL.
- **Cùng user, cùng role, khác đơn vị:** Có thể có nhiều dòng UserRole: (User, RoleA, Org1), (User, RoleA, Org2) – user có RoleA tại Org1 và Org2. Khi CurrentOrgId = Org1 thì effective roles có RoleA; khi CurrentOrgId = Org2 cũng có RoleA.
- **Endpoint không cần org:** Một số API (vd. GET /auth/me, đổi mật khẩu) không phụ thuộc đơn vị. Có thể:
  - Không yêu cầu header; dùng CurrentOrgId = 0 → chỉ role global, hoặc
  - Cho phép dùng “bất kỳ role nào” (chỉ cần đăng nhập) với [Authorize] không gắn policy role-org.

- **Vai trò luôn gắn với đơn vị (bắt buộc):** Khi gán hoặc chọn vai trò cho user, **phải** chỉ rõ đơn vị (trừ role “toàn hệ thống” nếu cho phép OrganizationId NULL). Trên giao diện: không có “chọn vai trò” độc lập; luôn chọn **cặp (Vai trò, Đơn vị)**.

---

## 6. Chuyển ngữ cảnh (vai trò – đơn vị) khi user có từ 2 cặp trở lên

### 6.1. Bối cảnh

- User có thể có nhiều cặp (Vai trò, Đơn vị) – ví dụ: (Trưởng phòng, Chi cục A), (Nhập liệu, Chi cục B).
- Mỗi request chỉ có **một** ngữ cảnh hiệu lực: một đơn vị + các role tại đơn vị đó (và role global).
- Cần cơ chế để user **chuyển** sang làm việc với vai trò–đơn vị khác khi có ≥ 2 cặp.

### 6.2. Nguyên tắc chuyển ngữ cảnh

- **Chọn ngữ cảnh = chọn cặp (Vai trò, Đơn vị):** Không chọn “chỉ vai trò” hoặc “chỉ đơn vị”. Mỗi lần chọn là chọn **một cặp** trong danh sách (Role, Organization) mà user được gán.
- **Bắt buộc gắn đơn vị khi chọn vai trò:** Giao diện chuyển ngữ cảnh hiển thị danh sách **cặp** (tên vai trò + tên đơn vị). Khi user chọn một mục, hệ thống set đồng thời đơn vị ngữ cảnh và (implicit) vai trò hiệu lực tại đơn vị đó.
- **Lưu ngữ cảnh hiện tại:** FE lưu cặp (OrganizationId, có thể kèm RoleId hoặc RoleCode để hiển thị) – ví dụ localStorage/sessionStorage hoặc state – và gửi `X-Organization-Id` tương ứng cho mọi request tiếp theo cho đến khi user chuyển ngữ cảnh.

### 6.3. Giải pháp triển khai (gợi ý)

| Thành phần | Nội dung |
|------------|----------|
| **API danh sách ngữ cảnh** | Endpoint (vd. `GET /api/v1/auth/me/contexts` hoặc mở rộng `GET /auth/me`) trả về danh sách **cặp (RoleId/RoleCode, OrganizationId)** mà user đang có (từ BCDT_UserRole + Role + Organization). Mỗi phần tử có: RoleCode, RoleName, OrganizationId, OrganizationName (và có thể IsGlobal nếu OrganizationId null). |
| **Chọn ngữ cảnh** | FE không gọi API “set context” (ngữ cảnh chỉ là header mỗi request). User chọn một cặp từ danh sách → FE lưu OrganizationId (và tên hiển thị) → từ đó mọi request gửi `X-Organization-Id: {id}`. Backend không lưu “context hiện tại” phía server. |
| **UI chuyển ngữ cảnh** | Dropdown/selector trên header hoặc menu user: hiển thị danh sách dạng “Vai trò @ Đơn vị” (vd. “Trưởng phòng @ Chi cục A”, “Nhập liệu @ Chi cục B”). Chọn một mục = đổi OrganizationId gửi trong header và (tùy) cập nhật label “Đang làm việc: …”. |
| **User chỉ có 1 cặp** | Có thể tự động chọn ngữ cảnh đó sau login (và vẫn gửi `X-Organization-Id`). Không bắt buộc hiện dropdown chuyển nếu chỉ có một lựa chọn. |
| **User có 0 cặp (chưa gán)** | Chỉ có role global (OrganizationId NULL) nếu có; khi đó có thể không gửi header hoặc gửi 0. FE có thể ẩn selector hoặc hiển thị “Toàn hệ thống”. |

### 6.4. Luồng người dùng (tóm tắt)

1. Sau đăng nhập: gọi API lấy danh sách ngữ cảnh (cặp vai trò–đơn vị) của user.
2. Nếu có ≥ 2 cặp: hiển thị bộ chọn “Vai trò @ Đơn vị”; nếu có 1 cặp: có thể tự set và không bắt buộc cho user chọn.
3. User chọn một cặp (hoặc mặc định cặp đầu) → FE lưu OrganizationId (và tên để hiển thị), gửi `X-Organization-Id` cho mọi request.
4. Khi user đổi sang cặp khác: cập nhật giá trị đang lưu + header, **và bắt buộc load lại dữ liệu** theo ngữ cảnh mới (xem 6.5).

### 6.5. Load lại dữ liệu khi chuyển ngữ cảnh (vai trò – đơn vị)

Sau khi user chọn cặp (Vai trò, Đơn vị) khác, dữ liệu đang hiển thị có thể thuộc đơn vị cũ hoặc đã lọc theo quyền cũ. Để đảm bảo **dữ liệu và quyền thao tác luôn khớp với vai trò – đơn vị hiện tại**, cần load lại dữ liệu theo đúng ngữ cảnh mới.

**Nguyên tắc:**

- Mọi request sau khi đổi ngữ cảnh phải dùng **header `X-Organization-Id` mới**. Backend (RLS + effective roles) sẽ trả về đúng dữ liệu và quyền theo đơn vị đó.
- Dữ liệu đã fetch/cache trước khi đổi ngữ cảnh **không còn đúng ngữ cảnh** → FE phải coi là hết hạn và **load lại** (refetch / invalidate cache), không tái sử dụng cho ngữ cảnh mới.

**Giải pháp FE (gợi ý):**

| Cách làm | Mô tả |
|----------|--------|
| **Invalidate + refetch** | Khi user chọn ngữ cảnh mới: (1) cập nhật state/header `X-Organization-Id`; (2) **invalidate** toàn bộ query/cache phụ thuộc đơn vị hoặc quyền (vd. React Query `queryClient.invalidateQueries()`, hoặc invalidate theo từng key có OrganizationId/role); (3) các component đang dùng data sẽ **refetch** với header mới → dữ liệu và menu/button theo đúng vai trò–đơn vị. |
| **Redirect về trang chủ / dashboard** | Sau khi đổi ngữ cảnh: chuyển về trang chủ hoặc dashboard, rồi load dữ liệu từ đầu. Đơn giản, tránh dữ liệu lỗi thời trên trang cũ (vd. danh sách submission của đơn vị A vẫn hiển thị khi đã chuyển sang đơn vị B). |
| **Reload toàn trang** | Nếu FE chưa có cache layer: sau khi lưu ngữ cảnh mới (vd. localStorage + state), **reload trang** (`window.location.reload()`). Mọi request sau reload sẽ mang header mới; dữ liệu load lại hoàn toàn theo đơn vị và quyền mới. |

**Khuyến nghị:**

- Ưu tiên **invalidate + refetch** nếu đã dùng React Query / SWR / cache có key theo org: trải nghiệm mượt, chỉ refetch những gì cần.
- Nếu chưa có cache thống nhất: **redirect về dashboard (hoặc trang chủ)** sau khi đổi ngữ cảnh, rồi load lại; hoặc **reload trang** để đơn giản và an toàn.
- **Menu / permission-driven UI:** Sau khi load lại, BE trả về menu hoặc danh sách quyền theo effective roles của đơn vị mới; FE cập nhật menu/nút theo response đó (hoặc refetch endpoint menu/permissions với header mới).

**Backend:**

- Không cần API riêng “reload”. Mỗi request đã mang `X-Organization-Id` → RLS và effective roles áp dụng đúng; FE chỉ cần **gửi lại request** (refetch) sau khi đổi ngữ cảnh để nhận dữ liệu và hành vi đúng vai trò–đơn vị.

---

## 7. Thứ tự triển khai gợi ý

1. **IEffectiveRoleService + implementation:** Query effective Role.Code theo (UserId, OrganizationId).
2. **Middleware hoặc filter:** Đọc header `X-Organization-Id`, set vào `HttpContext.Items["CurrentOrganizationId"]` (và có thể set effective roles vào Items để tránh query nhiều lần).
3. **Custom AuthorizationHandler:** Requirement “RequireEffectiveRole(params string[] roles)”; handler lấy UserId, CurrentOrgId, gọi EffectiveRoleService (hoặc lấy từ Items), trả về Success nếu giao với roles khác rỗng.
4. **Đăng ký policy:** Thay policy hiện tại (RequireRole) bằng policy dùng RequireEffectiveRole cho endpoint cần phân quyền theo (user, role, org).
5. **UserService + DTO:** CreateUserRequest/UpdateUserRequest nhận `List<(RoleId, OrganizationId?)>`; UserService sync BCDT_UserRole kèm OrganizationId.
6. **FE:** Dropdown/selector đơn vị → gửi header; form user: bảng/cặp (Vai trò, Đơn vị).

**Kế hoạch chi tiết từng phase (không ảnh hưởng công việc cũ):** [KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md](KE_HOACH_TRIEN_KHAI_USER_ROLE_ORG.md).

---

**Version:** 1.4  
**Ngày:** 2026-02-11
