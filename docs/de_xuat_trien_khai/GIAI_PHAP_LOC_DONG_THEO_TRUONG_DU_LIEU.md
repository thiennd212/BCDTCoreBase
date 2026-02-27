# Giải pháp tổng thể: Lọc động theo các trường dữ liệu (điều kiện lọc trên cột nguồn)

**Mục đích:** Thiết kế cơ chế **lọc động** cho vùng chỉ tiêu động (và nguồn hàng) không chỉ theo **đơn vị**, **catalog**, mà theo **nhiều điều kiện trên các cột** của bảng/nguồn dữ liệu. **Một placeholder = một dòng** trên template (đặt điều kiện cho placeholder đó); **nhiều placeholder** trên template và **một placeholder có thể lặp lại nhiều lần** với điều kiện giống hoặc khác nhau. Chỉ tiêu cố định hoặc động đều có thể xuất hiện nhiều lần trên Excel để nhập liệu. Tài liệu để **duyệt** trước khi đưa vào GIAI_PHAP chính thức và triển khai.

**Ngày:** 2026-02-06.  
**Tham chiếu:** [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md). Ý nghĩa vùng chỉ tiêu động & trạng thái: [KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md](KE_HOACH_CAU_HINH_BIEU_MAU_MO_RONG.md) mục 1–2.

---

## 1. Yêu cầu nghiệp vụ và nguyên tắc thiết kế

### 1.1. Cách tạo template (quan trọng)

- **Khi tạo template:** Chỉ thêm **một dòng** cho mỗi placeholder và đặt **điều kiện** cho placeholder đó.
- **Nhiều placeholder** trên template: nhiều vị trí (nhiều dòng) độc lập, mỗi vị trí có thể gắn nguồn và bộ lọc riêng.
- **Một placeholder có thể lặp lại nhiều lần** trên template: cùng định nghĩa placeholder (nguồn, kiểu hiển thị) nhưng đặt ở nhiều dòng khác nhau; **điều kiện** tại mỗi lần xuất hiện có thể **giống hoặc khác nhau**.
- **Chỉ tiêu cố định hoặc động** đều có thể **xuất hiện nhiều lần** trên Excel để nhập liệu (cùng chỉ tiêu, nhiều vị trí, mỗi vị trí có thể có bộ lọc riêng).

**Không** dùng mô hình “chia một vùng thành nhiều khoảng dòng (vd 1–10, 11–15, 16+) với mỗi khoảng một bộ lọc”. Thay vào đó: **mỗi dòng placeholder trên template = một vị trí (occurrence)** với **một** bộ lọc; khi gen Excel, dòng đó **mở rộng** thành 0..N hàng tùy kết quả truy vấn nguồn theo điều kiện.

### 1.2. Ví dụ (minh họa)

- **Placeholder A** (nguồn = dự án): đặt ở **dòng 5** với điều kiện *Ngày ban hành &lt; ReportDate và Tổng mức &gt; 10 tỷ* → khi gen, dòng 5 mở rộng thành N hàng (N = số dự án thỏa điều kiện).
- **Placeholder A** (cùng định nghĩa) đặt lại ở **dòng 20** với điều kiện *IsNew = 1* → dòng 20 mở rộng thành M hàng (M = số dự án mới).
- **Placeholder A** đặt ở **dòng 30** với điều kiện *HasAdjustment = 1* → dòng 30 mở rộng thành K hàng.

**Ràng buộc:** Điều kiện lọc phải cấu hình được **theo trường dữ liệu** (tên cột, toán tử, giá trị literal hoặc tham số), **không hard-code** trong code.

### 1.3. Yêu cầu đối xứng cho cột

**Yêu cầu:** Khi cấu hình **cột** cũng đảm bảo việc **cấu hình placeholder** và **điều kiện lọc** tương tự như dòng.

- **Placeholder cột:** Cho phép khai báo “vùng cột động”: số cột và nhãn cột **không cố định** lúc tạo template, mà xác định khi **gen Excel cho từng đơn vị** (theo tham chiếu: kỳ báo cáo, danh mục tháng/quý, catalog, hoặc nguồn có lọc).
- **Điều kiện lọc cho cột:** Mỗi **vị trí placeholder cột** có thể gắn **một bộ lọc** (FilterDefinition) – cùng cơ chế điều kiện theo trường (Field, Operator, Value) và tham số (ReportDate, OrganizationId, …) như placeholder dòng. Ví dụ: chỉ sinh cột các tháng thuộc kỳ báo cáo, hoặc chỉ cột thỏa điều kiện trên danh mục kỳ.
- **Đối xứng với dòng:** Một định nghĩa placeholder cột có thể được **đặt nhiều lần** trên template (nhiều vị trí cột); mỗi vị trí có **một** bộ lọc, có thể giống hoặc khác nhau. Khi gen: resolve bộ lọc + nguồn cột → 0..N cột tại vị trí đó.

---

## 2. Giải pháp tổng thể

### 2.1. Các thành phần chính

