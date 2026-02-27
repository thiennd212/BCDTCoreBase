# Kế hoạch: Hoàn thiện Biểu mẫu động (Excel) – 4 Ưu tiên

**Lưu tại project**: `docs/de_xuat_trien_khai/KE_HOACH_BIEU_MAU_DONG_4_UU_TIEN.md`
**Ngày lập**: 2026-02-26

---

## Context

Hệ thống BCDT hiện thiếu 4 tính năng so với nghiệp vụ biểu mẫu động Excel:

| # | Gap | Hệ quả |
|---|-----|--------|
| 1 | `FormColumn.ExcelColumn` bắt buộc lúc thiết kế template | Không thể tạo template khi chưa biết số cột động |
| 2 | `FormRow` không có `IsEditable`, `IsRequired`, `Formula` | Không cấu hình được nhập/không nhập ở cấp hàng |
| 3 | Không có formula engine | Công thức lưu chuỗi, không inject vào Fortune Sheet |
| 4 | Không có cell-level formula/editable override | Không thể override formula ở giao điểm HÀNG × CỘT |

---

## Mục 1 – ExcelColumn: Tính tại runtime, không lưu cố định

### Vấn đề gốc
`FormColumn.ExcelColumn` (e.g. "A", "B") được lưu lúc tạo template. Khi sheet có `FormDynamicColumnRegion` (cột sinh từ datasource theo từng đơn vị), số cột không xác định lúc thiết kế → không thể điền đúng ExcelColumn cho các cột phía sau vùng động.

### Giải pháp: LayoutOrder + ColumnLayoutService

**1.1 – Thêm `LayoutOrder` (int) vào 2 entity**

```
FormColumn.LayoutOrder        = thứ tự trong layout tổng của sheet
FormPlaceholderColumnOccurrence.LayoutOrder = thứ tự trong layout tổng
```

Cả 2 dùng chung namespace số → sort chung → gán A/B/C liên tiếp.

Ví dụ cấu hình:
```
FormColumn "STT"         LayoutOrder=0  → A
FormColumn "Tên"         LayoutOrder=1  → B
PlaceholderOccurrence    LayoutOrder=2  → C, D, E (3 cột từ datasource đơn vị)
FormColumn "Tổng"        LayoutOrder=3  → F  (tự động shift do dynamic)
```

**1.2 – Make `FormColumn.ExcelColumn` nullable**

- Giữ field trong DB (nullable) để backward compat data cũ
- Khi null → dùng computed value từ ColumnLayoutService
- Khi có giá trị → vẫn dùng (override tĩnh, hiếm dùng)

**1.3 – Tạo `IColumnLayoutService`**

```csharp
// Application/Services/Form/IColumnLayoutService.cs
Task<Result<ColumnLayoutResult>> ComputeLayoutAsync(
    int sheetId,
    ParameterContext ctx,
    CancellationToken ct = default);

// DTOs/Form/ColumnLayoutResult.cs
public class ColumnLayoutResult
{
    public List<ColumnSlot> Slots { get; set; }
}
public class ColumnSlot
{
    public string ExcelColumn { get; set; }   // "A", "B", ...
    public int? FormColumnId { get; set; }    // null nếu slot động
    public string? DynamicLabel { get; set; } // tên cột động
    public bool IsEditable { get; set; }
    public int LayoutOrder { get; set; }
}
```

Logic implement (`ColumnLayoutService.cs`):
1. Load FormColumns + FormPlaceholderColumnOccurrences của sheet
2. Sort chung theo `LayoutOrder`
3. Với FormColumn → 1 slot
4. Với PlaceholderOccurrence → query DataSource/ByCatalog/ByReportingPeriod → N slots
5. Gán ExcelColumn bằng `ExcelTemplateParser.ColumnIndexToLetter(i+1)` (hàm đã có)

**1.4 – Cập nhật consumers**

