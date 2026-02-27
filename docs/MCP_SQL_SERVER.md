# Hướng dẫn cài đặt MCP SQL Server (Cursor)

Dùng MCP **mssql_mcp_server** (RichardHan) để Cursor/AI kết nối và làm việc với SQL Server trên máy (list tables, execute query).

---

## 1. Điều kiện

- **Python 3.8+** đã cài (kiểm tra: `python --version` hoặc `py -3 --version`).
- **SQL Server** đang chạy, **TCP/IP đã bật** (SQL Server Configuration Manager → Protocols for MSSQLSERVER → TCP/IP = Enabled).
- Đã tạo database **BCDT** (chạy script `docs/script_core/sql/v2/` 01→14 nếu chưa có).

---

## 2. Cài MCP server (một lần)

Mở **Command Prompt** hoặc **PowerShell**, chạy:

```bash
pip install microsoft_sql_server_mcp
```

Nếu dùng nhiều phiên bản Python:

```bash
py -3 -m pip install microsoft_sql_server_mcp
```

Kiểm tra cài thành công:

```bash
python -m mssql_mcp_server --help
```

(Hoặc `py -3 -m mssql_mcp_server --help` — có thể không in gì, chỉ cần không báo "No module named ...".)

---

## 3. Cấu hình MCP trong Cursor

### Cách mở cấu hình MCP

- **Cursor:** **File → Preferences → Cursor Settings** (hoặc **Ctrl+,**) → tìm **MCP** / **Model Context Protocol**.
- Hoặc mở file cấu hình MCP của Cursor (tùy phiên bản):
  - **Windows:** `%APPDATA%\Cursor\User\globalStorage\cursor.mcp\mcp.json`  
  - Hoặc trong project: `.cursor/mcp.json` (nếu dùng cấu hình theo workspace).

### Thêm server `mssql`

Trong phần **MCP Servers** (hoặc trong object `mcpServers` của file JSON), thêm:

```json
{
  "mcpServers": {
    "mssql": {
      "command": "python",
      "args": ["-m", "mssql_mcp_server"],
      "env": {
        "MSSQL_SERVER": "localhost",
        "MSSQL_PORT": "1433",
        "MSSQL_DATABASE": "BCDT",
        "MSSQL_USER": "sa",
        "MSSQL_PASSWORD": "YourPasswordHere",
        "MSSQL_ENCRYPT": "false"
      }
    }
  }
}
```

**Chỉnh lại cho đúng máy bạn:**

| Biến | Ý nghĩa | Ví dụ |
|------|---------|--------|
| `MSSQL_SERVER` | Tên máy hoặc địa chỉ SQL Server | `localhost` hoặc `DESKTOPLT` |
| `MSSQL_PORT` | Port TCP (instance mặc định thường 1433) | `1433` |
| `MSSQL_DATABASE` | Tên database | `BCDT` |
| `MSSQL_USER` | Login SQL | `sa` hoặc user riêng (vd: `mcp_bcdt`) |
| `MSSQL_PASSWORD` | Mật khẩu login | Mật khẩu thật, **không commit** file chứa password |

Nếu Cursor dùng **Python từ path khác** (vd `py`), có thể đổi:

```json
"command": "py",
"args": ["-3", "-m", "mssql_mcp_server"],
```

Lưu file cấu hình.

---

## 4. Khởi động lại Cursor

Đóng Cursor rồi mở lại (hoặc Reload Window) để nạp MCP. Sau khi mở lại, MCP **mssql** sẽ xuất hiện trong danh sách MCP và có các tool (vd: list tables, execute query).

---

## 5. Kiểm tra

- Trong Cursor: vào phần **MCP** / **Tools** (tùy giao diện) xem có server **mssql** và các tool không.
- Hoặc nhờ AI trong chat: *“Dùng MCP mssql list các bảng trong database BCDT”* / *“Chạy query SELECT TOP 5 * FROM BCDT_OrganizationType”*.

Nếu lỗi **kết nối**:

- Kiểm tra SQL Server đang chạy, TCP/IP bật, port 1433 (trong SQL Server Configuration Manager → TCP/IP → IP Addresses → IPAll).
- Kiểm tra `MSSQL_SERVER`, `MSSQL_PORT`, `MSSQL_USER`, `MSSQL_PASSWORD` đúng; tên database `BCDT` tồn tại.

---

## 6. Sửa lỗi: `connect() got an unexpected keyword argument 'encrypt'`

### Nguyên nhân
- Package dùng **pymssql** để kết nối SQL Server.
- **pymssql.connect()** chỉ nhận tham số **`encryption`** (giá trị: `'off'`, `'request'`, `'require'`), **không** nhận **`encrypt`**.
- Một số bản package (hoặc code path) truyền **`encrypt`** (từ env `MSSQL_ENCRYPT`) vào `connect(**config)` → pymssql báo lỗi.

### Giải pháp A — Patch file trong site-packages (khuyến nghị)