| Thành phần | Vai trò |
|------------|--------|
| **Định nghĩa placeholder dòng (FormDynamicRegion)** | Mô tả **một loại** placeholder **hàng**: nguồn (DataSource hoặc Catalog), DisplayColumn, ValueColumn. **Một định nghĩa** có thể **đặt nhiều lần** (FormPlaceholderOccurrence), mỗi vị trí một FilterDefinition. |
| **Vị trí placeholder dòng (FormPlaceholderOccurrence)** | **Một dòng** trên template = một lần xuất hiện. **ExcelRowStart**, FormDynamicRegionId, **FilterDefinitionId**. Khi gen: truy vấn nguồn theo bộ lọc → 0..N bản ghi → **mở rộng** thành N hàng. |
| **Định nghĩa placeholder cột (FormDynamicColumnRegion)** | Mô tả **một loại** placeholder **cột** (đối xứng với dòng): ColumnSourceType (ByReportingPeriod, ByCatalog, ByDataSource), ColumnSourceRef, LabelColumn. **Một định nghĩa** có thể **đặt nhiều lần** (FormPlaceholderColumnOccurrence), mỗi vị trí một FilterDefinition. |
| **Vị trí placeholder cột (FormPlaceholderColumnOccurrence)** | **Một vị trí cột** trên template = ExcelColStart, FormDynamicColumnRegionId, **FilterDefinitionId**. Khi gen: resolve filter + nguồn cột → 0..N cột tại vị trí đó. |
| **Nguồn dữ liệu (DataSource)** | Bảng/view/API cung cấp danh sách bản ghi (hàng) hoặc dùng cho nguồn cột (catalog). FilterDefinition dùng chung cho cả hàng và cột. |
| **Định nghĩa bộ lọc (FilterDefinition)** | Điều kiện lọc (Field, Operator, ValueType, Value). **Tái sử dụng** cho **cả vị trí placeholder dòng và vị trí placeholder cột** – mỗi vị trí gắn một FilterDefinitionId. |
| **Ngữ cảnh tham số (Parameter Context)** | Khi build workbook: ReportDate, OrganizationId, SubmissionId, ReportingPeriodId, CurrentDate, CatalogId. Dùng khi resolve filter cho cả hàng và cột. |

### 2.2. Luồng xử lý (khi build workbook / load dữ liệu cho submission)

1. **Xác định ngữ cảnh:** Lấy ReportDate, OrganizationId, ReportingPeriodId, … từ submission / kỳ báo cáo.
2. **Theo từng vị trí placeholder (occurrence)** trên sheet (sắp xếp theo ExcelRowStart để điền đúng thứ tự):
   - **Resolve bộ lọc** của vị trí này: thay tham số trong FilterDefinition bằng giá trị thực.
   - **Truy vấn nguồn** (theo định nghĩa placeholder) với WHERE tương đương bộ lọc → danh sách 0..N bản ghi.
   - **Điền hàng:** Bắt đầu từ **ExcelRowStart** (một dòng trên template), điền N hàng (mỗi hàng = một bản ghi). Cột "Tên chỉ tiêu" / "Giá trị" theo DisplayColumn, ValueColumn. Có thể giới hạn MaxRows nếu cấu hình.
3. **Nhiều vị trí:** Mỗi vị trí độc lập; vị trí sau có ExcelRowStart nằm sau vùng đã điền của vị trí trước (hoặc quy ước tính lại offset khi có mở rộng hàng).
4. **Gộp với dữ liệu đã nhập:** Nếu đơn vị đã chỉnh/sửa (ReportDynamicIndicator), merge theo chính sách (ưu tiên nguồn pre-fill hay ưu tiên dữ liệu đã lưu).

---

## 3. Mô hình dữ liệu đề xuất

### 3.1. Nguồn dữ liệu (DataSource) – mở rộng hoặc bảng mới

Dùng cho “hàng động từ nguồn có lọc”. Có thể gắn với **catalog** (chỉ tiêu từ BCDT_Indicator) hoặc **bảng/view nghiệp vụ** (vd BCDT_Project).

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| Code | NVARCHAR(50) NOT NULL | Mã nguồn (vd PROJECT_LIST, DM_DU_AN) |
| Name | NVARCHAR(200) NOT NULL | Tên hiển thị |
| SourceType | NVARCHAR(20) NOT NULL | `Catalog` \| `Table` \| `View` \| `API` |
| SourceRef | NVARCHAR(500) NULL | Tên bảng/view (vd BCDT_Project) hoặc URL/key API; với Catalog = để trống hoặc IndicatorCatalogId |
| IndicatorCatalogId | INT NULL | FK → BCDT_IndicatorCatalog (khi SourceType = Catalog, dùng catalog làm nguồn; có thể join bảng mở rộng nếu catalog gắn với bảng dự án) |
| DisplayColumn | NVARCHAR(100) NULL | Cột dùng làm "Tên chỉ tiêu" khi điền hàng (vd ProjectName, Name) |
| ValueColumn | NVARCHAR(100) NULL | Cột dùng làm "Giá trị" mặc định (có thể null; đơn vị nhập sau) |
| IsActive | BIT NOT NULL DEFAULT 1 | |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | | Audit |

- **Ràng buộc:** Nếu SourceType = Table/View thì SourceRef bắt buộc; schema (danh sách cột) lấy từ DB hoặc cấu hình để dùng trong FilterDefinition.

### 3.2. Vị trí placeholder (FormPlaceholderOccurrence) – một dòng trên template, có thể lặp nhiều lần

