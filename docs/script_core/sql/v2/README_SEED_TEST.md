# Seed dữ liệu test – Nhập liệu Excel

**Rà soát toàn bộ dữ liệu seeding (core 14, menu 15/23, test excel):** [RA_SOAT_DU_LIEU_SEEDING.md](RA_SOAT_DU_LIEU_SEEDING.md).

## Seed qua MCP (AI/Agent)

Nếu dùng **MCP SQL Server** (`mcp_mssql_execute_sql`), gọi lần lượt với nội dung từng file:

1. `seed_mcp_1_test_excel_entry.sql`
2. `seed_mcp_2_test_excel_full.sql`
3. `seed_mcp_3_more_submissions.sql`

Chi tiết: **SEED_VIA_MCP.md**.

---

## Tự động kiểm tra và chạy seed (PowerShell)

Script **Ensure-TestData.ps1** kiểm tra điều kiện test rồi chạy seed khi thiếu:

1. **Schema:** Có bảng `BCDT_FormDefinition`.
2. **TEST_EXCEL_ENTRY:** Có ít nhất 1 submission có ít nhất 1 `ReportDataRow`.
3. **TEST_EXCEL_FULL:** Có ít nhất 1 submission có ít nhất 1 `ReportDataRow`.
4. **Nhiều submission (tùy chọn):** TEST_EXCEL_ENTRY có ít nhất 2 submission có data.

Nếu thiếu → chạy lần lượt: `seed_test_excel_entry.sql`, `seed_more_submissions_excel_entry.sql` (nếu cần), `seed_test_excel_full_form.sql`.

### Cách chạy

**Từ thư mục repo:**

```powershell
.\scripts\Ensure-TestData.ps1
```

**Từ thư mục `docs/script_core/sql/v2`:**

```powershell
.\Ensure-TestData.ps1
```

**Tham số:**

- `-ConnectionString "Server=...;Database=BCDT;..."` – chuỗi kết nối (mặc định: env `BCDT_ConnectionString` hoặc `src/BCDT.Api/appsettings.Development.json`).
- `-SkipMoreSubmissions` – chỉ đảm bảo có 1 submission có data, không chạy `seed_more_submissions_excel_entry.sql`.

**Yêu cầu:** Cài **sqlcmd** (SQL Server Command Line Utilities). Trên Windows có thể đi kèm SQL Server hoặc [Download](https://learn.microsoft.com/en-us/sql/tools/sqlcmd/sqlcmd-utility).

## Chạy seed thủ công

Nếu không dùng script, chạy theo thứ tự:

1. `seed_test_excel_entry.sql` – Form TEST_EXCEL_ENTRY + 1 submission + 80 ReportDataRow.
2. `seed_more_submissions_excel_entry.sql` – Thêm submission và 30 dòng/submission cho submission chưa có data.
3. `seed_test_excel_full_form.sql` – Form TEST_EXCEL_FULL (cột load sẵn, nhập, công thức, khóa, dropdown) + 1 submission + 20 dòng.
4. `seed_bao_cao_dau_tu_kkte.sql` – Form **BAO_CAO_DAU_TU_KKTE** (báo cáo đầu tư KKT-E: 4 cột Chỉ tiêu / Đơn vị tính / KCN trong KKT / Khu vực khác) + 1 submission + **56** ReportDataRow (1 header + 55 dòng: A, A.I, A.II, B, C gồm Quy đổi sang VNĐ, D). Chạy với **sp_SetSystemContext** trước (script đã gọi); idempotent: xóa form cũ rồi insert lại. **Tiếng Việt:** file UTF-8, bắt buộc chạy sqlcmd với **-f 65001** (ví dụ: `sqlcmd ... -f 65001 -i seed_bao_cao_dau_tu_kkte.sql`), nếu không sẽ bị lỗi mojibake (BÃ¡o cÃ¡o Ä'áº§u tÆ° thay vì Báo cáo đầu tư).

Sau khi có schema và RLS (01–14, 12), chạy bằng **sqlcmd** hoặc SSMS.

---

## Kiểm tra cho AI (rà soát seed)

Khi task "Rà soát dữ liệu đã seeding": đọc [RA_SOAT_DU_LIEU_SEEDING.md](RA_SOAT_DU_LIEU_SEEDING.md) mục 1–3, 5 (đầy đủ nghiệp vụ), 6 (trùng lặp/chồng chéo); đối chiếu file và tài liệu; nếu có MCP SQL chạy query trong SEED_VIA_MCP.md; báo Pass/Fail từng mục (mục 7 RA_SOAT).