1. **Tìm file `server.py` của package:**
   - Chạy trong terminal:
     ```bash
     python -c "import mssql_mcp_server; print(mssql_mcp_server.__file__)"
     ```
   - Hoặc mở thư mục cài Python (vd: `C:\Users\<user>\AppData\Local\Programs\Python\Python3xx\Lib\site-packages\mssql_mcp_server\`), mở file **`server.py`**.

2. **Tìm hàm `get_db_config()`** — trong đó có đoạn build `config` (server, user, password, database, port, có thể có tds_version).

3. **Đảm bảo không truyền `encrypt` vào `connect()`:**
   - Trước khi `return config`, thêm (để xóa `encrypt` và dùng đúng tham số pymssql):
     ```python
     # pymssql chỉ nhận 'encryption', không nhận 'encrypt'
     if "encrypt" in config:
         enc = config.pop("encrypt")
         config["encryption"] = "off" if str(enc).lower() in ("false", "0", "no") else "request"
     ```
   - Hoặc chỉ cần **xóa** key `encrypt` nếu không cần bật encryption:
     ```python
     config.pop("encrypt", None)
     ```

4. **Lưu file**, **tắt hẳn Cursor** rồi **mở lại**, test lại MCP.

**Tài liệu tham chiếu (Giải pháp A):**
- [pymssql.connect() – Module reference](https://pymssql.readthedocs.io/en/stable/ref/pymssql.html): tham số `connect()` chỉ có **`encryption`** (giá trị `'off'`, `'request'`, `'require'`), không có `encrypt`.
- [RichardHan/mssql_mcp_server – server.py (get_db_config)](https://github.com/RichardHan/mssql_mcp_server/blob/main/src/mssql_mcp_server/server.py): nơi build `config` và gọi `pymssql.connect(**config)`.

---

### Giải pháp B — Cài từ GitHub (bản mới nhất, có thể đã sửa)

```bash
pip uninstall microsoft_sql_server_mcp -y
pip install git+https://github.com/RichardHan/mssql_mcp_server.git
```

Sau đó restart Cursor và test. Nếu vẫn lỗi → dùng Giải pháp A.

**Tài liệu tham chiếu (Giải pháp B):**
- [RichardHan/mssql_mcp_server – GitHub](https://github.com/RichardHan/mssql_mcp_server): repo gốc; cài trực tiếp từ main: `pip install git+https://github.com/RichardHan/mssql_mcp_server.git`.
- [microsoft-sql-server-mcp – PyPI](https://pypi.org/project/microsoft-sql-server-mcp/): bản đóng gói PyPI (có thể chậm hơn bản GitHub).

---

### Giải pháp C — Không set `MSSQL_ENCRYPT` (thử nhanh)

Trong cấu hình MCP (`mcp.json`), **xóa hẳn** hai dòng:
- `"MSSQL_ENCRYPT": "false"`
- `"MSSQL_TRUST_SERVER_CERTIFICATE": "true"`

Chỉ giữ: `MSSQL_SERVER`, `MSSQL_PORT`, `MSSQL_DATABASE`, `MSSQL_USER`, `MSSQL_PASSWORD`.  
Lưu, restart Cursor, test. Một số bản package chỉ thêm `encrypt` vào config khi có biến env này; bỏ đi có thể hết lỗi.

**Tài liệu tham chiếu (Giải pháp C):**
- [RichardHan/mssql_mcp_server – README (Configuration)](https://github.com/RichardHan/mssql_mcp_server#configuration): mô tả biến env `MSSQL_ENCRYPT`, `MSSQL_TRUST_SERVER_CERTIFICATE`; không set các biến này có thể tránh key `encrypt` bị đưa vào `config`.
- [Issue #18 – Error: connect() got an unexpected keyword argument 'encrypt'](https://github.com/RichardHan/mssql_mcp_server/issues/18): báo lỗi gốc và bối cảnh (config/env).

---

## 6.1. Seed dữ liệu test qua MCP

Để tạo form và submission mẫu cho **màn nhập liệu Excel**, có thể chạy seed qua MCP (tool `mcp_mssql_execute_sql`):

1. Đọc nội dung từng file (một batch mỗi file, không dùng `GO`):  
   `docs/script_core/sql/v2/seed_mcp_1_test_excel_entry.sql` → `seed_mcp_2_test_excel_full.sql` → `seed_mcp_3_more_submissions.sql`.
2. Thứ tự: 1 (form + data entry), 2 (form full + ColumnGroupName), 3 (thêm submission và dòng).

Chi tiết: [SEED_VIA_MCP.md](script_core/sql/v2/SEED_VIA_MCP.md), [README_SEED_TEST.md](script_core/sql/v2/README_SEED_TEST.md). PowerShell: chạy `Ensure-TestData.ps1` trong thư mục `docs/script_core/sql/v2/` nếu không dùng MCP.

---

## 7. Bảo mật (khuyến nghị)

- Không dùng `sa` lâu dài: tạo login SQL riêng (vd: `mcp_bcdt`), gán quyền tối thiểu trên DB **BCDT** (vd: `db_datareader`, `db_datawriter` nếu cần ghi).
- Không commit file cấu hình chứa mật khẩu vào Git; có thể dùng biến môi trường hoặc secret của Cursor (nếu hỗ trợ).

---

**Tham chiếu chung:**
- [RichardHan/mssql_mcp_server](https://github.com/RichardHan/mssql_mcp_server) – repo MCP SQL Server.
- [pymssql – Module reference](https://pymssql.readthedocs.io/en/stable/ref/pymssql.html) – tham số `connect()` (encryption).

**Version:** 1.1  
**Last Updated:** 2026-02-06 (thêm mục 6.1 Seed dữ liệu test qua MCP)