| File | Thay đổi |
|------|----------|
| `BuildWorkbookFromSubmissionService.cs` | Gọi `ComputeLayoutAsync` → dùng `slot.ExcelColumn` (thay lines 165, 178) |
| `SyncFromPresentationService.cs` | Gọi `ComputeLayoutAsync` → dùng `slot.ExcelColumn` khi read JSON key (line 104) |
| `SubmissionExcelService.cs` | Gọi `ComputeLayoutAsync` → dùng `slot.ExcelColumn` cho cell address (lines 96, 100) |
| `FormTemplateService.cs` | Gọi `ComputeLayoutAsync` → dùng `slot.ExcelColumn` cho header/data (lines 75, 79, 83, 97) |
| `FormColumnService.cs` | ExcelColumn trong Create/Update trở thành optional |

**1.5 – Frontend**

`FormConfigPage.tsx`: thêm field `LayoutOrder` (number input) vào form tạo/sửa cột. Cho phép kéo-thả hoặc nhập số để sắp xếp thứ tự interleaving với dynamic regions.

### Files sửa (Mục 1)
```
DOMAIN:
  src/BCDT.Domain/Entities/Form/FormColumn.cs                          ExcelColumn → nullable; thêm LayoutOrder
  src/BCDT.Domain/Entities/Form/FormPlaceholderColumnOccurrence.cs     thêm LayoutOrder

APPLICATION:
  src/BCDT.Application/Services/Form/IColumnLayoutService.cs           NEW
  src/BCDT.Application/DTOs/Form/ColumnLayoutResult.cs                 NEW (ColumnLayoutResult, ColumnSlot)
  src/BCDT.Application/DTOs/Form/FormColumnDto.cs                      ExcelColumn optional, thêm LayoutOrder
  src/BCDT.Application/DTOs/Form/CreateFormColumnRequest.cs            ExcelColumn optional, thêm LayoutOrder
  src/BCDT.Application/DTOs/Form/UpdateFormColumnRequest.cs            ExcelColumn optional, thêm LayoutOrder

INFRASTRUCTURE:
  src/BCDT.Infrastructure/Services/ColumnLayoutService.cs              NEW
  src/BCDT.Infrastructure/Services/BuildWorkbookFromSubmissionService.cs
  src/BCDT.Infrastructure/Services/SyncFromPresentationService.cs
  src/BCDT.Infrastructure/Services/SubmissionExcelService.cs
  src/BCDT.Infrastructure/Services/FormTemplateService.cs
  src/BCDT.Infrastructure/Services/FormColumnService.cs
  src/BCDT.Infrastructure/Persistence/AppDbContext.cs                  mapping ExcelColumn nullable, LayoutOrder

FRONTEND:
  src/bcdt-web/src/pages/FormConfigPage.tsx                            thêm LayoutOrder input cho cột
  src/bcdt-web/src/types/form.types.ts                                 excelColumn optional, thêm layoutOrder

DB (trong file 21_bieu_mau_dong.sql):
  ALTER TABLE BCDT_FormColumn ALTER COLUMN ExcelColumn NVARCHAR(10) NULL;
  ALTER TABLE BCDT_FormColumn ADD LayoutOrder INT NOT NULL DEFAULT 0;
  UPDATE BCDT_FormColumn SET LayoutOrder = DisplayOrder;  -- backfill
  ALTER TABLE BCDT_FormPlaceholderColumnOccurrence ADD LayoutOrder INT NOT NULL DEFAULT 0;
  UPDATE BCDT_FormPlaceholderColumnOccurrence SET LayoutOrder = DisplayOrder;  -- backfill
```

---

## Mục 2 – FormRow: IsEditable, IsRequired, Formula

### Thiết kế
Đối xứng với `FormColumn` (đã có IsEditable, IsRequired, Formula). Thêm 3 fields vào `FormRow`.

```csharp
// FormRow.cs (bổ sung)
public bool IsEditable { get; set; } = true;     // hàng có cho nhập không
public bool IsRequired { get; set; } = false;    // bắt buộc nhập
public string? Formula { get; set; }             // công thức cấp hàng (placeholder-based)
```

**Lưu ý**: `Formula` trên FormRow hoạt động kết hợp với `FormRowFormulaScope` (Mục 3) để xác định cột nào được inject.