**Không** dùng “đoạn vùng” (khoảng RowStart–RowEnd). Mỗi **vị trí** = **một dòng** trên template (một placeholder được đặt tại một hàng), gắn **một** bộ lọc. Cùng một định nghĩa placeholder (FormDynamicRegion) có thể xuất hiện **nhiều lần** (nhiều bản ghi FormPlaceholderOccurrence), mỗi lần điều kiện có thể giống hoặc khác nhau.

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| FormSheetId | INT NOT NULL | FK → BCDT_FormSheet (sheet chứa vị trí này) |
| FormDynamicRegionId | INT NOT NULL | FK → BCDT_FormDynamicRegion (định nghĩa placeholder; có thể trùng nhau cho nhiều vị trí) |
| **ExcelRowStart** | **INT NOT NULL** | **Hàng (1-based) tại đó placeholder xuất hiện trên template. Chỉ một dòng;** khi gen, dòng này **mở rộng** thành 0..N hàng tùy kết quả truy vấn nguồn. |
| FilterDefinitionId | INT NULL | FK → FilterDefinition (bộ lọc cho **vị trí này**); NULL = không lọc (lấy tất cả theo RLS/scope) |
| DataSourceId | INT NULL | FK → DataSource; NULL = dùng nguồn từ FormDynamicRegion (catalog/nguồn mặc định) |
| DisplayOrder | INT NOT NULL | Thứ tự khi duyệt các vị trí (để tính offset hàng sau khi mở rộng; vị trí trước mở rộng → vị trí sau bắt đầu từ hàng tiếp theo) |
| MaxRows | INT NULL | Số dòng tối đa khi mở rộng (0 = không giới hạn hoặc theo cấu hình region) |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | | Audit |

- **Ví dụ:** Trên sheet có 3 vị trí cùng dùng FormDynamicRegionId = “Dự án”: (1) ExcelRowStart=5, FilterDefinitionId=F1 (ngày VB &lt; ReportDate, tổng mức &gt; 10 tỷ); (2) ExcelRowStart=20, FilterDefinitionId=F2 (IsNew=1); (3) ExcelRowStart=30, FilterDefinitionId=F3 (HasAdjustment=1). Khi gen: dòng 5 → N hàng; dòng 20 → M hàng; dòng 30 → K hàng (N, M, K từ truy vấn).

### 3.3. Định nghĩa bộ lọc (FilterDefinition)

Một bộ lọc có thể **tái sử dụng** (nhiều vị trí placeholder dùng chung). Lưu dạng **cấu trúc** (bảng con điều kiện) hoặc **JSON** (linh hoạt, dễ mở rộng). Đề xuất: **bảng + bảng con** để query và validate rõ ràng.

**Bảng chính: BCDT_FilterDefinition**

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| Code | NVARCHAR(50) NOT NULL | Mã bộ lọc (vd DU_AN_NGAY_VB_TONG_MUC) |
| Name | NVARCHAR(200) NOT NULL | Tên hiển thị |
| LogicalOperator | NVARCHAR(3) NOT NULL | `AND` \| `OR` (gộp tất cả điều kiện con) |
| DataSourceId | INT NULL | FK → DataSource (bộ lọc áp dụng cho nguồn nào; optional, có thể suy từ vị trí placeholder) |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | | Audit |

**Bảng con: BCDT_FilterCondition**

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| FilterDefinitionId | INT NOT NULL | FK → BCDT_FilterDefinition |
| ConditionOrder | INT NOT NULL | Thứ tự điều kiện (để AND/OR đúng thứ tự nếu cần) |
| **Field** | **NVARCHAR(100) NOT NULL** | **Tên cột/trường trong nguồn dữ liệu** (vd DocumentIssueDate, TotalInvestment, IsNew, HasAdjustment) |
| **Operator** | **NVARCHAR(20) NOT NULL** | **Toán tử:** Eq, Ne, Lt, Le, Gt, Ge, In, NotIn, Contains, StartsWith, EndsWith, IsNull, IsNotNull, Between |
| **ValueType** | **NVARCHAR(20) NOT NULL** | `Literal` \| `Parameter` |
| **Value** | **NVARCHAR(500) NULL** | Giá trị: nếu Literal thì giá trị so sánh (vd 10000000000, 1, 'A'); nếu Parameter thì **tên tham số** (vd ReportDate, OrganizationId, CurrentDate) |
| Value2 | NVARCHAR(500) NULL | Dùng cho Between (giá trị thứ hai) |
| CreatedAt, CreatedBy | | Audit |

**Ví dụ điều kiện (một vị trí placeholder – dự án có ngày VB &lt; ReportDate và tổng mức &gt; 10 tỷ):**

- Điều kiện 1: Field = `DocumentIssueDate`, Operator = `Lt`, ValueType = `Parameter`, Value = `ReportDate`.
- Điều kiện 2: Field = `TotalInvestment`, Operator = `Gt`, ValueType = `Literal`, Value = `10000000000`.
- LogicalOperator = `AND`.

**Ví dụ điều kiện (vị trí khác – chỉ dự án mới):** Field = `IsNew`, Operator = `Eq`, ValueType = `Literal`, Value = `1`.

**Ví dụ điều kiện (vị trí khác – chỉ dự án có điều chỉnh):** Field = `HasAdjustment`, Operator = `Eq`, ValueType = `Literal`, Value = `1`.

### 3.4. Tham số chuẩn (Parameter Context)

Khi **resolve** bộ lọc và truy vấn nguồn, hệ thống cung cấp ít nhất các tham số sau (tên dùng trong FilterCondition.Value khi ValueType = Parameter):

| Tham số | Nguồn | Mô tả |
|---------|--------|--------|
| **ReportDate** | Ngày lập báo cáo (từ ReportingPeriod hoặc submission) | Ngày dùng so sánh với cột ngày (vd ngày ban hành văn bản) |
| **OrganizationId** | ReportSubmission.OrganizationId | Đơn vị nộp báo cáo (lọc theo đơn vị nếu nguồn có cột này) |
| **SubmissionId** | ReportSubmission.Id | ID báo cáo (ít dùng trong lọc, có thể dùng cho audit) |
| **ReportingPeriodId** | ReportSubmission.ReportingPeriodId | Kỳ báo cáo |
| **CurrentDate** | DateTime.UtcNow (hoặc server date) | Ngày hiện tại |
| **UserId** | User đang thực hiện | (tùy chọn) |
| **CatalogId** | FormDynamicRegion.IndicatorCatalogId | Danh mục chỉ tiêu gắn với vùng (nếu cần) |

