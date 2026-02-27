# Đề xuất triển khai B6 – Frontend (cho AI)

Tài liệu hướng dẫn AI triển khai **B6: Frontend** – Login page, trang quản lý đơn vị, trang quản lý user (DevExtreme); gọi API BCDT (/api/v1/auth, organizations, users).

**Tham chiếu:** [TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md), [BCDT-API.postman_collection.json](../postman/BCDT-API.postman_collection.json).

---

## 1. Mục tiêu B6

| Deliverable | Mô tả |
|-------------|--------|
| Trang đăng nhập | Form username/password; gọi POST /api/v1/auth/login; lưu accessToken (localStorage/sessionStorage); redirect sau khi đăng nhập thành công. |
| Trang quản lý đơn vị | List (DataGrid/table) gọi GET /api/v1/organizations; có thể thêm form tạo/sửa (POST, PUT, DELETE theo B4 API). |
| Trang quản lý user | List (DataGrid/table) gọi GET /api/v1/users; có thể thêm form tạo/sửa (POST, PUT, DELETE theo B5 API). |
| Bảo vệ route | Các trang /organizations, /users chỉ truy cập khi đã đăng nhập; nếu chưa có token thì redirect về /login. |

---

## 2. API hiện có

- **POST /api/v1/auth/login** – Body: `{ username, password }`. Response: `{ success, data: { accessToken, refreshToken, expiresIn, user } }`.
- **GET /api/v1/auth/me** – Header: `Authorization: Bearer <accessToken>`. Response: `{ success, data: { id, username, email, fullName } }`.
- **GET /api/v1/organizations** – Query: parentId, organizationTypeId, includeInactive. Response: `{ success, data: OrganizationDto[] }`.
- **GET /api/v1/organizations/:id**, **POST**, **PUT**, **DELETE** – (B4).
- **GET /api/v1/users** – Query: organizationId, includeInactive. Response: `{ success, data: UserDto[] }`.
- **GET /api/v1/users/:id**, **POST**, **PUT**, **DELETE** – (B5).

Base URL mặc định: `http://localhost:5080` (cấu hình qua env VITE_API_BASE_URL hoặc constant).

---

## 3. Kiến trúc gợi ý