### Files sửa (Mục 2)
```
DOMAIN:
  src/BCDT.Domain/Entities/Form/FormRow.cs                             thêm IsEditable, IsRequired, Formula

APPLICATION:
  src/BCDT.Application/DTOs/Form/FormRowDto.cs                         thêm 3 fields
  src/BCDT.Application/DTOs/Form/CreateFormRowRequest.cs               thêm 3 fields (IsEditable default true)
  src/BCDT.Application/DTOs/Form/UpdateFormRowRequest.cs               thêm 3 fields

INFRASTRUCTURE:
  src/BCDT.Infrastructure/Services/FormRowService.cs                   Create/Update/MapToDto: map 3 fields
  src/BCDT.Infrastructure/Persistence/AppDbContext.cs                  thêm Property mapping

FRONTEND:
  src/bcdt-web/src/pages/FormConfigPage.tsx                            thêm row config UI: IsEditable toggle, Formula input

DB (trong file 21_bieu_mau_dong.sql):
  ALTER TABLE BCDT_FormRow ADD IsEditable BIT NOT NULL DEFAULT 1;
  ALTER TABLE BCDT_FormRow ADD IsRequired BIT NOT NULL DEFAULT 0;
  ALTER TABLE BCDT_FormRow ADD Formula NVARCHAR(1000) NULL;
```

---

## Mục 3 – Formula Engine: Inject công thức vào Fortune Sheet

### Cơ chế placeholder
Công thức lưu dưới dạng template, inject địa chỉ thực tế lúc gen biểu:

| Placeholder | Thay bằng |
|------------|-----------|
| `{COL}` | Excel column letter của cột hiện tại (e.g. "D") |
| `{ROW}` | Excel row number của hàng hiện tại (e.g. "9") |
| `{DATA_START_ROW}` | Row đầu tiên chứa data (sau header) |
| `{PREV_ROW}` | `{ROW} - 1` |
| `{NEXT_ROW}` | `{ROW} + 1` |
| `{COL_A}`, `{COL_B}` | Column letter của FormColumn có ColumnCode = A hoặc B |

Ví dụ:
```
Column formula: =SUM({COL}{DATA_START_ROW}:{COL}{PREV_ROW})
  → Gen biểu đơn vị, col D, row 9: =SUM(D3:D8)

Row formula (hàng Tỷ lệ %):  ={COL}{PREV_ROW}/{COL_TONG}{PREV_ROW}*100
  → Col D, row 10: =D9/B9*100
```

### FormRowFormulaScope – chọn cột áp dụng cho row formula

```csharp
// Domain/Entities/Form/FormRowFormulaScope.cs  (NEW)
public class FormRowFormulaScope
{
    public int Id { get; set; }
    public int FormRowId { get; set; }
    public int FormColumnId { get; set; }   // cột được apply formula
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
```

Khi `FormRow.Formula` != null:
- Nếu có `FormRowFormulaScope` records → inject chỉ vào các cột được chọn
- Nếu không có records → mặc định inject vào tất cả cột `IsEditable=true AND DataType IN ('Number','Formula')`

### IFormulaInjectionService

```csharp
// Application/Services/Form/IFormulaInjectionService.cs  (NEW)
void InjectFormulas(
    WorkbookSheetFromSubmissionDto sheet,
    List<FormColumn> columns,
    List<FormRow> rows,
    List<FormRowFormulaScope> rowScopes,
    List<FormCellFormula> cellFormulas,    // Mục 4
    ColumnLayoutResult layout,
    int dataStartRow,
    int dataEndRow);
```

Logic (priority: cell > row > column):
1. Tính `dataStartRow` từ header row count (`GetHeaderRowCount()` đã có trong SyncFromPresentationService)
2. **Column formula**: với mỗi data row r trong [dataStartRow, dataEndRow] → inject `col.Formula` vào cell (r, colIndex) nếu không bị override
3. **Row formula**: với mỗi FormRow có Formula → tìm `rowScopes` tương ứng → inject vào cells tại (rowIndex, các colIndex được chọn / tất cả IsEditable Number)
4. **Cell formula** (FormCellFormula): inject cuối cùng, override column + row formula

Fortune Sheet cell format:
```json
{ "r": 8, "c": 3, "v": { "f": "=SUM(D3:D8)", "v": null } }
```

Integration: gọi `InjectFormulas()` ở cuối `BuildWorkbookFromSubmissionService.BuildAsync()`.