Mở rộng sau: tham số tùy chỉnh từ FormDefinition (vd dropdown “Nhóm dự án”) lưu trong submission → đưa vào context.

### 3.5. Kiểu dữ liệu và ép kiểu khi so sánh

- **Literal:** Chuỗi lưu trong Value; khi build WHERE cần **ép kiểu** theo kiểu cột nguồn (số, ngày, bit). Có thể lưu thêm **DataType** (Number, Date, Boolean, Text) trong FilterCondition để engine ép đúng.
- **Parameter:** ReportDate, CurrentDate → Date; OrganizationId, SubmissionId, … → number; giá trị lấy từ context, ép kiểu theo cột đích.

Đề xuất: thêm cột **FilterCondition.DataType** (optional): `Text`, `Number`, `Date`, `Boolean` để khi ValueType = Literal thì ép Value sang đúng kiểu trước khi so sánh.

---

## 4. Luồng kỹ thuật (Build workbook / Load dữ liệu)

### 4.1. Khi build workbook (GET workbook-data hoặc export Excel)

1. Lấy **Parameter Context** từ submission (ReportDate, OrganizationId, ReportingPeriodId, …).
2. Lấy danh sách **vị trí placeholder** (FormPlaceholderOccurrence) của sheet, sắp theo **DisplayOrder** (hoặc ExcelRowStart). Với mỗi vị trí:
   - Lấy **FormDynamicRegion** (định nghĩa) và **FilterDefinition** (của vị trí này).
   - **Resolve filter:** Thay tham số trong FilterCondition bằng giá trị từ context; Literal ép kiểu theo DataType.
   - **Build WHERE** (whitelist cột, parameterized) và **truy vấn DataSource** (hoặc nguồn từ region) → danh sách 0..N bản ghi. Giới hạn theo MaxRows nếu có.
   - **Điền hàng:** Bắt đầu từ **ExcelRowStart** (một dòng), điền **N hàng** (mỗi hàng = một bản ghi). Cột "Tên chỉ tiêu" = DisplayColumn, "Giá trị" = ValueColumn hoặc để trống. Sau khi điền, **offset hàng** cho các vị trí tiếp theo có thể cộng thêm N (nếu template tính hàng động).
3. **Merge với ReportDynamicIndicator** theo chính sách (ưu tiên nguồn pre-fill hay dữ liệu đã lưu).

### 4.2. Khi sync từ Excel về (PUT presentation → sync)

- Giữ nguyên logic hiện tại: đọc vùng placeholder (theo ExcelRowStart, ExcelColName, ExcelColValue) từ WorkbookJson → ghi ReportDynamicIndicator. **Không** cần resolve filter khi sync (filter chỉ dùng khi **sinh hàng** từ nguồn).

### 4.3. Khi đơn vị mở trang nhập liệu (SubmissionDataEntryPage)

- **Lần đầu (chưa có ReportDynamicIndicator):** Có thể gọi API **prefill** (vd GET submissions/{id}/dynamic-indicators/prefill) với Parameter Context → backend resolve filter **từng vị trí placeholder**, query nguồn → trả về danh sách hàng gợi ý (theo từng vị trí) → FE hiển thị và cho phép sửa; khi "Lưu chỉ tiêu động" thì PUT dynamic-indicators.
- **Đã có dữ liệu:** Load ReportDynamicIndicator như hiện tại; không cần prefill lại (hoặc cho phép "Làm mới từ nguồn" để gọi prefill lại).

---

## 4a. Placeholder cột và điều kiện lọc cho cột (đối xứng với dòng)

Đáp ứng yêu cầu 1.3: cấu hình cột cũng có **placeholder** và **điều kiện lọc** tương tự như dòng.

### 4a.1. Định nghĩa placeholder cột (FormDynamicColumnRegion)

Mô tả **một loại** placeholder cột: nguồn sinh cột (theo kỳ, danh mục, catalog), quy tắc nhãn cột. **Một định nghĩa** có thể được **đặt nhiều lần** trên template (nhiều vị trí cột), mỗi vị trí gắn **một** bộ lọc.

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| FormSheetId | INT NOT NULL | FK → BCDT_FormSheet |
| Code | NVARCHAR(50) NOT NULL | Mã (vd COL_BY_PERIOD, COL_BY_MONTH) |
| Name | NVARCHAR(200) NOT NULL | Tên hiển thị (vd "Cột theo tháng trong kỳ") |
| **ColumnSourceType** | **NVARCHAR(30) NOT NULL** | `ByReportingPeriod` \| `ByCatalog` \| `ByDataSource` \| `Fixed` – nguồn sinh danh sách cột khi gen |
| **ColumnSourceRef** | **NVARCHAR(500) NULL** | ReportingPeriodId, IndicatorCatalogId, DataSourceId (hoặc rule name); với ByReportingPeriod có thể để trống (lấy từ submission) |
| LabelColumn | NVARCHAR(100) NULL | Cột nguồn dùng làm nhãn header (vd MonthName, PeriodLabel); với ByReportingPeriod có thể dùng rule "T1","T2",… |
| DisplayOrder | INT NOT NULL | Thứ tự khi duyệt vùng cột động |
| IsActive | BIT NOT NULL DEFAULT 1 | |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | | Audit |

