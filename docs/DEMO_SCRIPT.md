# Demo Script – BCDT

Kịch bản demo hệ thống BCDT trên localhost, dùng cho UAT và bàn giao. Gồm **Core flow** (luồng chính) và **P8 flow** (cấu hình động dòng/cột).

**Chuẩn bị:** API + FE chạy; DB đã chạy script 01→22; seed (Ensure-TestData.ps1 hoặc seed_mcp_*). Tài khoản: admin / Admin@123.

---

## 1. Kịch bản chính (Core flow)

Thứ tự gợi ý: Login → Đơn vị → User → Form → Sheet/Column → Kỳ báo cáo → Submission (bulk) → Nhập liệu Excel → Gửi duyệt → Duyệt → Dashboard.

| Bước | Hành động | Mô tả ngắn |
|------|-----------|-------------|
| 1 | **Login** | Đăng nhập admin / Admin@123; kiểm tra redirect về trang chủ, menu hiển thị đúng. |
| 2 | **Tạo đơn vị** | Vào Đơn vị → Thêm: Mã BCDT_DEMO, Tên "Đơn vị Demo"; (tùy chọn) thêm đơn vị con. |
| 3 | **Tạo user** | Vào Người dùng → Thêm user demo; gán Role (vd. Biên tập), gán Đơn vị vừa tạo. |
| 4 | **Tạo form** | Vào Biểu mẫu → Thêm form: Mã FM_DEMO, Tên "Biểu mẫu Demo"; tạo version 1. |
| 5 | **Cấu hình sheet/column** | Mở form → Cấu hình: 1 sheet, vài cột (FormColumn), data binding / mapping (FormColumnMapping) nếu có. |
| 6 | **Tạo kỳ báo cáo** | Vào Kỳ báo cáo → Thêm: Tên "Kỳ Demo", ngày bắt đầu/kết thúc. |
| 7 | **Tạo submission (bulk)** | Chọn form FM_DEMO, version 1, kỳ vừa tạo; chọn 1 hoặc vài đơn vị → Tạo hàng loạt; kiểm tra danh sách submission Draft. |
| 8 | **Nhập liệu Excel** | Mở 1 submission Draft → Load workbook-data; nhập vài ô số liệu → Lưu. |
| 9 | **Gửi duyệt** | Trên submission vừa nhập → Gửi duyệt; kiểm tra trạng thái Submitted, workflow instance Pending. |
| 10 | **Duyệt** | Đăng nhập (hoặc chuyển role) người duyệt → Công việc duyệt → Mở submission → Duyệt (Approve); kiểm tra trạng thái Approved. |
| 11 | **Dashboard** | Vào Dashboard admin: kiểm tra thống kê (số submission, số chờ duyệt); Dashboard user: kiểm tra công việc (nếu có). |

**Kết quả mong đợi:** Toàn bộ bước thực hiện không lỗi; dữ liệu hiển thị đúng trên list và chi tiết.

---

## 2. Kịch bản mở rộng (P8 – Cấu hình động dòng/cột)

Thứ tự: Login admin → DataSource → FilterDefinition + FilterCondition → Form: FormDynamicRegion + FormPlaceholderOccurrence → FormDynamicColumnRegion + FormPlaceholderColumnOccurrence → Submission → workbook-data → Kiểm tra N hàng × M cột → Nhập liệu → Gửi duyệt.

| Bước | Hành động | Mô tả ngắn |
|------|-----------|-------------|
| 1 | **Login** | Đăng nhập admin. |
| 2 | **Tạo DataSource** | POST /api/v1/data-sources: Name, ConnectionString hoặc SourceType + TableName (tùy API); GET .../data-sources/{id}/columns → xác nhận danh sách cột. |
| 3 | **Tạo FilterDefinition** | POST filter-definitions (Name, DataSourceId); POST filter-conditions (FilterDefinitionId, ColumnName, Operator, Value) – vd. cột "Tỉnh" = "Hà Nội". |
| 4 | **Form: Vùng dòng động** | Trên form (có thể dùng FM_DEMO hoặc form mới): thêm FormDynamicRegion (SheetId, DataSourceId, FilterDefinitionId); thêm FormPlaceholderOccurrence (FormDynamicRegionId, ExcelRowStart, FilterDefinitionId). |
| 5 | **Form: Vùng cột động** | Thêm FormDynamicColumnRegion (SheetId, DataSourceId, LabelColumn, StartColumnIndex, ...); thêm FormPlaceholderColumnOccurrence (DynamicColumnRegionId, ...). |
| 6 | **Tạo submission** | Tạo submission cho form có cả placeholder dòng + cột. |
| 7 | **workbook-data** | GET /api/v1/submissions/{id}/workbook-data. **Demo:** Response có sheets[].dynamicRegions với rows (N hàng từ nguồn đã lọc); dynamicColumnRegions với columnLabels (M cột); merge đúng cột cố định + cột động. |
| 8 | **Nhập liệu** | Mở màn nhập liệu; grid hiển thị N hàng × (cột cố định + M cột động); nhập vài ô → Lưu. |
| 9 | **Gửi duyệt** | Gửi duyệt submission; kiểm tra trạng thái Submitted. |

**Kết quả mong đợi:** workbook-data trả về đúng số hàng N (từ DataSource đã lọc) và số cột M (từ label column); FE (nếu có) hiển thị đúng lưới.

---

## 3. Kịch bản edge case (tùy chọn)

| Bước | Hành động | Kỳ vọng |
|------|-----------|---------|
| 1 | Form **không** có vùng động | workbook-data chỉ có cột cố định, không có dynamicRegions/dynamicColumnRegions. |
| 2 | DataSource **0 bản ghi** | Filter trả về 0 dòng → placeholder dòng tạo 0 hàng; placeholder cột 0 nhãn → 0 cột động; API vẫn 200, structure rỗng. |

---

## 4. Chuẩn bị dữ liệu demo

- **Chung với UAT:** Dùng sample data mục 2 trong [W17_UAT_DEMO.md](de_xuat_trien_khai/W17_UAT_DEMO.md).
- **P8:** Ít nhất 1 DataSource có ≥ 5 bản ghi; 1 FilterDefinition có điều kiện; 1 form có cả FormDynamicRegion + FormPlaceholderOccurrence và FormDynamicColumnRegion + FormPlaceholderColumnOccurrence.
- Script: `docs/script_core/sql/v2/Ensure-TestData.ps1`; seed P8 theo [P8_FILTER_PLACEHOLDER.md](de_xuat_trien_khai/P8_FILTER_PLACEHOLDER.md).

---

## 5. Kiểm tra sau khi chạy demo

- [ ] Core flow: từ Login đến Dashboard, không lỗi; submission Draft → Submitted → Approved.
- [ ] P8 flow: workbook-data có N hàng và M cột động; merge cột cố định + động đúng.
- [ ] Edge case (nếu chạy): Form không động → chỉ cột cố định; DataSource 0 record → 0 hàng/0 cột động, response 200.

**Kết quả:** Điền Pass/Fail vào [W17_UAT_DEMO.md](de_xuat_trien_khai/W17_UAT_DEMO.md) mục 3 và mục 6 (test demo).

---

**Version:** 1.0  
**Ngày:** 2026-02-11
