# Task 2.9 – CloneAsync: Nhân bản biểu mẫu (deep copy)

**Ngày:** 2026-02-27
**Kết quả:** ✅ DONE – Build Pass
**Size:** LARGE (5+ files, deep copy với ParentId re-mapping)

## Vấn đề ban đầu

CS0535: `FormDefinitionService` không implement `CloneAsync` (Cursor thêm vào interface nhưng không implement). Cursor fix cũng timeout.

## Giải pháp

Đọc tất cả entity files trước (FormVersion, FormSheet, FormColumn, FormRow) để lấy exact property names, sau đó implement trong `FormDefinitionService.CloneAsync`:

1. Load source FormDefinition (kèm Versions, Sheets, Columns, Rows)
2. Check NewCode không trùng
3. Tạo FormDefinition mới, SaveChanges → lấy Id
4. Clone từng FormVersion → lưu, lấy Id
5. Clone từng FormSheet → lưu, lấy Id (versionId map)
6. Clone từng FormColumn → lưu, lấy Id; build `columnIdMap[old] = new`
7. Fix ParentId: load lại columns → set ParentId theo columnIdMap → SaveChanges
8. Clone từng FormRow → lưu, lấy Id; build `rowIdMap[old] = new`
9. Fix ParentRowId: load lại rows → set ParentRowId theo rowIdMap → SaveChanges

## Endpoint

`POST /api/v1/forms/{id}/clone` – Policy: `FormStructureAdmin`

## Key properties

- `FormColumn.ColumnGroupName`, `.ColumnGroupLevel2`, `.ColumnGroupLevel3`, `.ColumnGroupLevel4` (KHÔNG phải L1/L2/L3/L4)
- `FormColumn.IndicatorId` là `int` NOT NULL (không nullable)
- `FormColumn.ParentId` nullable → cần re-map qua dictionary
- `FormRow.ParentRowId` nullable → cần re-map qua dictionary
