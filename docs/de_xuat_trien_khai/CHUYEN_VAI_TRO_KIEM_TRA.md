# Chuyển vai trò – Kiểm tra cho AI

## Tóm tắt tính năng
- **BE:** GET `/api/v1/auth/me/roles` trả danh sách vai trò của user (Id, Code, Name, OrganizationId?, OrganizationName?) – mỗi cặp (vai trò, đơn vị) một mục.
- **FE:** Dropdown user có "Chuyển vai trò" → modal chọn vai trò (hiển thị "Vai trò (Đơn vị)" khi có); lưu vào context + localStorage; header hiển thị tên vai trò (và đơn vị nếu có).
- **Dữ liệu:** Dùng bảng BCDT_UserRole, BCDT_Role (seed sẵn). User admin đã có role SYSTEM_ADMIN.

## 7.1. Kiểm tra cho AI (checklist)

| # | Bước | Kỳ vọng | Cách kiểm tra |
|---|------|---------|----------------|
| 1 | Build BE | Build thành công | `dotnet build src/BCDT.Api/BCDT.Api.csproj` (tắt process BCDT.Api trước nếu cần). |
| 2 | API GET /auth/me/roles (có token) | 200, body `{ success: true, data: [ { id, code, name, organizationId?, organizationName? }, ... ] }` | Postman: Login → Me Roles. Mỗi cặp (vai trò, đơn vị) là một phần tử; cùng vai trò khác đơn vị = nhiều phần tử. |
| 3 | API GET /auth/me/roles (không token) | 401 | Gọi không gửi header Authorization. |
| 4 | FE – Dropdown có "Chuyển vai trò" | Mục hiển thị, click mở modal | Đăng nhập → click avatar/tên → thấy "Chuyển vai trò" → click → modal mở. |
| 5 | FE – Modal danh sách vai trò | Radio list vai trò (tên + code), nút Áp dụng, Hủy | Modal hiển thị ít nhất 1 vai trò (admin có SYSTEM_ADMIN). Chọn 1 vai trò → Áp dụng → modal đóng. |
| 6 | FE – Header hiển thị vai trò đang chọn | Dưới tên user có dòng nhỏ tên vai trò (và đơn vị nếu có) | Sau khi Áp dụng, header hiển thị "Vai trò" hoặc "Vai trò (Đơn vị)". Reload trang vẫn giữ. |
| 7 | Postman collection | Có request "Me Roles", import không lỗi | Mở `docs/postman/BCDT-API.postman_collection.json`, parse JSON thành công; trong folder Auth có "Me Roles". |

## Dữ liệu cần có
- User đăng nhập được (vd admin / Admin@123).
- User đó có ít nhất 1 bản ghi trong BCDT_UserRole (role đang active). Seed 14.seed_data.sql gán admin → SYSTEM_ADMIN (toàn hệ thống) và UNIT_ADMIN tại đơn vị MOF (Bộ Tài chính); GET me/roles trả 2 mục để test chuyển vai trò.

## Kết luận
- **BE:** Đủ (API, DTO, service).
- **FE:** Đủ (dropdown, modal, context, localStorage).
- **Dữ liệu:** Đủ (dùng sẵn UserRole/Role).
- **Test:** Có checklist thủ công trên; chưa có unit/integration test tự động (dự án chưa có test project cho API). Postman request "Me Roles" đã thêm.