**API cho FormRowFormulaScope**: `CRUD /api/v1/forms/{formId}/sheets/{sheetId}/rows/{rowId}/formula-scope`

### Files sửa/thêm (Mục 3)
```
DOMAIN:
  src/BCDT.Domain/Entities/Form/FormRowFormulaScope.cs                 NEW

APPLICATION:
  src/BCDT.Application/Services/Form/IFormulaInjectionService.cs       NEW
  src/BCDT.Application/Services/Form/IFormRowFormulaScopeService.cs    NEW
  src/BCDT.Application/DTOs/Form/FormRowFormulaScopeDto.cs             NEW

INFRASTRUCTURE:
  src/BCDT.Infrastructure/Services/FormulaInjectionService.cs          NEW
  src/BCDT.Infrastructure/Services/FormRowFormulaScopeService.cs       NEW
  src/BCDT.Infrastructure/Services/BuildWorkbookFromSubmissionService.cs  gọi InjectFormulas
  src/BCDT.Infrastructure/Persistence/AppDbContext.cs                  thêm DbSet FormRowFormulaScopes

API:
  src/BCDT.Api/Controllers/ApiV1/FormRowFormulaScopesController.cs     NEW

FRONTEND:
  src/bcdt-web/src/pages/FormConfigPage.tsx                            UI chọn cột áp dụng cho row formula

DB (trong file 21_bieu_mau_dong.sql):
  CREATE TABLE BCDT_FormRowFormulaScope (
    Id INT IDENTITY PRIMARY KEY,
    FormRowId INT NOT NULL REFERENCES BCDT_FormRow(Id),
    FormColumnId INT NOT NULL REFERENCES BCDT_FormColumn(Id),
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy INT NOT NULL,
    UNIQUE (FormRowId, FormColumnId)
  );
```

---

## Mục 4 – FormCellFormula: Override formula/IsEditable cấp CELL

### Thiết kế
Entity nhẹ lưu override tại giao điểm (FormColumn × FormRow):

```csharp
// Domain/Entities/Form/FormCellFormula.cs  (NEW)
public class FormCellFormula
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int FormColumnId { get; set; }
    public int FormRowId { get; set; }
    public string? Formula { get; set; }     // null = no formula at this cell
    public bool? IsEditable { get; set; }    // null = inherit từ col/row; false = lock cell
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
```

**Priority inject formula**:
```
FormCellFormula.Formula      (highest – cell-level override)
  ↑
FormRow.Formula              (row-level)
  ↑
FormColumn.Formula           (lowest – column-level)
```

**Priority IsEditable**:
```
FormCellFormula.IsEditable   (cell override, null = ignore)
  ↑
FormRow.IsEditable AND FormColumn.IsEditable  (both must be true)
```

**API**: `CRUD /api/v1/forms/{formId}/sheets/{sheetId}/cell-formulas`

**Frontend**: Grid UI (rows × columns) trên FormConfigPage cho phép click cell → modal điền Formula/IsEditable override.

### Files thêm mới (Mục 4)
```
DOMAIN:
  src/BCDT.Domain/Entities/Form/FormCellFormula.cs                     NEW

APPLICATION:
  src/BCDT.Application/Services/Form/IFormCellFormulaService.cs        NEW
  src/BCDT.Application/DTOs/Form/FormCellFormulaDto.cs                 NEW
  src/BCDT.Application/DTOs/Form/CreateFormCellFormulaRequest.cs       NEW

INFRASTRUCTURE:
  src/BCDT.Infrastructure/Services/FormCellFormulaService.cs           NEW
  src/BCDT.Infrastructure/Persistence/AppDbContext.cs                  thêm DbSet FormCellFormulas + mapping

API:
  src/BCDT.Api/Controllers/ApiV1/FormCellFormulasController.cs         NEW

FRONTEND:
  src/bcdt-web/src/pages/FormConfigPage.tsx                            grid UI override formula/editable per cell
  src/bcdt-web/src/api/formStructureApi.ts                             thêm cell formula CRUD

DB (trong file 21_bieu_mau_dong.sql):
  CREATE TABLE BCDT_FormCellFormula (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FormSheetId INT NOT NULL REFERENCES BCDT_FormSheet(Id),
    FormColumnId INT NOT NULL REFERENCES BCDT_FormColumn(Id),
    FormRowId INT NOT NULL REFERENCES BCDT_FormRow(Id),
    Formula NVARCHAR(1000) NULL,
    IsEditable BIT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy INT NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL,
    UNIQUE (FormColumnId, FormRowId)
  );
```

