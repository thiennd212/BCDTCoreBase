# Hướng dẫn sử dụng hệ thống BCDT

Tài liệu hướng dẫn người dùng các chức năng chính của hệ thống Báo cáo Công khai Dữ liệu Tài chính (BCDT) trên môi trường localhost/demo.

**Tham chiếu kỹ thuật:** [RUNBOOK.md](RUNBOOK.md) (cài đặt, chạy API/FE), [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md).

---

## 1. Đăng nhập và xác thực (Auth)

### 1.1. Đăng nhập

1. Mở trình duyệt, truy cập URL frontend (vd. `http://localhost:5173`).
2. Nhập **Tên đăng nhập** và **Mật khẩu**.
3. Sau khi đăng nhập thành công, hệ thống chuyển về trang chủ/dashboard; token được lưu và dùng cho các request tiếp theo.

**Tài khoản mặc định (sau khi chạy seed):**

- **Tên đăng nhập:** `admin`
- **Mật khẩu:** `Admin@123`

Nên đổi mật khẩu ngay sau lần đăng nhập đầu.

### 1.2. Đăng xuất

Chọn **Đăng xuất** trên menu/header để kết thúc phiên. Token sẽ bị vô hiệu hóa (nếu backend hỗ trợ logout blacklist).

### 1.3. Làm mới token (Refresh)

Ứng dụng có thể tự gọi API refresh token khi access token hết hạn; người dùng không cần thao tác. Nếu bị 401, thử đăng nhập lại.

---

## 2. Quản lý đơn vị (Organization)

### 2.1. Xem danh sách đơn vị

- Vào menu **Đơn vị** (hoặc **Tổ chức**).
- Danh sách hiển thị dạng cây phân cấp (Bộ → Sở → Phòng, tối đa 5 cấp).
- Có thể bật **Hiển thị tất cả** (all=true) để xem toàn bộ cây.

### 2.2. Thêm / Sửa / Xóa đơn vị

- **Thêm:** Chọn **Thêm đơn vị**, nhập Mã, Tên, chọn Đơn vị cha (nếu có), lưu.
- **Sửa:** Mở đơn vị cần sửa, chỉnh Mã/Tên/trạng thái, lưu.
- **Xóa:** Chọn đơn vị (không có con và không được gán user/submission), xóa. Hệ thống có thể chặn xóa nếu còn ràng buộc.

---

## 3. Quản lý người dùng (User)

### 3.1. Xem danh sách người dùng

- Vào menu **Người dùng**.
- Danh sách hiển thị username, email, vai trò, đơn vị gán.

### 3.2. Thêm / Sửa người dùng

- **Thêm:** Chọn **Thêm người dùng**, nhập Tên đăng nhập, Mật khẩu, Email; chọn **Vai trò** (Role) và **Đơn vị** (Organization) được phép; lưu.
- **Sửa:** Mở user, chỉnh thông tin hoặc gán lại Role/Đơn vị, lưu.

### 3.3. Phân quyền

- **Vai trò (Role):** Quyết định quyền truy cập chức năng (vd. Admin, Biên tập, Duyệt).
- **Đơn vị:** Quyết định phạm vi dữ liệu (chỉ thấy/nhập báo cáo của đơn vị được gán). Kết hợp với Row-Level Security (RLS) trên database.

---

## 4. Định nghĩa biểu mẫu (Form Definition)

### 4.1. Danh sách biểu mẫu

- Vào menu **Biểu mẫu** (hoặc **Form**).
- Xem danh sách form: Mã, Tên, phiên bản đang dùng.

### 4.2. Tạo / Sửa biểu mẫu

- **Tạo:** Nhập Mã, Tên form; tạo phiên bản (version) đầu tiên.
- **Cấu hình cấu trúc:** Chọn form → Cấu hình Sheet, Cột (FormColumn), Data binding, mapping (FormColumnMapping) để gắn cột Excel với chỉ tiêu dữ liệu.

### 4.3. Phiên bản (Version)

- Mỗi form có thể có nhiều phiên bản. Khi sửa cấu trúc lớn, tạo version mới; submission gắn với formId + versionId cụ thể.

### 4.4. Cấu hình mở rộng (P8 – Dòng/Cột động)

- **Nguồn dữ liệu (DataSource):** Khai báo nguồn (bảng/view) để tạo dòng hoặc nhãn cột động.
- **Bộ lọc (FilterDefinition):** Thiết lập điều kiện lọc theo trường (vd. Tỉnh = "Hà Nội").
- **Vùng chỉ tiêu động (FormDynamicRegion):** Gắn với DataSource + Filter; dùng cho **placeholder dòng** (FormPlaceholderOccurrence): mỗi bản ghi sau khi lọc tương ứng 1 hàng trong Excel.
- **Vùng cột động (FormDynamicColumnRegion):** Gắn DataSource, cột nhãn; dùng cho **placeholder cột** (FormPlaceholderColumnOccurrence): mỗi giá trị cột nhãn tương ứng 1 cột trong Excel.
- Chi tiết kỹ thuật: [P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md), [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](de_xuat_trien_khai/KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md).

