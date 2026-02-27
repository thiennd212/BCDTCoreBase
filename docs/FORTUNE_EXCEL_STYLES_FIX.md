# Xử lý lỗi Export Excel – "Repairs to … / Removed: styles" (FortuneExcel)

## Vấn đề

Khi export xlsx từ [@corbe30/fortune-excel](https://github.com/corbe30/fortuneexcel), Excel báo:

- **"Excel was able to open the file by repairing or removing the unreadable content"**
- **"Removed: /xl/styles.xml part. (Styles)"**
- **"Repaired Records: Cell information from /xl/worksheets/sheet1.xml part"**

File mở được nhưng báo repair; format (màu, font, border) có thể mất.

## Giải pháp khuyến nghị (chuyên nghiệp)

**Dùng luồng export riêng bằng SheetJS (xlsx)** – tạo file .xlsx chuẩn OOXML, mở bằng Excel **không báo lỗi repair**:

- **Nút "Tải Excel (.xlsx)"** trên trang Nhập liệu (và mục tương ứng trên toolbar): gọi `downloadFortuneSheetsAsXlsx()` trong `src/bcdt-web/src/utils/exportSheetJsXlsx.ts`.
- Dữ liệu lấy từ `ref.getAllSheets()` hoặc state; chuyển sang AOA (array of arrays) rồi ghi bằng `XLSX.utils.aoa_to_sheet` / `XLSX.write` (chỉ giá trị ô, không style).
- Dependency: **xlsx** (SheetJS). File tải xuống mở bằng Excel bình thường, không repair.

Export từ plugin đã bỏ khỏi UI (không còn nút Export của plugin); chỉ dùng **Tải Excel (.xlsx)** (SheetJS) cho xlsx.

## Nguyên nhân

Chuẩn OOXML (Excel) yêu cầu màu ở dạng **ARGB 8 ký tự hex** (`AARRGGBB`). Plugin ghi màu chỉ **6 ký tự** (`RRGGBB`), nên `styles.xml` không hợp lệ và Excel xóa toàn bộ phần styles.

## Giải pháp đã áp dụng

**Hiện tại (tránh lỗi "Removed Part: styles"):** Patch **tắt hoàn toàn** fill, font, alignment và border khi export. File xlsx chỉ còn **dữ liệu ô + numFmt + merge + kích thước hàng/cột**; mở Excel không báo Repairs. Format (màu, font, border) tạm thời không xuất.

Dùng **patch** (patch-package) sửa trong `node_modules/@corbe30/fortune-excel`:

1. **ExcelConvert.js**
   - Thêm hàm `ensureArgb(hex)`: nếu `hex` 6 ký tự thì đổi thành `'FF' + hex`, đảm bảo luôn 8 ký tự.
   - Dùng `ensureArgb()` cho:
     - **fill** (màu nền ô): `fgColor.argb`
     - **font** (màu chữ): `color.argb`

2. **ExcelBorder.js**
   - Thêm hàm `ensureArgb(hex)` (chuẩn hóa hex, chỉ giữ ký tự 0-9A-Fa-f, trả về 8 ký tự uppercase).
   - Thêm `safeBorderStyle(styleMap, value)` để tránh **border style undefined** (fallback `"thin"`).
   - Dùng `ensureArgb()` cho màu border; kiểm tra `typeof info.*.color === "string"` trước khi gọi `indexOf("rgb")`.

3. **ExcelConvert.js (bổ sung)**
   - **Font name:** OOXML yêu cầu tên font là chuỗi; FortuneSheet gửi `ff` là số 0–12 → map sang tên font (hoặc `"Calibri"` nếu thiếu).
   - **Alignment:** Fallback khi `vt`/`ht`/`tb`/`tr` ngoài phạm vi để tránh giá trị `undefined` trong styles.
   - **ensureArgb:** Chỉ giữ ký tự hex, trả về chuỗi **uppercase** (một số validator Excel yêu cầu).

4. **ExcelStyle.js** – Tắt áp dụng style khi export (nguyên nhân Excel xóa toàn bộ styles.xml):
   - Không gán `target.fill`, `target.font`, `target.alignment` (chỉ giữ value, numFmt, row height, column width).

5. **ExcelFile.js** – Không gọi `setBorder(table, worksheet)` để tránh tạo thêm style/border có thể gây lỗi styles.xml.

Sau các patch trên, export xlsx từ plugin (nút Export) vẫn có thể khiến Excel báo repair (do ExcelJS tạo styles/sheet XML). **Khuyến nghị:** dùng nút **"Tải Excel (.xlsx)"** (SheetJS) để tải file chuẩn, không lỗi.

## Cách áp dụng patch trong project

- Patch được lưu tại: **`src/bcdt-web/patches/@corbe30+fortune-excel+2.2.5.patch`**
- Script **`postinstall`: `patch-package`** trong `package.json` của `bcdt-web` sẽ tự áp dụng patch sau mỗi lần `npm install`.

Nếu cài lại dependency mà chưa chạy `npm install` trong `src/bcdt-web`, cần chạy:

```bash
cd src/bcdt-web && npm install
```

để patch được áp lại.

## Đóng góp upstream

Có thể đề xuất fix này lên repo [Corbe30/FortuneExcel](https://github.com/corbe30/fortuneexcel) (issue hoặc PR) để chuẩn hóa màu ARGB 8 ký tự trong ExcelConvert và ExcelBorder, giúp mọi project dùng FortuneExcel không bị lỗi Repairs.
