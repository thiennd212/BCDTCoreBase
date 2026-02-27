# Review thiết kế: Định nghĩa biểu mẫu – Cột và hàng có từ danh mục chỉ tiêu dùng chung không?

**Ngày:** 2026-02-24  
**Phạm vi:** Cấu trúc biểu mẫu (FormDefinition, FormSheet, FormColumn, FormRow) và danh mục chỉ tiêu (IndicatorCatalog, Indicator).  
**Kết luận:** Đúng như nhận định – **cột và hàng trong định nghĩa biểu mẫu hiện đang là dữ liệu nhập trực tiếp (per-form), không bắt buộc lấy từ danh mục chỉ tiêu dùng chung.** Chỉ có **tùy chọn** tham chiếu danh mục (FormColumn.IndicatorId); hàng cố định không có “danh mục hàng”.

---

## 1. Hiện trạng thiết kế

### 1.1. Cột (FormColumn)

| Thành phần | Cách lưu | Danh mục chỉ tiêu |
|------------|----------|-------------------|
| **ColumnCode, ColumnName, ExcelColumn, DataType, …** | Nhập trực tiếp **theo từng form/sheet** (mỗi FormColumn có bộ giá trị riêng). | **Không bắt buộc** từ danh mục. |
| **FormColumn.IndicatorId** (FK → BCDT_Indicator) | **Nullable**, thêm trong B12 (R6 – tái sử dụng chỉ tiêu). | **Tùy chọn:** nếu có thì cột “gắn” với một chỉ tiêu trong danh mục; metadata (Code, Name, DataType, …) có thể copy từ Indicator khi tạo cột, nhưng vẫn lưu trong FormColumn. |

- Tạo cột mới: API/UI cho phép **(1) Tạo mới** (nhập Code, Name, DataType, … trực tiếp) hoặc **(2) Chọn từ danh mục** (gửi `indicatorId` → copy từ Indicator). **Mặc định / luồng chính hiện tại vẫn là nhập trực tiếp**, không bắt buộc chọn chỉ tiêu từ catalog.

### 1.2. Hàng (FormRow)

| Thành phần | Cách lưu | Danh mục chỉ tiêu |
|------------|----------|-------------------|
| **FormRow** (RowType, label, thứ tự, ParentRowId, FormDynamicRegionId) | Định nghĩa **theo từng sheet** (cấu hình hàng cố định hoặc hàng thuộc vùng động). | **Không có** bảng “danh mục hàng” hay “danh mục chỉ tiêu cho hàng cố định”. |
| **Vùng chỉ tiêu động (FormDynamicRegion)** | FormDynamicRegion.IndicatorCatalogId → **bắt buộc** dùng một danh mục chỉ tiêu cho **phần động** (placeholder). | **Có:** chỉ tiêu động lấy từ BCDT_Indicator theo catalog; dữ liệu theo đơn vị lưu ReportDynamicIndicator. |

- **Hàng cố định:** hoàn toàn là cấu hình nhập trực tiếp (label, thứ tự, cha-con) trên từng form/sheet, **không** tham chiếu BCDT_Indicator hay catalog.  
- **Hàng động (placeholder):** mới gắn với danh mục (IndicatorCatalog + Indicator).

---

## 2. Đối chiếu với yêu cầu

- **R6 – Tái sử dụng chỉ tiêu:** Giải pháp đã triển khai là **FormColumn.IndicatorId (tùy chọn)** và API “thêm cột từ danh mục” (indicatorId). Đúng với mô tả “tái sử dụng” (có thể chọn từ catalog), **không** yêu cầu “mọi cột phải từ danh mục”.  
- **R3 – Chỉ tiêu cố định:** Cột/hàng cố định “định nghĩa sẵn” – hiện tại được hiểu là định nghĩa **trong cấu trúc form** (FormColumn/FormRow), có thể **hoặc không** gắn với Indicator.  
- **R8/R9 – Chỉ tiêu động theo danh mục:** Chỉ áp dụng cho **vùng placeholder** (FormDynamicRegion + ReportDynamicIndicator), không áp dụng cho cột/hàng cố định.