---

## Migration SQL tổng hợp

**File duy nhất**: `docs/script_core/sql/v2/21_bieu_mau_dong.sql`

```sql
-- =====================================================================
-- v21: Hoàn thiện biểu mẫu động – 4 ưu tiên
-- =====================================================================

-- Mục 1: LayoutOrder
ALTER TABLE BCDT_FormColumn ALTER COLUMN ExcelColumn NVARCHAR(10) NULL;
ALTER TABLE BCDT_FormColumn ADD LayoutOrder INT NOT NULL DEFAULT 0;
UPDATE BCDT_FormColumn SET LayoutOrder = DisplayOrder;

ALTER TABLE BCDT_FormPlaceholderColumnOccurrence ADD LayoutOrder INT NOT NULL DEFAULT 0;
UPDATE BCDT_FormPlaceholderColumnOccurrence SET LayoutOrder = DisplayOrder;

-- Mục 2: FormRow fields
ALTER TABLE BCDT_FormRow ADD IsEditable BIT NOT NULL DEFAULT 1;
ALTER TABLE BCDT_FormRow ADD IsRequired BIT NOT NULL DEFAULT 0;
ALTER TABLE BCDT_FormRow ADD Formula NVARCHAR(1000) NULL;

-- Mục 3: FormRowFormulaScope
CREATE TABLE BCDT_FormRowFormulaScope (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FormRowId INT NOT NULL,
    FormColumnId INT NOT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy INT NOT NULL,
    CONSTRAINT FK_FormRowFormulaScope_Row FOREIGN KEY (FormRowId) REFERENCES BCDT_FormRow(Id),
    CONSTRAINT FK_FormRowFormulaScope_Col FOREIGN KEY (FormColumnId) REFERENCES BCDT_FormColumn(Id),
    CONSTRAINT UQ_FormRowFormulaScope UNIQUE (FormRowId, FormColumnId)
);

-- Mục 4: FormCellFormula
CREATE TABLE BCDT_FormCellFormula (
    Id INT IDENTITY(1,1) PRIMARY KEY,
    FormSheetId INT NOT NULL,
    FormColumnId INT NOT NULL,
    FormRowId INT NOT NULL,
    Formula NVARCHAR(1000) NULL,
    IsEditable BIT NULL,
    CreatedAt DATETIME2 NOT NULL DEFAULT GETUTCDATE(),
    CreatedBy INT NOT NULL,
    UpdatedAt DATETIME2 NULL,
    UpdatedBy INT NULL,
    CONSTRAINT FK_FormCellFormula_Sheet FOREIGN KEY (FormSheetId) REFERENCES BCDT_FormSheet(Id),
    CONSTRAINT FK_FormCellFormula_Col FOREIGN KEY (FormColumnId) REFERENCES BCDT_FormColumn(Id),
    CONSTRAINT FK_FormCellFormula_Row FOREIGN KEY (FormRowId) REFERENCES BCDT_FormRow(Id),
    CONSTRAINT UQ_FormCellFormula UNIQUE (FormColumnId, FormRowId)
);
```

---

## Thứ tự thực hiện

```
Bước 1 (song song):
  ├── Mục 1: DB migration + ColumnLayoutService + update consumers
  └── Mục 2: DB migration + FormRow fields + service + DTOs

Bước 2 (sau Bước 1 xong):
  └── Mục 3: FormulaInjectionService + FormRowFormulaScope
             (cần ColumnLayoutResult từ Mục 1)

Bước 3 (sau Bước 2 xong):
  └── Mục 4: FormCellFormula entity + service + integrate vào FormulaInjectionService

Bước 4 (parallel với Bước 2-3):
  └── Frontend: FormConfigPage cập nhật cho Mục 1, 2, 3, 4
```

---

## Danh sách file tóm tắt