- **ByReportingPeriod:** Resolve từ submission → kỳ báo cáo → danh sách tháng/quý (số cột + nhãn). Có thể dùng FilterDefinition trên bảng “danh mục kỳ” để lọc cột (vd chỉ tháng trong kỳ).
- **ByCatalog / ByDataSource:** Truy vấn nguồn (catalog hoặc DataSource); **FilterDefinition** gắn tại **vị trí** (FormPlaceholderColumnOccurrence) lọc bản ghi nào được sinh thành cột.

### 4a.2. Vị trí placeholder cột (FormPlaceholderColumnOccurrence)

**Một cột** trên template = một vị trí (sau cột X, placeholder cột xuất hiện tại đây). Khi gen: vị trí này **mở rộng** thành 0..N cột. Cùng định nghĩa (FormDynamicColumnRegion) có thể xuất hiện **nhiều lần** (nhiều bản ghi), mỗi lần **một** bộ lọc.

| Cột | Kiểu | Mô tả |
|-----|------|--------|
| Id | INT IDENTITY | PK |
| FormSheetId | INT NOT NULL | FK → BCDT_FormSheet |
| FormDynamicColumnRegionId | INT NOT NULL | FK → FormDynamicColumnRegion (định nghĩa placeholder cột) |
| **ExcelColStart** | **INT NOT NULL** | Cột bắt đầu (1-based) hoặc **ExcelColName** (vd "E") – tại đó placeholder cột xuất hiện; khi gen, **mở rộng** thành 0..N cột. |
| **FilterDefinitionId** | **INT NULL** | FK → BCDT_FilterDefinition (bộ lọc cho **vị trí này**); NULL = không lọc (lấy tất cả theo nguồn). **Tái sử dụng** cùng cơ chế FilterDefinition như placeholder dòng. |
| DisplayOrder | INT NOT NULL | Thứ tự khi duyệt vị trí cột (để tính offset cột sau khi mở rộng) |
| MaxColumns | INT NULL | Số cột tối đa khi mở rộng (0 = không giới hạn) |
| CreatedAt, CreatedBy, UpdatedAt, UpdatedBy | | Audit |

- **Ví dụ:** FormDynamicColumnRegion "Cột theo tháng": ColumnSourceType = ByReportingPeriod. Hai vị trí: (1) ExcelColStart = 5, FilterDefinitionId = F1 (chỉ tháng Q1); (2) ExcelColStart = 15, FilterDefinitionId = F2 (chỉ tháng Q2). Khi gen: cột 5 → 3 cột T1,T2,T3; cột 15 → 3 cột T4,T5,T6.

### 4a.3. Luồng build workbook (cột động)

1. **Parameter Context** từ submission (như hiện tại).
2. Lấy danh sách **vị trí placeholder cột** (FormPlaceholderColumnOccurrence) của sheet, sắp theo DisplayOrder / ExcelColStart.
3. Với mỗi vị trí:
   - Lấy **FormDynamicColumnRegion** và **FilterDefinition** (của vị trí này).
   - **Resolve filter:** Thay tham số bằng giá trị từ context (cùng engine FilterDefinition như dòng).
   - **Resolve nguồn cột:** Theo ColumnSourceType – ByReportingPeriod: lấy kỳ từ submission → danh sách (Label, Order); ByCatalog/ByDataSource: query nguồn với WHERE theo bộ lọc đã resolve → danh sách (Label, Order). Giới hạn MaxColumns nếu có.
   - **Sinh cột:** Tại **ExcelColStart** (một cột trên template), sinh **N cột** (header + ô trống hoặc mapping). Offset cột cho vị trí tiếp theo cộng thêm N.
4. **Merge với FormColumn cố định:** Cột cố định và cột động được sắp theo thứ tự (DisplayOrder, vị trí) để tạo danh sách cột cuối cùng cho sheet.

### 4a.4. FE – Cấu hình placeholder cột (đối xứng với dòng)

- **FormConfig – block "Vùng cột động":** Danh sách **định nghĩa placeholder cột** (FormDynamicColumnRegion) theo sheet: Code, Name, ColumnSourceType, ColumnSourceRef, LabelColumn. Nút "Thêm định nghĩa".
- **FormConfig – block "Vị trí placeholder cột":** Danh sách **vị trí** (FormPlaceholderColumnOccurrence): ExcelColStart (hoặc tên cột), chọn **Định nghĩa placeholder cột**, chọn **Bộ lọc** (FilterDefinition – dropdown chung với placeholder dòng). Cùng định nghĩa có thể thêm nhiều vị trí, mỗi vị trí một bộ lọc (giống hoặc khác).
- **Tái sử dụng:** Cùng **FilterDefinition** và **DataSource** dùng cho cả placeholder dòng và placeholder cột; chỉ khác bảng/vị trí (FormPlaceholderOccurrence vs FormPlaceholderColumnOccurrence) và luồng (mở rộng hàng vs mở rộng cột).

---

## 5. API gợi ý

