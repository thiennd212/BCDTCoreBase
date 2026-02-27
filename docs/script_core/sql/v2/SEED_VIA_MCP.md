# Seed dữ liệu test qua MCP (mcp_mssql_execute_sql)

AI/Agent có MCP SQL Server có thể tự động seed dữ liệu test bằng cách gọi **mcp_mssql_execute_sql** với nội dung từng file batch (theo thứ tự). Mỗi file là **một batch** (không có `GO`), chạy lại an toàn nhờ điều kiện trong SQL.

## File batch (chạy theo thứ tự)

| Thứ tự | File | Mô tả |
|--------|------|------|
| 1 | `seed_mcp_1_test_excel_entry.sql` | Form TEST_EXCEL_ENTRY + 1 submission + 80 ReportDataRow (chỉ chạy khi chưa có form). |
| 2 | `seed_mcp_2_test_excel_full.sql` | Form TEST_EXCEL_FULL (8 cột) + 1 submission + 20 ReportDataRow (chỉ chạy khi chưa có form). |
| 3 | `seed_mcp_3_more_submissions.sql` | Thêm submission và ~30 ReportDataRow cho submission chưa có data (idempotent). |
| (tùy chọn) | `seed_bao_cao_dau_tu_kkte.sql` | Form BAO_CAO_DAU_TU_KKTE (báo cáo đầu tư KKT-E, 4 cột, 56 dòng). Một batch (không GO), gọi **sp_SetSystemContext** đầu script; xóa form cũ rồi insert lại. Có thể chạy qua MCP với `query` = nội dung file. |

**Cách dùng:** Đọc nội dung từng file (Read), rồi gọi **mcp_mssql_execute_sql** với `query` = nội dung file đó. Gọi lần lượt 1 → 2 → 3. Nếu cần biểu mẫu KKT-E thì chạy thêm `seed_bao_cao_dau_tu_kkte.sql`.

## 1. Query kiểm tra trạng thái

```sql
EXEC [dbo].[sp_SetSystemContext];
SELECT
  CASE WHEN EXISTS (SELECT 1 FROM [dbo].[BCDT_FormDefinition] f
    INNER JOIN [dbo].[BCDT_ReportSubmission] s ON s.FormDefinitionId = f.Id
    INNER JOIN [dbo].[BCDT_ReportDataRow] r ON r.SubmissionId = s.Id
    WHERE f.[Code] = N'TEST_EXCEL_ENTRY') THEN 1 ELSE 0 END AS HasEntry,
  CASE WHEN EXISTS (SELECT 1 FROM [dbo].[BCDT_FormDefinition] f
    INNER JOIN [dbo].[BCDT_ReportSubmission] s ON s.FormDefinitionId = f.Id
    INNER JOIN [dbo].[BCDT_ReportDataRow] r ON r.SubmissionId = s.Id
    WHERE f.[Code] = N'TEST_EXCEL_FULL') THEN 1 ELSE 0 END AS HasFull,
  (SELECT COUNT(DISTINCT s.Id) FROM [dbo].[BCDT_FormDefinition] f
    INNER JOIN [dbo].[BCDT_ReportSubmission] s ON s.FormDefinitionId = f.Id
    INNER JOIN [dbo].[BCDT_ReportDataRow] r ON r.SubmissionId = s.Id
    WHERE f.[Code] = N'TEST_EXCEL_ENTRY') AS SubCount;
```

---

## Gợi ý cho AI

Khi user yêu cầu **"seed data"**, **"tự động seed"**, **"seed qua MCP"**:

1. **(Tùy chọn)** Gọi **mcp_mssql_execute_sql** với query kiểm tra (mục 1) để báo HasEntry, HasFull, SubCount.
2. Gọi **mcp_mssql_execute_sql** với **nội dung file** `docs/script_core/sql/v2/seed_mcp_1_test_excel_entry.sql` (đọc file rồi truyền vào tham số `query`).
3. Gọi **mcp_mssql_execute_sql** với **nội dung file** `docs/script_core/sql/v2/seed_mcp_2_test_excel_full.sql`.
4. Gọi **mcp_mssql_execute_sql** với **nội dung file** `docs/script_core/sql/v2/seed_mcp_3_more_submissions.sql`.
5. Báo user: đã seed qua MCP; dữ liệu test sẵn sàng; mở `/submissions/{id}/entry` để test.

Các file `seed_mcp_*.sql` đã là **một batch** (không có `GO`), dùng trực tiếp cho MCP.

### Header nhiều tầng (N tầng)

- Trước khi seed (hoặc trên DB đã có schema): chạy **17.add_form_column_group_levels.sql** (thêm cột ColumnGroupLevel2, Level3, Level4).
- **seed_mcp_2** đã insert ColumnGroupLevel2 cho TEST_EXCEL_FULL (mẫu 3 tầng).
- Trên DB đã có sẵn form TEST_EXCEL_FULL (chưa có Level2): chạy **18.update_test_excel_full_header_levels.sql** để cập nhật mẫu 3 tầng.