**Kết luận:** Thiết kế hiện tại **đúng với mô tả trong** [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md): cột/hàng chủ yếu nhập trực tiếp; danh mục chỉ tiêu dùng chung cho **(1)** tùy chọn gắn cột với Indicator (R6) và **(2)** bắt buộc cho chỉ tiêu động (FormDynamicRegion).

---

## 3. Gap so với kỳ vọng “cột/hàng từ danh mục dùng chung”

Nếu nghiệp vụ kỳ vọng **phần lớn hoặc toàn bộ** cột/hàng (kể cả cố định) **phải** lấy từ danh mục chỉ tiêu dùng chung thì hiện tại có gap:

| Kỳ vọng | Hiện tại | Gap |
|---------|----------|-----|
| Cột cố định chủ yếu từ danh mục | Cột có thể tạo mới (nhập trực tiếp), IndicatorId tùy chọn | Chưa bắt buộc chọn Indicator khi tạo/sửa cột. |
| Hàng cố định từ “danh mục hàng” / chỉ tiêu | FormRow chỉ là cấu hình per-sheet, không FK tới Indicator | Không có khái niệm “danh mục hàng” hay “chỉ tiêu hàng cố định” trong schema. |

---

## 4. Đề xuất hướng xử lý (nếu muốn tăng “từ danh mục”)

1. **Cột – Ưu tiên “từ danh mục” (không đổi schema):**
   - **UI/API:** Đẩy luồng “Chọn từ danh mục chỉ tiêu” thành **luồng mặc định** khi thêm cột (vd. FormConfig: “Thêm cột” mở modal chọn Indicator trước, tạo mới thuần chỉ dành cho ngoại lệ).
   - **Ràng buộc (tùy chọn):** Có thể thêm rule nghiệp vụ: “Cột dữ liệu (DataType ≠ Header/…) bắt buộc có IndicatorId” – khi đó API validation từ chối lưu FormColumn nếu IndicatorId null (và có policy theo role).

2. **Cột – Bắt buộc Indicator (đổi schema):**
   - FormColumn.IndicatorId chuyển thành **NOT NULL** (và migration gán IndicatorId cho cột hiện có, hoặc tạo Indicator “ảo” cho từng cột cũ). Mọi cột mới sẽ phải gắn với một chỉ tiêu trong danh mục.

3. **Hàng cố định từ danh mục:**
   - Cần mở rộng thiết kế: ví dụ **FormRow.IndicatorId** (nullable, FK → BCDT_Indicator) để “hàng cố định” cũng có thể tham chiếu chỉ tiêu dùng chung; hoặc định nghĩa “danh mục hàng” (bảng riêng hoặc dùng Indicator với loại “row”). Đây là thay đổi lớn, nên làm rõ yêu cầu nghiệp vụ (hàng cố định có cần chuẩn hóa tên/đơn vị giữa nhiều form không) trước khi thiết kế chi tiết.

---

## 5. Tóm tắt

- **Đúng như review:** Trong phần định nghĩa biểu mẫu, **cột và hàng hiện đang là dữ liệu nhập trực tiếp (per-form), không bắt buộc từ danh mục chỉ tiêu dùng chung.**
- **Ngoại lệ:** (1) Cột có thể **tùy chọn** gắn với danh mục qua **FormColumn.IndicatorId**; (2) **Chỉ tiêu động** (vùng placeholder) **bắt buộc** dùng danh mục (FormDynamicRegion.IndicatorCatalogId + BCDT_Indicator).
- **Tài liệu tham chiếu:** [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) (mục 4.6 – Tái sử dụng chỉ tiêu), [REVIEW_NGHIEP_VU_MODULE_B12_CHI_TIEU_CO_DINH_DONG.md](REVIEW_NGHIEP_VU_MODULE_B12_CHI_TIEU_CO_DINH_DONG.md).
- **Bước tiếp (nếu cần):** Làm rõ với nghiệp vụ có yêu cầu “cột/hàng cố định bắt buộc từ danh mục” hay không; nếu có thì áp dụng một trong các hướng ở mục 4 (ưu tiên UI, validation, hoặc schema + FormRow.IndicatorId).