| Method | Route | Mô tả |
|--------|--------|--------|
| GET / POST | /api/v1/data-sources | Danh sách / tạo nguồn dữ liệu (Table, View, Catalog, API) |
| GET / PUT / DELETE | /api/v1/data-sources/{id} | Chi tiết / cập nhật / xóa |
| GET | /api/v1/data-sources/{id}/columns | Metadata cột (để cấu hình filter và mapping) – có thể từ sys.columns hoặc cấu hình |
| GET / POST | /api/v1/filter-definitions | Danh sách / tạo bộ lọc |
| GET / PUT / DELETE | /api/v1/filter-definitions/{id} | Chi tiết / cập nhật / xóa (kèm conditions) |
| GET / POST | /api/v1/forms/{formId}/sheets/{sheetId}/placeholder-occurrences | Danh sách / tạo vị trí placeholder (FormDynamicRegionId, ExcelRowStart, FilterDefinitionId, DataSourceId, DisplayOrder, MaxRows) – mỗi bản ghi = một dòng trên template |
| GET / PUT / DELETE | /api/v1/forms/{formId}/sheets/{sheetId}/placeholder-occurrences/{id} | Chi tiết / cập nhật / xóa vị trí placeholder |
| GET | /api/v1/submissions/{id}/dynamic-indicators/prefill | (Tùy chọn) Pre-fill từ nguồn theo từng vị trí placeholder + filter; body/query có thể truyền override params |

---

## 6. Giao diện cấu hình (FE – FormConfig)

- **Vùng chỉ tiêu động (đã có):** Giữ block hiện tại (FormDynamicRegion: ExcelRowStart, ExcelColName, ExcelColValue, MaxRows, IndicatorCatalogId, IndicatorExpandDepth) – đây là **định nghĩa** một loại placeholder.
- **Vị trí placeholder (mới):** Trong màn cấu hình sheet, thêm block **"Vị trí placeholder"** (Placeholder Occurrences):
  - Mỗi dòng = **một vị trí** trên template: **ExcelRowStart** (một hàng), **Định nghĩa placeholder** (dropdown FormDynamicRegion), **Bộ lọc** (dropdown FilterDefinition – có thể giống hoặc khác nhau giữa các vị trí), Nguồn (optional override), DisplayOrder, MaxRows.
  - Nút Thêm vị trí, Sửa, Xóa. **Cùng một FormDynamicRegion** có thể chọn nhiều lần (nhiều vị trí) với bộ lọc khác nhau.
- **Bộ lọc (mới):** Trang hoặc modal **"Bộ lọc"** (FilterDefinition):
  - Tên, Mã, LogicalOperator (AND/OR).
  - Danh sách điều kiện: **Trường** (dropdown cột từ DataSource hoặc nhập tên), **Toán tử** (Eq, Lt, Gt, …), **Loại giá trị** (Literal / Parameter), **Giá trị** (nhập số/chuỗi hoặc chọn tham số: ReportDate, OrganizationId, …).
  - Có thể chọn DataSource trước để dropdown Trường lấy từ metadata cột.
- **Nguồn dữ liệu (mới):** Trang **"Nguồn dữ liệu"** (DataSource): CRUD; với SourceType = Table/View thì nhập tên bảng/view, sau đó "Lấy danh sách cột" để dùng trong FilterDefinition.

---

## 7. Bảng tổng hợp: Điều kiện lọc hỗ trợ

| Loại lọc | Cách đáp ứng |
|----------|---------------|
| **Theo đơn vị** | Tham số OrganizationId trong context; điều kiện Field = OrganizationId (hoặc cột tương đương), Operator = Eq, ValueType = Parameter, Value = OrganizationId. Hoặc RLS trên bảng nguồn. |
| **Theo catalog** | DataSource gắn IndicatorCatalogId; nguồn = chỉ tiêu trong catalog (và có thể join bảng mở rộng). |
| **Theo nhiều điều kiện trên cột** | FilterDefinition + FilterCondition: mỗi điều kiện = Field (cột) + Operator + Value (Literal hoặc Parameter). LogicalOperator = AND/OR. |
| **Ví dụ: ngày ban hành < ngày lập báo cáo** | Field = DocumentIssueDate, Operator = Lt, ValueType = Parameter, Value = ReportDate. |
| **Ví dụ: tổng mức đầu tư > 10 tỷ** | Field = TotalInvestment, Operator = Gt, ValueType = Literal, Value = 10000000000 (và DataType = Number). |
| **Ví dụ: dự án mới (cột cờ)** | Field = IsNew, Operator = Eq, ValueType = Literal, Value = 1 (DataType = Boolean). |
| **Ví dụ: có điều chỉnh** | Field = HasAdjustment, Operator = Eq, ValueType = Literal, Value = 1. |
| **Nhiều placeholder, một placeholder lặp nhiều lần với bộ lọc giống/khác** | FormPlaceholderOccurrence: mỗi vị trí = một ExcelRowStart (một dòng), FormDynamicRegionId, FilterDefinitionId. Cùng FormDynamicRegionId có thể có nhiều occurrence, mỗi occurrence một FilterDefinition (giống hoặc khác). |

---

## 7.1. Phân cấp cha-con (chỉ tiêu cố định) và độ sâu (chỉ tiêu động từ placeholder) – Giải pháp đã đáp ứng chưa?

**Yêu cầu:** (1) **Điều kiện cho dòng** đã đúng (bộ lọc theo trường). (2) Cần **phân cấp cha-con cho chỉ tiêu cố định**. (3) Với **chỉ tiêu động** tạo từ placeholder: cần **xác định độ sâu** lấy cấp con đến mức nào để tạo ra **số dòng và phân cấp tương ứng** khi tạo file Excel cho đơn vị nhập liệu trên web.

### Thiết kế (GIAI_PHAP – đã đáp ứng trong tài liệu)

