---
name: bcdt-seed-test-data
description: Seed dữ liệu test cho BCDT (form, submission, ReportDataRow) phục vụ màn nhập liệu Excel. Dùng MCP mssql execute_sql hoặc PowerShell Ensure-TestData.ps1. Use when user says "seed test", "dữ liệu mẫu", "chạy seed", "test data excel entry", or cần dữ liệu để test màn nhập liệu.
---

# BCDT Seed Test Data

Tạo form và submission mẫu để test màn nhập liệu Excel (`/submissions/{id}/entry`).

## Tài liệu bắt buộc

- [README_SEED_TEST.md](../../../docs/script_core/sql/v2/README_SEED_TEST.md) – mục đích, thứ tự script.
- [SEED_VIA_MCP.md](../../../docs/script_core/sql/v2/SEED_VIA_MCP.md) – chạy seed qua MCP (execute_sql từng batch).

## Cách làm

### Qua MCP (Cursor)

1. Dùng tool **mcp_mssql_execute_sql**.
2. Chạy lần lượt **nội dung** (một batch, không `GO`) từng file:
   - `docs/script_core/sql/v2/seed_mcp_1_test_excel_entry.sql`
   - `docs/script_core/sql/v2/seed_mcp_2_test_excel_full.sql`
   - `docs/script_core/sql/v2/seed_mcp_3_more_submissions.sql`

### Qua PowerShell

Trong thư mục `docs/script_core/sql/v2/` chạy:

```powershell
.\Ensure-TestData.ps1
```

## Nội dung seed

| File | Nội dung |
|------|----------|
| seed_mcp_1 | Form TEST_EXCEL_ENTRY + ReportDataRow mẫu (~80 dòng) |
| seed_mcp_2 | Form TEST_EXCEL_FULL (8 cột, ColumnGroupName, load sẵn, công thức, khóa, dropdown) |
| seed_mcp_3 | Thêm submission và ~30 dòng/submission |

## Điều kiện

- Đã chạy schema 01→14 (và `16.add_form_column_group.sql` nếu dùng form có ColumnGroupName).
- Rule **bcdt-database** (seed, MCP, ColumnGroupName).