---

## 5. Kỳ báo cáo (Reporting Period)

- Vào menu **Kỳ báo cáo**.
- **Tạo kỳ:** Nhập Tên, Ngày bắt đầu, Ngày kết thúc, (tùy chọn) hạn nộp.
- **Sửa/Xóa:** Chọn kỳ, chỉnh hoặc xóa (nếu chưa có submission phụ thuộc).

---

## 6. Báo cáo và nhập liệu (Submission)

### 6.1. Tạo báo cáo (Submission)

- Chọn **Biểu mẫu**, **Phiên bản**, **Kỳ báo cáo**, **Đơn vị** (theo quyền); tạo submission.
- Có thể dùng **Tạo hàng loạt** (bulk): chọn form, version, kỳ và nhiều đơn vị → hệ thống tạo một submission cho mỗi đơn vị.

### 6.2. Nhập liệu (Excel)

- Mở submission ở trạng thái **Nháp (Draft)**.
- Hệ thống load **workbook-data** (cấu trúc sheet + cột cố định + dòng/cột động nếu có P8).
- Nhập số liệu vào ô tương ứng (giao diện dạng bảng/Excel web); **Lưu** để giữ Nháp.

### 6.3. Gửi duyệt

- Khi đã hoàn tất nhập, chọn **Gửi duyệt**. Submission chuyển trạng thái **Đã gửi (Submitted)** và tạo workflow instance chờ duyệt.

### 6.4. Upload file Excel (nếu có)

- Một số luồng cho phép upload file Excel có sẵn; hệ thống map cột và lưu vào storage. Chi tiết theo từng API (vd. POST submissions/{id}/upload).

---

## 7. Quy trình duyệt (Workflow)

### 7.1. Xem công việc cần duyệt

- **Dashboard** hoặc menu **Công việc duyệt** hiển thị danh sách báo cáo đang chờ duyệt (theo role và đơn vị).

### 7.2. Duyệt / Từ chối / Yêu cầu chỉnh sửa

- Mở submission:
  - **Duyệt (Approve):** Báo cáo chuyển trạng thái Đã duyệt; có thể chuyển cấp trên hoặc kết thúc tùy cấu hình workflow.
  - **Từ chối (Reject):** Báo cáo bị từ chối; người nộp có thể xem lý do.
  - **Yêu cầu chỉnh sửa (Revision):** Trả về Nháp; người nộp chỉnh và gửi lại.

### 7.3. Duyệt hàng loạt (Bulk approve)

- Chọn nhiều bản ghi chờ duyệt, chọn **Duyệt hàng loạt**. API xử lý từng bản; kết quả trả về danh sách thành công/thất bại.

---

## 8. Dashboard

### 8.1. Dashboard Admin

- Thống kê tổng quan: số đơn vị, số user, số form, số submission theo trạng thái, số công việc chờ duyệt.
- API: GET `/api/v1/dashboard/admin/stats` (hoặc tương đương).

### 8.2. Dashboard User

- Công việc cần làm: báo cáo nháp, báo cáo chờ duyệt, thông báo.
- API: GET `/api/v1/dashboard/user/tasks` (nếu có).

---

## 9. Xuất PDF và Thông báo

### 9.1. Xuất PDF

- Từ màn chi tiết submission (đã duyệt hoặc cho phép xem), chọn **Xuất PDF**. API GET `/api/v1/submissions/{id}/pdf` trả về file PDF; trình duyệt tải hoặc mở.

### 9.2. Thông báo

- Menu **Thông báo** hiển thị danh sách (vd. "Báo cáo X đã được duyệt", "Yêu cầu chỉnh sửa báo cáo Z").
- Đánh dấu đã đọc (PATCH read) để giảm badge chưa đọc.

---

## 10. Ghi chú chung

- **Quyền:** Một số menu/API chỉ hiển thị cho Admin hoặc role có permission tương ứng.
- **Phạm vi dữ liệu:** Kết quả list submission, dashboard được lọc theo đơn vị của user (RLS).
- **Lỗi thường gặp:** 401 → đăng nhập lại; 403 → không đủ quyền; 404 → kiểm tra id/URL. Chi tiết xem [RUNBOOK.md](RUNBOOK.md) mục Troubleshooting.

---

**Version:** 1.0  
**Ngày:** 2026-02-11
