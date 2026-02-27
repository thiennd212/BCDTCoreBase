# Kiểm tra cho AI – Header Excel nhiều tầng (N tầng)

## Mục đích
Xác nhận header Excel hỗ trợ 1–4 tầng nhóm (ColumnGroupName + ColumnGroupLevel2/3/4), merge đúng, sync đúng số hàng header.

## Điều kiện
- Đã chạy migration: `17.add_form_column_group_levels.sql`, (tùy chọn) `18.update_test_excel_full_header_levels.sql`.
- Form TEST_EXCEL_FULL có ít nhất 1 submission (seed_mcp_2 hoặc Ensure-TestData.ps1).
- API chạy tại http://localhost:5080.

## Test cases

### TC-01: API columns trả về đủ trường Level2, Level3, Level4
- **Request:** GET `/api/v1/forms/{formId}/sheets/{sheetId}/columns` với Bearer token.
- **Kỳ vọng:** 200; mỗi phần tử trong `data` có `columnGroupName`, `columnGroupLevel2`, `columnGroupLevel3`, `columnGroupLevel4` (có thể null).
- **Lệnh (PowerShell):** Sau khi Login lấy token, gọi `Invoke-RestMethod -Uri "$base/api/v1/forms/5/sheets/7/columns" -Headers @{ Authorization = "Bearer $token" }` (formId/sheetId thay bằng id thực tế của TEST_EXCEL_FULL).

### TC-02: GET workbook-data – submission form TEST_EXCEL_FULL
- **Request:** GET `/api/v1/submissions/{submissionId}/workbook-data` với submission thuộc form TEST_EXCEL_FULL.
- **Kỳ vọng:** 200; `data.sheets` có ít nhất 1 sheet, `sheets[0].rows` có dữ liệu.
- **Ghi chú:** Số hàng header (1–5) do FE tính từ columns khi build FortuneSheet; backend chỉ trả rows (không build header).

### TC-03: Màn nhập liệu – header 3 tầng hiển thị đúng
- **Thao tác:** Vào `/submissions/{id}/entry` với submission form TEST_EXCEL_FULL (có ColumnGroupName + ColumnGroupLevel2).
- **Kỳ vọng:** Sheet hiển thị 3 hàng header: hàng 0 = nhóm tầng 1 (Thong tin chung / So lieu), hàng 1 = nhóm tầng 2 (Dinh danh / Chi tiet), hàng 2 = tên cột; merge ô đúng theo từng tầng.

### TC-04: Đồng bộ (sync) bỏ qua đủ số hàng header
- **Thao tác:** Trên màn entry, sửa vài ô dữ liệu → Đồng bộ. Gọi API PUT presentation hoặc dùng nút Đồng bộ.
- **Kỳ vọng:** SyncFromPresentationService dùng `GetHeaderRowCount` = 3 (với form có Level2); chỉ dòng từ hàng 3 trở đi được đọc vào ReportDataRow; không lỗi.

### TC-05: FormConfigPage – sửa cột có Nhóm tầng 2, 3, 4
- **Thao tác:** Vào Cấu hình biểu mẫu → chọn sheet → Sửa một cột, nhập "Nhóm header tầng 1", "Nhóm header tầng 2" → Cập nhật.
- **Kỳ vọng:** 200; GET lại columns thấy `columnGroupName`, `columnGroupLevel2` đúng giá trị đã nhập.

## Lệnh kiểm tra nhanh (PowerShell, API đang chạy)

```powershell
$base = "http://localhost:5080"
$login = Invoke-RestMethod -Uri "$base/api/v1/auth/login" -Method POST -Body '{"Username":"admin","Password":"Admin@123"}' -ContentType "application/json"
$h = @{ Authorization = "Bearer $($login.data.accessToken)" }
# Form TEST_EXCEL_FULL: formId=5, sheetId=7 (tra DB)
$cols = Invoke-RestMethod -Uri "$base/api/v1/forms/5/sheets/7/columns" -Headers $h -Method GET
$cols.data[0] | Format-List columnGroupName, columnGroupLevel2, columnGroupLevel3, columnGroupLevel4
# Kỳ vọng: columnGroupLevel2 có giá trị (vd "Dinh danh" hoặc "Chi tiet")
```

## Kết quả cần báo
- TC-01: Pass / Fail (ghi lỗi nếu Fail).
- TC-02: Pass / Fail.
- TC-03: Pass / Fail (kiểm tra thủ công hoặc E2E).
- TC-04: Pass / Fail (sau khi Đồng bộ, query ReportDataRow kiểm tra RowIndex bắt đầu từ headerRowCount+1).
- TC-05: Pass / Fail.