- **api/** – apiClient (axios, interceptors gắn Bearer token), authApi, organizationsApi, usersApi.
- **hooks/** – useAuth, useOrganizations, useUsers (react-query).
- **context/** – AuthContext (token, user, login, logout).
- **pages/** – LoginPage, OrganizationsPage, UsersPage.
- **components/** – ProtectedRoute, layout (sidebar/menu nếu cần), bảng cho Organizations/Users.
- **routes/** – /login, / (redirect), /organizations, /users; ProtectedRoute bọc route cần auth.
- **UI chung (login, đơn vị, user, layout):** **Ant Design** – Form, Input, Button, Table, Layout; theme qua ConfigProvider. Chi tiết: [FRONTEND_UI_THEME.md](FRONTEND_UI_THEME.md).
- **DevExpress (DevExtreme):** **Chỉ dùng cho module nhập liệu Excel** (biểu mẫu báo cáo, Spreadsheet). Không dùng cho login/đơn vị/user. Khi triển khai module Excel mới import DevExtreme (lazy) và cấu hình license trong module đó.

### 3.1. DevExtreme license (chỉ cho module nhập liệu Excel)

Nếu thấy banner màu cam *"For evaluation purposes only..."*:

1. Lấy license key: đăng nhập [DevExpress Client Center](https://www.devexpress.com/ClientCenter/DownloadManager/) → chọn DevExtreme → copy License key.
2. Trong `src/bcdt-web`: copy `.env.example` thành `.env` (hoặc `.env.local`).
3. Gán `VITE_DEVEXTREME_LICENSE_KEY=<key_của_bạn>`.
4. Khởi động lại `npm run dev`. Không commit file `.env` / `.env.local` có key.

Khi có module Excel: gọi `config({ licenseKey })` trong entry của module đó (trước khi render component DevExtreme); không gọi trong `main.tsx`.

---

## 4. Kiểm tra sau khi triển khai

Xem mục **7.1. Kiểm tra cho AI**; AI tự chạy đủ bước và báo Pass/Fail từng bước, **không skip** bước nào.

---

## 7.1. Kiểm tra cho AI (tự chạy và báo kết quả)

**AI sau khi triển khai B6 chạy lần lượt các bước dưới đây và báo Pass/Fail.**

1. **Build frontend**
   - Lệnh: `npm run build` trong `src/bcdt-web` (hoặc `bcdt-web`).
   - Kỳ vọng: Build succeeded (tsc + vite build).

2. **API đang chạy**
   - Backend API BCDT chạy tại http://localhost:5080 (vd `dotnet run --project src/BCDT.Api`).

3. **Chạy frontend**
   - Lệnh: `npm run dev` trong `src/bcdt-web`. Mở http://localhost:5173 (hoặc port Vite báo).

4. **Trang đăng nhập**
   - Mở http://localhost:5173/login (hoặc / rồi redirect đến /login).
   - Kỳ vọng: Form có username, password; nút đăng nhập.

5. **Login thành công**
   - Nhập username: admin, password: Admin@123; bấm đăng nhập.
   - Kỳ vọng: Gọi API login thành công; lưu token; redirect đến trang chính (vd /organizations hoặc /).

6. **Trang quản lý đơn vị**
   - Sau khi đăng nhập, vào /organizations.
   - Kỳ vọng: Hiển thị list (Ant Design Table); có nút Thêm đơn vị, cột Thao tác (Sửa, Xóa); không lỗi 401.

7. **Trang quản lý user**
   - Vào /users.
   - Kỳ vọng: Hiển thị list (Ant Design Table); có nút Thêm người dùng, cột Thao tác (Sửa, Xóa); không lỗi 401.

7a. **Form tạo/sửa đơn vị** (nếu có)
   - Trên /organizations: bấm Thêm đơn vị → Modal mở với form (Mã, Tên, Loại đơn vị, Đơn vị cha, …). Điền và Tạo → list cập nhật. Bấm Sửa một dòng → Modal sửa → Cập nhật → list cập nhật. Bấm Xóa → xác nhận → dòng biến mất (hoặc API trả lỗi nếu không cho xóa).

7b. **Form tạo/sửa user** (nếu có)
   - Trên /users: bấm Thêm người dùng → Modal với form (Username, Mật khẩu, Họ tên, Email, Vai trò, Đơn vị, …). Tạo → list cập nhật. Sửa user (đổi mật khẩu tùy chọn) → Cập nhật. Xóa (xác nhận) → list cập nhật.

8. **Chưa đăng nhập truy cập /organizations**
   - Mở tab ẩn danh hoặc xóa token; vào http://localhost:5173/organizations.
   - Kỳ vọng: Redirect về /login (hoặc 401 và redirect).

9. **Logout (nếu có)**
   - Bấm đăng xuất (nếu có nút).
   - Kỳ vọng: Xóa token; redirect về /login.

10. **Postman collection**
    - Không bắt buộc sửa Postman cho B6; nếu không sửa: bước này Pass.

**Báo kết quả:** Liệt kê từng bước (1–10, 7a, 7b) kèm **Pass** hoặc **Fail**. **Không skip** bước nào. **Console:** Kiểm tra DevTools Console không có cảnh báo deprecated (antd).

**Chạy nhanh:** Build: `npm run build` trong `src/bcdt-web`. Dev: `npm run dev` trong `src/bcdt-web`. API: `dotnet run --project src/BCDT.Api --launch-profile http`. Script: `powershell -ExecutionPolicy Bypass -File scripts/test-b6-checklist.ps1` (từ thư mục gốc). **Tự test UI (FE+BE):** Xem [B6_AI_TU_TEST_UI.md](B6_AI_TU_TEST_UI.md) – chạy `npm run test:e2e` trong `src/bcdt-web` (cần cài Playwright và API đang chạy) hoặc dùng MCP browser theo từng bước.

---

**Version:** 1.3  
**Ngày:** 2026-02-05  
**Trạng thái triển khai:** Login; AppLayout (Header, Sider, Content, Footer) responsive; Organizations/Users list + **form Modal tạo/sửa/xóa đơn vị** (POST/PUT/DELETE /api/v1/organizations) + **form Modal tạo/sửa/xóa user** (POST/PUT/DELETE /api/v1/users, gán RoleIds/OrganizationIds); constants organizationTypes, roles; api create/update/delete. Build Pass. Test thủ công: bước 5–9, 7a, 7b; kiểm tra Console không deprecated.
