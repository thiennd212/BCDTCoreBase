---
name: bcdt-form-builder
description: Create a new FormDefinition with sheets, columns, rows, and data bindings for BCDT reporting system. Use when user says "tạo biểu mẫu", "định nghĩa form", "create form definition", or wants to set up a new Excel-based report form.
---

# BCDT Form Builder

Create complete form definition for Excel-based reporting.

## Workflow

1. **Gather requirements**:
   - Form name and code
   - Form type: Input (nhập liệu) or Aggregate (tổng hợp)
   - Reporting frequency (Daily, Weekly, Monthly, etc.)
   - Number of sheets
   - For each sheet: columns and their data types/bindings

2. **Generate SQL** for form structure:

### FormDefinition
```sql
INSERT INTO BCDT_FormDefinition (Code, Name, FormType, ReportingFrequencyId, DeadlineOffsetDays, RequireApproval, Status, CreatedBy)
VALUES (
    '{FormCode}',           -- e.g., 'BC_NHANSU_T'
    N'{FormName}',          -- e.g., N'Báo cáo nhân sự tháng'
    '{FormType}',           -- 'Input' or 'Aggregate'
    {FrequencyId},          -- 1=Daily, 2=Weekly, 3=Monthly, 4=Quarterly, 5=Yearly
    5,                      -- Deadline offset days
    1,                      -- Require approval
    'Draft',
    -1
);
DECLARE @FormId INT = SCOPE_IDENTITY();
```

### FormSheet
```sql
INSERT INTO BCDT_FormSheet (FormDefinitionId, SheetIndex, SheetName, DisplayName, IsDataSheet, CreatedBy)
VALUES 
    (@FormId, 0, 'Sheet1', N'Dữ liệu chính', 1, -1),
    (@FormId, 1, 'DanhMuc', N'Danh mục', 0, -1);
DECLARE @Sheet1Id INT = SCOPE_IDENTITY() - 1;
```

### FormColumn
- Cột **ColumnGroupName** (NVARCHAR, nullable): dùng cho header phân cấp 1–2 tầng trên màn nhập liệu (Fortune-sheet). Cùng nhóm → merge ô header. Script schema: `docs/script_core/sql/v2/16.add_form_column_group.sql`.
```sql
INSERT INTO BCDT_FormColumn (FormSheetId, ColumnCode, ColumnName, ExcelColumn, DataType, IsRequired, IsEditable, DisplayOrder, ColumnGroupName, CreatedBy)
VALUES 
    (@Sheet1Id, 'STT', N'STT', 'A', 'Number', 0, 0, 1, N'Thong tin chung', -1),
    (@Sheet1Id, 'TEN', N'Họ tên', 'B', 'Text', 1, 1, 2, N'Thong tin chung', -1),
    (@Sheet1Id, 'SOLUONG', N'Số lượng', 'C', 'Number', 1, 1, 3, N'So lieu', -1),
    (@Sheet1Id, 'TONGCONG', N'Tổng cộng', 'D', 'Formula', 0, 0, 4, N'So lieu', -1);
```

### FormDataBinding (for auto-populated columns)
```sql
-- Example: Column bound to Organization name
INSERT INTO BCDT_FormDataBinding (FormColumnId, BindingType, SourceTable, SourceColumn, DefaultValue, CreatedBy)
SELECT Id, 'Organization', NULL, 'Name', NULL, -1
FROM BCDT_FormColumn WHERE ColumnCode = 'TENDONVI' AND FormSheetId = @Sheet1Id;

-- Example: Column bound to Reference entity
INSERT INTO BCDT_FormDataBinding (FormColumnId, BindingType, ReferenceEntityTypeId, ReferenceDisplayColumn, CreatedBy)
SELECT c.Id, 'Reference', r.Id, 'Name', -1
FROM BCDT_FormColumn c, BCDT_ReferenceEntityType r
WHERE c.ColumnCode = 'LOAISP' AND c.FormSheetId = @Sheet1Id AND r.Code = 'PRODUCT_TYPE';
```

### FormColumnMapping (for data extraction)
```sql
INSERT INTO BCDT_FormColumnMapping (FormColumnId, TargetColumnName, TargetColumnIndex, AggregateFunction, CreatedBy)
SELECT Id, 'NumericValue1', 1, 'SUM', -1 FROM BCDT_FormColumn WHERE ColumnCode = 'SOLUONG';
```

## Data Binding Types

| Type | Use Case | Example |
|------|----------|---------|
| Static | Fixed value | Year = "2026" |
| Database | Query from table | `SELECT Name FROM BCDT_Organization WHERE Id = @OrgId` |
| API | External API | GET /api/external/exchange-rate |
| Formula | Excel formula | `=SUM(C2:C100)` |
| Reference | Entity lookup | Product.Name |
| Organization | Current org info | CurrentOrg.Code |
| System | System values | CurrentDate, CurrentUser |

## Column DataTypes

| DataType | Description | Editable |
|----------|-------------|----------|
| Text | Free text | Yes |
| Number | Numeric | Yes |
| Date | Date picker | Yes |
| Formula | Excel formula | No |
| Reference | Dropdown from entity | Yes |
| Boolean | Checkbox | Yes |

## Submission flow (đã có API)
- **Tải template:** GET /api/v1/forms/{id}/template → file .xlsx (ClosedXML). Query `fillBinding=true` (và optional `organizationId`, `reportingPeriodId`) → IDataBindingResolver điền giá trị theo FormDataBinding (Static, Database, Reference, Organization, System, Formula, API).
- **Upload Excel:** POST /api/v1/submissions/{id}/upload-excel (multipart); service đọc file theo FormColumnMapping → ReportDataRow + ReportPresentation.WorkbookJson.
- FormColumnMapping bắt buộc để map cột Excel → cột lưu (TargetColumnName, TargetColumnIndex).

## Output Checklist
- [ ] FormDefinition INSERT
- [ ] FormSheet INSERT (for each sheet)
- [ ] FormColumn INSERT (for each column)
- [ ] FormDataBinding INSERT (for auto-populated columns)
- [ ] FormColumnMapping INSERT (for numeric columns to extract)
- [ ] FormRow INSERT (if has repeating rows)
