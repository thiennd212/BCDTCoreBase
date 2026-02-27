# Lưu ý nghiệp vụ: Khởi tạo cấu trúc biểu mẫu và chỉ tiêu

Tài liệu ghi lại quy ước: **ai** khởi tạo cấu trúc biểu mẫu, **cấu trúc** gồm những gì, và cách phân biệt **chỉ tiêu cố định** vs **chỉ tiêu động** (placeholder do đơn vị nhập).

---

## 1. Người thực hiện khởi tạo

- **Cấu trúc biểu mẫu** do **System Admin** khởi tạo và quản lý (không phải đơn vị hay Form Admin tùy tiện tạo cấu trúc từ đầu).

---

## 2. Cấu trúc biểu mẫu gồm những gì

Cấu trúc biểu mẫu bao gồm đầy đủ các thành phần sau:

| Thành phần | Mô tả ngắn |
|------------|------------|
| **Thông tin biểu mẫu** | Mã, tên, mô tả, loại (Input/Aggregate), chu kỳ, hạn nộp, trạng thái, v.v. |
| **Định nghĩa sheet** | Số sheet, tên sheet, thứ tự, sheet dữ liệu/không, hàng bắt đầu dữ liệu, v.v. |
| **Định nghĩa cột** | Mã cột, tên, kiểu dữ liệu, bắt buộc, chỉ đọc, validation, nhóm cột, v.v. |
| **Định nghĩa hàng** | Hàng cố định, merge, tiêu đề, v.v. (theo schema FormRow/FormCell nếu có) |
| **Công thức** | Formula cho ô/cột (Data Binding type Formula, hoặc rule công thức) |
| **Khóa (lock)** | Ô/cột được khóa hay cho phép sửa (IsEditable, lock cell trong Excel) |
| **Format & style** | Font, màu, border, merge, conditional format (TemplateDisplayJson, style trong template) |
| **Bộ lọc (data binding)** | Nguồn dữ liệu: Static, Database, API, Formula, Reference, Organization, System |
| **Ánh xạ (column mapping)** | Cột Excel → cột lưu trữ (TargetColumnName, TargetColumnIndex, AggregateFunction) |
| **Các cấu hình khác** | Theo từng phiên bản (B7, B8, script 04.form_definition.sql) |

Tài liệu kỹ thuật chi tiết: [B7_FORM_DEFINITION.md](de_xuat_trien_khai/B7_FORM_DEFINITION.md), [B8_FORM_SHEET_COLUMN_DATA_BINDING.md](de_xuat_trien_khai/B8_FORM_SHEET_COLUMN_DATA_BINDING.md).

---

## 3. Chỉ tiêu: cố định vs động (placeholder)

Đối với **cột** và **hàng**, hệ thống hỗ trợ hai cách cấu hình:

### 3.1. Chỉ tiêu cố định (cứng)

- **Ý nghĩa:** Cột/hàng được **định nghĩa sẵn** bởi System Admin trong cấu trúc biểu mẫu (mã, tên, kiểu, binding, mapping, format, khóa, …).
- **Đơn vị:** Chỉ **nhập giá trị** vào các ô tương ứng; không thêm/bớt chỉ tiêu.
- **Ví dụ:** Cột "Mã đơn vị", "Tên đơn vị", "Số lượng A", "Số lượng B", … đã được khai báo trong FormColumn + DataBinding + ColumnMapping.

### 3.2. Placeholder cho chỉ tiêu động (đơn vị tự nhập)

- **Ý nghĩa:** Một hoặc nhiều **vị trí giữ chỗ (placeholder)** trong cấu trúc biểu mẫu, dành cho **chỉ tiêu do đơn vị tự định nghĩa và nhập** (tên chỉ tiêu + giá trị, hoặc danh sách chỉ tiêu động).
- **Đơn vị:** Tại vị trí placeholder, đơn vị có thể nhập thêm tên chỉ tiêu, giá trị, hoặc mở rộng hàng/cột theo quy tắc (tùy đặc tả triển khai).
- **Ví dụ:** Một vùng "Chỉ tiêu bổ sung" (một sheet con, một block hàng/cột đặc biệt) cho phép đơn vị thêm các dòng "Tên chỉ tiêu – Giá trị" hoặc cột động.

### 3.3. Kết hợp → Biểu mẫu nhập liệu đầy đủ của đơn vị

- **Biểu mẫu nhập liệu đầy đủ** = **Phần cố định** (chỉ tiêu đã định nghĩa sẵn trong cấu trúc) + **Phần động** (các chỉ tiêu đơn vị tự nhập tại vị trí placeholder).
- System Admin khởi tạo **cấu trúc** (gồm cả vùng placeholder nếu có); đơn vị điền **giá trị** và **chỉ tiêu động** trong phạm vi cho phép.

---

## 4. Liên hệ với implementation hiện tại

| Khía cạnh | Hiện trạng (BCDT) | Ghi chú |
|-----------|-------------------|--------|
| Khởi tạo cấu trúc | FormDefinition, FormSheet, FormColumn, FormDataBinding, FormColumnMapping do API/FormConfig quản lý | Nên ràng buộc quyền: chỉ role System Admin (hoặc FormAdmin theo chính sách) được tạo/sửa cấu trúc. |
| Chỉ tiêu cố định | Mỗi FormColumn = một chỉ tiêu (cột); DataBinding + ColumnMapping = nguồn dữ liệu và ánh xạ lưu trữ | Đã có. |
| Placeholder chỉ tiêu động | FormRow/FormCell có trong schema; chưa có luồng UI/API riêng cho "một vùng placeholder chỉ tiêu động" | Có thể mở rộng: thêm loại cột/hàng "DynamicIndicator" hoặc một block placeholder (sheet/range) cho đơn vị mở rộng. |

Khi triển khai **placeholder chỉ tiêu động**, cần bổ sung đặc tả: cách lưu trữ (cột JSON, bảng con, hay mở rộng ReportDataRow), quy tắc hiển thị trên Excel web, và quyền chỉnh sửa của đơn vị.

**Giải pháp triển khai đầy đủ:** [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](de_xuat_trien_khai/GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) – phân tích, gap, data model, API, authorization, hiệu năng, kế hoạch phase.

---

**Last updated:** 2026-02-06
