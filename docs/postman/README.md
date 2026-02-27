# Postman – Kiểm thử thủ công API BCDT

Thư mục chứa **Postman collection** để kiểm thử thủ công API BCDT.

## File

| File | Mô tả |
|------|--------|
| `BCDT-API.postman_collection.json` | Collection chính: Auth (B1), Organizations (B4), Users (B5), Form Definitions (B7), Form Sheets/Columns/DataBinding/ColumnMapping (B8), Form Dynamic Regions (B12), **P8** (Data Sources, Filter Definitions, Placeholder dòng, Dynamic Column Regions, Placeholder cột), Submissions (gồm **workbook-data**), Report Presentations, Notifications, Workflow (B9), Reporting & Dashboard (B10), Health. |

## Cách dùng

1. **Import collection** vào Postman: File → Import → chọn file `BCDT-API.postman_collection.json`.
2. **Biến collection** (đã có sẵn):
   - `baseUrl`: mặc định `http://localhost:5080` (đổi nếu chạy API port khác).
   - `accessToken`, `refreshToken`: được set tự động sau khi chạy request **Auth → Login** (script Tests).
3. **Biến collection (path):** `formId`, `sheetId`, `columnId`, `submissionId` (mặc định 1) — dùng cho Form Definitions, Form Sheets/Columns, Submissions. Có thể sửa trong URL từng request hoặc đổi giá trị biến collection.
4. **Thứ tự kiểm tra Auth (B1):** Chạy **Login** (admin / Admin@123) → token lưu vào biến; **Me** (Bearer {{accessToken}}); **Refresh**; **Logout** → sau đó **Refresh** với token cũ kỳ vọng 401.
5. **Các nhóm API:** Auth, Organizations, Users, Form Definitions, Form Sheets, Form Columns, Form Column Data Binding, Form Column Mapping, **Form Dynamic Regions** (B12), **P8 – Nguồn dữ liệu** (data-sources, data-sources/{id}/columns), **P8 – Bộ lọc** (filter-definitions), **P8 – Vị trí placeholder (dòng)** (placeholder-occurrences theo formId/sheetId), **P8 – Vùng cột động** (dynamic-column-regions), **P8 – Vị trí placeholder cột** (placeholder-column-occurrences), Submissions (CRUD, **workbook-data**, presentation, dynamic-indicators, upload-excel, pdf), Notifications, Workflow (B9), Reporting & Dashboard (B10), Health.
6. **Biến path P8:** `formId`, `sheetId` (dùng chung Form); `regionId`, `occurrenceId` (dynamic region, placeholder dòng); `dataSourceId`, `filterDefinitionId`; `columnRegionId`, `columnOccurrenceId` (P8e). Có thể sửa trong URL hoặc đổi giá trị biến collection.

## Nếu không import được vào Postman

1. **Cập nhật Postman** lên bản mới (hỗ trợ collection v2.1): Help → Check for updates.
2. **Import bằng Raw text:** Trong Postman chọn Import → tab "Raw text" → mở file `BCDT-API.postman_collection.json` bằng editor, copy toàn bộ nội dung → dán vào ô Raw text → Continue → Import.
3. **Kiểm tra encoding:** Đảm bảo file JSON lưu dạng **UTF-8** (không BOM). Nếu mở bằng Notepad và thấy ký tự lạ ở đầu file, lưu lại với encoding UTF-8.
4. **Đường dẫn file:** Tránh đường dẫn quá dài hoặc ký tự đặc biệt; thử copy file vào thư mục ngắn (vd `C:\postman\BCDT-API.postman_collection.json`) rồi Import từ file.

## Chuẩn khi tạo/cập nhật collection

Để tránh lỗi import, khi tạo/sửa file collection cần tuân thủ chuẩn trong rule [always-verify-after-work](.cursor/rules/always-verify-after-work.mdc) mục **"Postman collection – chuẩn bắt buộc"**: có `info._postman_id`, `request.url` dạng chuỗi, JSON hợp lệ (không trailing comma), file UTF-8; sau khi ghi file chạy xác thực parse JSON (vd PowerShell `ConvertFrom-Json`) và chỉ báo Pass khi thành công.

## Cập nhật collection

Khi thêm/sửa API, AI (theo rule `always-verify-after-work` và mục "Kiểm tra cho AI" trong từng đề xuất) sẽ **tạo hoặc cập nhật** file collection trong thư mục này và báo bước "Postman collection: Pass/Fail".
