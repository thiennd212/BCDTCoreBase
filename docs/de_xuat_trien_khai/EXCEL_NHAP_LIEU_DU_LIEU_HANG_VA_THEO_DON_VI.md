# Phương án: Xử lý dữ liệu hàng và dữ liệu theo đơn vị khi gen Excel nhập liệu

**Mục đích:** Mô tả luồng hiện tại và đề xuất cách xử lý **dữ liệu hàng** (row data) và **dữ liệu theo đơn vị** (data by organization) khi tạo/tải Excel nhập liệu tương ứng.

---

## 1. Luồng hiện tại

### 1.1 Hai nguồn “Excel nhập liệu”

| Nguồn | API / Service | Mục đích |
|-------|----------------|----------|
| **Template thuần** | `GET /api/v1/forms/{id}/template` (FormTemplateService.GetTemplateAsync) | File .xlsx mẫu từ cấu hình form (sheet, cột, optional DataBinding row 2). **Không** gắn submission/đơn vị. |
| **Workbook theo submission** | `GET /api/v1/submissions/{id}/workbook-data` (BuildWorkbookFromSubmissionService.BuildAsync) | Dữ liệu hàng (sheets + rows) để hiển thị nhập liệu cho **một submission cụ thể**. |

### 1.2 Dữ liệu hàng (row data) – hiện tại

- **Nguồn:** `BCDT_ReportDataRow` theo `SubmissionId`.
- **Cách lấy:** `BuildWorkbookFromSubmissionService.BuildAsync(submissionId)`:
  - Lấy form (sheets, columns), FormColumnMapping.
  - Lấy tất cả `ReportDataRow` của submission đó, sắp xếp theo SheetIndex, RowIndex.
  - Với mỗi sheet: chỉ lấy cột có **FormColumnMapping** (`colsWithMapping`). Mỗi ReportDataRow → một row dictionary (ExcelColumn → value) qua `SubmissionExcelServiceHelper.GetDataRowValue(row, mapping.TargetColumnName)`.
  - Nếu sheet không có ReportDataRow nào → trả về **một dòng trống** (emptyRow).
- **Ánh xạ:** FormColumn → FormColumnMapping.TargetColumnName → ReportDataRow (NumericValue1–10, TextValue1–3, DateValue1–2). Cột không có mapping **không** xuất trong workbook-data.

### 1.3 Dữ liệu theo đơn vị – hiện tại

- **ReportSubmission** có `OrganizationId`: mỗi submission đã gắn **một đơn vị**.
- **BuildAsync(submissionId)** chỉ dùng dữ liệu của submission đó → dữ liệu hàng trả về đã **theo đúng đơn vị** của submission (một submission = một đơn vị + một kỳ + một form).
- **GET template** (form template) không có khái niệm đơn vị: chỉ là mẫu cấu trúc, có thể điền DataBinding (Organization, System, …) vào row 2 khi `fillBinding=true` và truyền context (organizationId, reportingPeriodId).

---

## 2. Các điểm cần xử lý rõ ràng

### 2.1 Dữ liệu hàng

- **Cột không có FormColumnMapping:** Hiện không xuất trong workbook-data → FE/Excel có thể thiếu cột so với form. **Phương án:** duy trì “chỉ cột có mapping mới sync DB”; với workbook-data có thể mở rộng: vẫn trả về đủ cột theo form, cột không mapping để null (để hiển thị/export đủ, nhưng sync chỉ ghi các cột có mapping).
- **Số dòng mặc định khi chưa có data:** Hiện tại “0 row” → trả về 1 dòng trống. **Phương án:** cấu hình được “số dòng trống mặc định” (vd. FormSheet.DataStartRow hoặc FormDefinition.DefaultDataRowCount) để gen ra N dòng trống khi chưa có ReportDataRow.
- **Nguồn dữ liệu hàng khác (tiền kỳ, tham chiếu):** Chưa có: copy từ submission kỳ trước, hoặc từ bảng tham chiếu. **Phương án mở rộng:** tham số kiểu “sourceSubmissionId” hoặc “referencePeriodId” để BuildAsync (hoặc service khác) có thể lấy thêm hàng từ nguồn khác và merge vào workbook (chỉ khi có nhu cầu nghiệp vụ).

### 2.2 Dữ liệu theo đơn vị khi gen Excel nhập liệu

- **Trường hợp 1 – Một submission, một đơn vị (đã có):**  
  Gen Excel nhập liệu = dùng **workbook-data** của submission đó. Dữ liệu hàng đã đúng đơn vị (ReportDataRow của submission = đơn vị của submission). **Không cần đổi luồng.**