### Mới hoàn toàn (NEW)
```
src/BCDT.Application/Services/Form/IColumnLayoutService.cs
src/BCDT.Application/DTOs/Form/ColumnLayoutResult.cs
src/BCDT.Infrastructure/Services/ColumnLayoutService.cs
src/BCDT.Application/Services/Form/IFormulaInjectionService.cs
src/BCDT.Infrastructure/Services/FormulaInjectionService.cs
src/BCDT.Domain/Entities/Form/FormRowFormulaScope.cs
src/BCDT.Application/Services/Form/IFormRowFormulaScopeService.cs
src/BCDT.Application/DTOs/Form/FormRowFormulaScopeDto.cs
src/BCDT.Infrastructure/Services/FormRowFormulaScopeService.cs
src/BCDT.Api/Controllers/ApiV1/FormRowFormulaScopesController.cs
src/BCDT.Domain/Entities/Form/FormCellFormula.cs
src/BCDT.Application/Services/Form/IFormCellFormulaService.cs
src/BCDT.Application/DTOs/Form/FormCellFormulaDto.cs
src/BCDT.Application/DTOs/Form/CreateFormCellFormulaRequest.cs
src/BCDT.Infrastructure/Services/FormCellFormulaService.cs
src/BCDT.Api/Controllers/ApiV1/FormCellFormulasController.cs
docs/script_core/sql/v2/21_bieu_mau_dong.sql
```

### Sửa đổi (EDIT)
```
src/BCDT.Domain/Entities/Form/FormColumn.cs
src/BCDT.Domain/Entities/Form/FormPlaceholderColumnOccurrence.cs
src/BCDT.Domain/Entities/Form/FormRow.cs
src/BCDT.Application/DTOs/Form/FormColumnDto.cs
src/BCDT.Application/DTOs/Form/CreateFormColumnRequest.cs
src/BCDT.Application/DTOs/Form/UpdateFormColumnRequest.cs
src/BCDT.Application/DTOs/Form/FormRowDto.cs
src/BCDT.Application/DTOs/Form/CreateFormRowRequest.cs
src/BCDT.Application/DTOs/Form/UpdateFormRowRequest.cs
src/BCDT.Infrastructure/Services/FormColumnService.cs
src/BCDT.Infrastructure/Services/FormRowService.cs
src/BCDT.Infrastructure/Services/BuildWorkbookFromSubmissionService.cs
src/BCDT.Infrastructure/Services/SyncFromPresentationService.cs
src/BCDT.Infrastructure/Services/SubmissionExcelService.cs
src/BCDT.Infrastructure/Services/FormTemplateService.cs
src/BCDT.Infrastructure/Persistence/AppDbContext.cs
src/bcdt-web/src/pages/FormConfigPage.tsx
src/bcdt-web/src/types/form.types.ts
src/bcdt-web/src/api/formStructureApi.ts
```

### Hàm tái sử dụng
```
ExcelTemplateParser.ColumnIndexToLetter()  – gán A/B/C cho slots
SyncFromPresentationService.ExcelColLetterToIndex()  – parse JSON keys
SyncFromPresentationService.GetHeaderRowCount()  – tính dataStartRow
BuildWorkbookFromSubmissionService.BuildColumnHeaders()  – merge header colspan
```

---

## Verification

| Mục | Test |
|-----|------|
| 1 | Tạo FormColumn không điền ExcelColumn → gen template Excel đúng; 2 đơn vị có datasource trả 2 và 3 cột → template mỗi đơn vị khác nhau, cột sau dynamic đúng thứ tự |
| 2 | FormRow `IsEditable=false` → Fortune Sheet cell read-only; `Formula` lưu và trả về đúng qua API |
| 3 | FormColumn.Formula = `=SUM({COL}{DATA_START_ROW}:{COL}{PREV_ROW})` → BuildWorkbook trả celldata có `f` đúng địa chỉ; FormRow formula inject đúng cột trong FormRowFormulaScope |
| 4 | FormCellFormula override → cell dùng formula override; `IsEditable=false` override → cell readonly dù col/row IsEditable=true |
| Regression | `npm run test:e2e` in `src/bcdt-web` (BE port 5080); Swagger manual test toàn bộ endpoint cũ |