| Nội dung | Trong giải pháp | Trạng thái thiết kế |
|----------|------------------|----------------------|
| **Phân cấp cha-con cho chỉ tiêu cố định** | **FormColumn.ParentId**, **FormRow.ParentId** (self-FK): cấu hình cột/hàng theo cây, độc lập với cây chỉ tiêu. **Cột:** khi build Excel, header cột cha **merge** (colspan) = số cột lá dưới nó. **BCDT_Indicator.ParentId** cho chỉ tiêu (cố định và động) dùng chung danh mục. | ✅ Đã có trong [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) mục 4.8 (R11). |
| **Độ sâu cho chỉ tiêu động từ placeholder** | **FormDynamicRegion.IndicatorExpandDepth**: khi placeholder gắn catalog (IndicatorCatalogId), giá trị này quy định **độ sâu** lấy cây chỉ tiêu khi sinh hàng: **1** = chỉ gốc, **2** = gốc + con, **3** = gốc + con + cháu, **0** = không giới hạn. Khi build workbook: lấy danh sách chỉ tiêu từ catalog theo cây (ParentId, DisplayOrder), **cắt đến độ sâu IndicatorExpandDepth**, rồi sinh dòng theo thứ tự đó → **số dòng và phân cấp** tương ứng trong Excel. | ✅ Đã có trong GIAI_PHAP mục 4.2, 4.8.3, 4.4 (Build workbook ưu tiên cấu hình → chỉ tiêu động theo depth). |

### Triển khai hiện tại (B12 – đã làm / chưa làm)

| Nội dung | Đã triển khai | Chưa triển khai |
|----------|----------------|------------------|
| **Phân cấp cột (chỉ tiêu cố định)** | ✅ Build workbook đã có **ColumnHeaders** theo cây FormColumn (ParentId), **colspan** = số cột lá. Cột có phân cấp khi tạo file Excel. | — |
| **Phân cấp hàng (FormRow)** | — | ⏳ **P2a** chưa xong: FormRow.ParentId, FormRow.FormDynamicRegionId, API tree rows. Hàng cố định theo cấu hình cây FormRow chưa đầy đủ. |
| **Sinh dòng chỉ tiêu động từ cây catalog theo IndicatorExpandDepth** | Hiện build workbook chỉ **đưa ra dữ liệu đã lưu** (ReportDynamicIndicator). Cột **IndicatorExpandDepth** đã có trên FormDynamicRegion, FE FormConfig đã có nhập độ sâu. | ⏳ **Chưa** có bước: lấy cây BCDT_Indicator (theo catalog) → cắt theo **IndicatorExpandDepth** → **sinh danh sách dòng** (gốc, con, cháu…) → điền vào vùng placeholder khi chưa có/hoặc pre-fill. Tức là “tạo ra số dòng và phân cấp tương ứng” **từ catalog theo độ sâu** chưa được implement trong BuildWorkbookFromSubmissionService. |

### Kết luận

- **Giải pháp (thiết kế)** đã đáp ứng: (1) phân cấp cha-con cho chỉ tiêu cố định (cột/hàng FormColumn/FormRow, merge header, cây chỉ tiêu BCDT_Indicator.ParentId); (2) độ sâu cho chỉ tiêu động từ placeholder (IndicatorExpandDepth để xác định lấy cấp con đến đâu, tạo số dòng và phân cấp khi tạo Excel).
- **Triển khai:** Phân cấp **cột** và xuất **dữ liệu chỉ tiêu động đã lưu** đã có; **sinh dòng từ cây chỉ tiêu theo IndicatorExpandDepth** (và đầy đủ FormRow cây hàng) chưa có – cần bổ sung trong phase B12 P2a / mở rộng Build workbook (khi placeholder gắn catalog: query cây Indicator → cắt depth → sinh danh sách dòng → điền/pre-fill).

### 7.2. Cấu hình cột – placeholder và điều kiện lọc (yêu cầu đối xứng với dòng)

**Yêu cầu (mục 1.3):** Khi cấu hình cột cũng đảm bảo **placeholder** và **điều kiện lọc** tương tự như dòng.

| Khía cạnh | Dòng (hàng) | Cột (theo yêu cầu + thiết kế mục 4a) |
|-----------|--------------|--------------------------------------|
| **Placeholder** | Có: **FormDynamicRegion** + **FormPlaceholderOccurrence** (nhiều vị trí, mỗi vị trí một bộ lọc). | **Thiết kế đề xuất:** **FormDynamicColumnRegion** (định nghĩa placeholder cột) + **FormPlaceholderColumnOccurrence** (vị trí cột, ExcelColStart, mở rộng thành 0..N cột khi gen). Cùng định nghĩa có thể đặt nhiều vị trí, mỗi vị trí một bộ lọc. |
| **Điều kiện (filter)** | **FilterDefinition** + **FilterCondition** gắn với **FormPlaceholderOccurrence**. | **Đối xứng:** **FormPlaceholderColumnOccurrence** gắn **FilterDefinitionId** – tái sử dụng cùng FilterDefinition/FilterCondition; khi gen → resolve filter → nguồn cột → sinh N cột tại vị trí đó. |

**Trạng thái:** Yêu cầu đã ghi nhận; thiết kế chi tiết tại **mục 4a** (FormDynamicColumnRegion, FormPlaceholderColumnOccurrence, luồng build workbook cột động, FE block "Vùng cột động" / "Vị trí placeholder cột"). Triển khai theo phase P8e–P8f (xem mục 9).

---

## 8. Rủi ro và giảm thiểu