- **Trường hợp 2 – Gen nhiều file Excel theo đơn vị (bulk):**  
  Ví dụ: một form + một kỳ, gen một file Excel cho từng đơn vị (mỗi file có dữ liệu hàng của đơn vị đó). **Phương án:**  
  - API mới (vd. `POST /api/v1/reporting-periods/{periodId}/forms/{formId}/export-by-organization`) hoặc job nền: với mỗi đơn vị có submission (hoặc cần tạo submission), gọi BuildAsync(submissionId) (hoặc tạo submission rồi build), xuất file .xlsx (hoặc zip nhiều file).  
  - Hoặc FE: filter danh sách submission theo period + form, với mỗi submission gọi GET workbook-data + GET template (hoặc template-display) rồi client-side ghép và export (ít chuẩn hơn, nhưng không cần API mới).

- **Trường hợp 3 – Template “theo đơn vị” (mẫu có sẵn thông tin đơn vị):**  
  GET template với `organizationId` (và optional `reportingPeriodId`) đã có: DataBinding điền vào row 2 theo context. **Đã hỗ trợ** qua ResolveContext. Có thể bổ sung: khi tạo submission từ template, gắn luôn OrganizationId vào submission và khi mở trang nhập liệu thì workbook-data (dữ liệu hàng) vẫn từ BuildAsync(submissionId) → vẫn đúng đơn vị.

---

## 3. Đề xuất triển khai (thứ tự ưu tiên)

### Bước 1 – Chuẩn hóa dữ liệu hàng (workbook-data)

- **Mục tiêu:** Workbook-data trả về **đủ cột** theo form (mọi FormColumn của sheet), không chỉ cột có mapping. Cột không có mapping: giá trị luôn `null` (hoặc default từ FormColumn).
- **Lợi ích:** FE/Excel hiển thị đủ cột; đồng bộ/sync vẫn chỉ ghi các cột có FormColumnMapping (SyncFromPresentationService giữ nguyên logic).
- **Thay đổi:** BuildWorkbookFromSubmissionService: với mỗi sheet, build `emptyRow` và mỗi row từ ReportDataRow dựa trên **toàn bộ** columns của sheet (theo DisplayOrder); với cột không có mapping thì row[col.ExcelColumn] = null (hoặc DefaultValue nếu cần).

### Bước 2 – Dòng mặc định khi chưa có data

- **Mục tiêu:** Khi sheet chưa có ReportDataRow nào, có thể trả về **N dòng trống** (N cấu hình được) thay vì chỉ 1.
- **Cách làm:** Dùng FormSheet.DataStartRow hoặc thêm FormSheet.DefaultEmptyRowCount (hoặc FormDefinition). Trong BuildAsync, nếu sheetDataRows.Count == 0 thì tạo `DefaultEmptyRowCount` (hoặc 1 nếu không cấu hình) bản sao của emptyRow.

### Bước 3 – Gen Excel theo đơn vị (bulk)

- **Mục tiêu:** Cho một kỳ + form, gen file Excel (hoặc zip) “một file một đơn vị”, mỗi file chứa dữ liệu hàng của đơn vị đó.
- **Cách làm:**  
  - API (vd. admin): nhận periodId, formId, danh sách organizationId (hoặc lấy tất cả đơn vị có quyền). Với mỗi đơn vị: tìm hoặc tạo ReportSubmission, gọi BuildAsync(submissionId), kết hợp với template (hoặc template-display) để tạo file .xlsx, trả về stream hoặc đưa vào zip.  
  - Hoặc job nền: tạo submission cho từng đơn vị (nếu chưa có), build workbook từng cái, xuất file lưu/minio hoặc gửi link.

---

## 4. Tóm tắt

| Nội dung | Hiện trạng | Phương án đề xuất |
|----------|------------|-------------------|
| **Dữ liệu hàng** | Chỉ cột có FormColumnMapping; 0 row → 1 dòng trống. | Trả về đủ cột theo form (cột không mapping = null); cấu hình số dòng trống mặc định khi chưa có data. |
| **Dữ liệu theo đơn vị** | Mỗi submission = một đơn vị; BuildAsync(submissionId) = dữ liệu đúng đơn vị. | Giữ nguyên; bổ sung API/job “gen Excel theo đơn vị” (nhiều file) khi cần. |
| **Template + đơn vị** | GET template với organizationId/reportingPeriodId đã điền DataBinding. | Giữ nguyên; đảm bảo khi mở nhập liệu luôn dùng workbook-data của submission (đã đúng đơn vị). |

---

**Tài liệu liên quan:** B8 (Form Sheet Column Data Binding), BuildWorkbookFromSubmissionService, SyncFromPresentationService, FormColumnMapping, ReportDataRow.