| Rủi ro | Giảm thiểu |
|--------|------------|
| SQL injection / unsafe filter | Không build raw SQL từ tên cột/user; dùng whitelist tên cột từ metadata DataSource; tham số hóa giá trị (parameterized query). |
| Performance (query lớn) | Giới hạn MaxRows theo từng vị trí placeholder; index trên bảng nguồn (cột hay dùng trong filter); cache metadata cột. |
| Bảng nguồn không có sẵn (vd BCDT_Project) | Phase 1: chỉ hỗ trợ SourceType = Catalog (filter trên bảng mở rộng gắn catalog nếu có). Phase 2: thêm Table/View khi nghiệp vụ có bảng dự án. |
| Ép kiểu Literal sai | Lưu DataType trong FilterCondition; validate khi lưu (số/ngày/boolean); khi resolve bắt lỗi và log. |

---

## 9. Kế hoạch triển khai gợi ý (sau khi duyệt)

| Phase | Nội dung | Ước lượng |
|-------|----------|-----------|
| **P8a** | DB: BCDT_DataSource, BCDT_FilterDefinition, BCDT_FilterCondition, BCDT_FormPlaceholderOccurrence. API CRUD DataSource, FilterDefinition (kèm conditions), Placeholder Occurrences theo sheet. | 2–3 ngày |
| **P8b** | Engine resolve filter: Parameter Context từ submission; build WHERE từ FilterCondition (whitelist cột, parameterized); query DataSource. Tích hợp BuildWorkbook: với mỗi FormPlaceholderOccurrence (một dòng), resolve filter → query → mở rộng thành N hàng từ ExcelRowStart. | 2–3 ngày |
| **P8c** | FE: Trang/modal DataSource, FilterDefinition (điều kiện theo trường), FormConfig – block Vị trí placeholder (ExcelRowStart, Định nghĩa placeholder, Bộ lọc; cùng định nghĩa có thể thêm nhiều vị trí với bộ lọc khác nhau). API prefill (optional). | 2–3 ngày |
| **P8d** | Test: tạo DataSource, nhiều FilterDefinition, nhiều vị trí placeholder (cùng hoặc khác bộ lọc), build workbook và kiểm tra đúng số hàng mở rộng và đúng bộ lọc từng vị trí. | 1 ngày |
| **P8e** | **Placeholder cột (đối xứng với dòng):** DB: BCDT_FormDynamicColumnRegion, BCDT_FormPlaceholderColumnOccurrence (ExcelColStart, FormDynamicColumnRegionId, FilterDefinitionId). API CRUD dynamic-column-regions, placeholder-column-occurrences theo sheet. Build workbook: với mỗi FormPlaceholderColumnOccurrence, resolve filter + nguồn cột (ByReportingPeriod / ByCatalog / ByDataSource) → sinh N cột tại ExcelColStart. | 2–3 ngày |
| **P8f** | FE FormConfig – block "Vùng cột động": định nghĩa placeholder cột (ColumnSourceType, ColumnSourceRef); block "Vị trí placeholder cột" (ExcelColStart, Định nghĩa, Bộ lọc – tái sử dụng FilterDefinition). Test: nhiều vị trí placeholder cột (cùng/khác bộ lọc), build workbook kiểm tra đúng số cột và nhãn cột. | 2–3 ngày |

**Tổng (P8a–P8d):** Khoảng 7–10 ngày. **Tổng (thêm P8e–P8f placeholder cột):** +4–6 ngày (ước lượng).

---

## 10. Tóm tắt

- **Yêu cầu đối xứng cho cột (1.3):** Cấu hình **cột** cũng đảm bảo **placeholder** và **điều kiện lọc** tương tự như dòng. Thiết kế tại **mục 4a** (FormDynamicColumnRegion, FormPlaceholderColumnOccurrence, FilterDefinitionId; luồng build workbook cột động; FE block "Vùng cột động" / "Vị trí placeholder cột"). Phase P8e–P8f.
- **Lọc theo đơn vị, catalog:** Tham số OrganizationId, CatalogId trong context và điều kiện trong FilterDefinition.
- **Lọc theo nhiều điều kiện trên các cột:** **FilterDefinition** + **FilterCondition** (Field, Operator, ValueType, Value) với **Parameter** (ReportDate, OrganizationId, …) và **Literal** (số, ngày, cờ). **Dùng chung** cho cả placeholder dòng và placeholder cột.
- **Placeholder dòng:** **FormPlaceholderOccurrence** – mỗi bản ghi = **một dòng** (ExcelRowStart), gắn FormDynamicRegionId và FilterDefinitionId. Khi gen: mỗi dòng mở rộng thành 0..N hàng theo kết quả truy vấn.
- **Placeholder cột:** **FormPlaceholderColumnOccurrence** – mỗi bản ghi = **một vị trí cột** (ExcelColStart), gắn FormDynamicColumnRegionId và FilterDefinitionId. Khi gen: mỗi vị trí mở rộng thành 0..N cột theo nguồn cột + bộ lọc.
- **Nguồn dữ liệu:** **DataSource** (Table, View, Catalog, API); **FormDynamicColumnRegion** có ColumnSourceType (ByReportingPeriod, ByCatalog, ByDataSource) để sinh danh sách cột.

Tài liệu này dùng để **duyệt**. Nếu đồng ý, có thể bổ sung vào [GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md](GIAI_PHAP_CAU_TRUC_BIEU_MAU_CHI_TIEU_CO_DINH_VA_DONG.md) (mục mới "Lọc động theo trường dữ liệu" + "Placeholder cột và điều kiện lọc cho cột") và lên kế hoạch phase P8a–P8f.
