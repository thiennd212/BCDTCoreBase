# Runbook – Chạy dự án BCDT local

Hướng dẫn từng bước để clone, cấu hình và chạy backend + frontend trên máy dev.

---

## 1. Prerequisites

Cài đặt trước:

| Công cụ | Phiên bản | Ghi chú |
|---------|------------|--------|
| .NET SDK | 8.x | [Download](https://dotnet.microsoft.com/download) |
| Node.js | 20+ LTS | [Download](https://nodejs.org/) — dùng npm hoặc pnpm |
| SQL Server | 2022 / LocalDB / Express | Database BCDT |
| Redis | 7.x (tùy chọn) | Cache / SignalR (có thể bỏ qua cho dev đơn giản) |

Kiểm tra:

```bash
dotnet --version   # 8.x
node --version     # v20.x hoặc cao hơn
```

---

## 2. Clone & cấu trúc

- Clone repo (hoặc mở folder dự án).
- Cấu trúc code (khi đã tạo): `src/BCDT.Api`, `src/bcdt-web`, ... (xem [CẤU_TRÚC_CODEBASE.md](CẤU_TRÚC_CODEBASE.md)).

---

## 3. Database

1. Tạo database **BCDT** (nếu script không tự tạo).
2. Chạy lần lượt các file SQL trong **`docs/script_core/sql/v2/`** theo thứ tự **01 → 14** (xem [README script_core](script_core/README.md#thứ-tự-chạy)).
3. Có thể dùng SQL Server Management Studio hoặc `sqlcmd`.

### 3.1. Seed dữ liệu test (nhập liệu Excel)

Để có form và submission mẫu cho màn nhập liệu Excel:

- **PowerShell:** Trong `docs/script_core/sql/v2/` chạy `.\Ensure-TestData.ps1` (chạy các script seed theo thứ tự).
- **MCP (Cursor):** Dùng tool `mcp_mssql_execute_sql` chạy lần lượt nội dung các file: `seed_mcp_1_test_excel_entry.sql`, `seed_mcp_2_test_excel_full.sql`, `seed_mcp_3_more_submissions.sql`. Chi tiết: [SEED_VIA_MCP.md](script_core/sql/v2/SEED_VIA_MCP.md), [README_SEED_TEST.md](script_core/sql/v2/README_SEED_TEST.md).

---

## 4. Backend config

1. Copy **`docs/appsettings.Development.example.json`** vào **`src/BCDT.Api/`**.
2. Đổi tên thành **`appsettings.Development.json`**.
3. Sửa:
   - **ConnectionString** → trỏ tới SQL Server vừa tạo.
   - **JWT / SecretKey** → giá trị bí mật cho môi trường dev (không commit file này).

---

## 5. NuGet – Feed DevExpress (Aequitas)

Dự án dùng feed NuGet riêng của công ty cho DevExpress để tránh lỗi license:

- **File:** `nuget.config` (ở thư mục gốc solution).
- **Feed:** `https://devexpress.aequitas.dev/nuget` (key: `DevExpress-Aequitas`).
- Các gói `DevExpress.*` và `DX*` sẽ được lấy từ feed này.

Nếu feed yêu cầu xác thực (API key / user-password), cấu hình thêm (vd `dotnet nuget add source` với `--username`/`--password`, hoặc lưu token trong credential provider). Xem [NuGet Config](https://learn.microsoft.com/en-us/nuget/reference/nuget-config-file).

---

## 6. Chạy Backend

```bash
cd src/BCDT.Api
dotnet restore
dotnet run
```

- Xem URL trong console (vd `https://localhost:7001`, `http://localhost:5000`).
- Swagger: thường tại `https://localhost:7xxx/swagger`.

---

## 6.1. Trước khi build Backend (bắt buộc)

Khi **build** solution/API (`dotnet build`), nếu process **BCDT.Api** đang chạy thì file/DLL có thể bị lock và build báo lỗi (vd "The process cannot access the file ... BCDT.Api").

**Quy trình:** Trước khi chạy `dotnet build` cho backend, luôn **kiểm tra và hủy process API** nếu đang chạy:

**PowerShell (Windows):**
```powershell
Get-Process -Name "BCDT.Api" -ErrorAction SilentlyContinue | Stop-Process -Force
# Sau đó build
dotnet build src/BCDT.Api/BCDT.Api.csproj
```

**Nếu cần chạy API lại sau khi build:** `dotnet run --project src/BCDT.Api/BCDT.Api.csproj` (có thể chạy nền trong terminal khác).

---

## 7. Chạy Frontend

```bash
cd src/bcdt-web
npm install
npm run dev
```

- Mở URL Vite in ra (vd `http://localhost:5173`).
- Đảm bảo backend đang chạy nếu frontend gọi API.

### 7.1. E2E (Playwright)

- **Điều kiện:** Backend API chạy tại **`http://localhost:5080`** (profile `http`: `dotnet run --project src/BCDT.Api/BCDT.Api.csproj --launch-profile http`).
- **Chạy E2E:** Trong `src/bcdt-web`: `npm run test:e2e`.
- Chi tiết điều kiện, danh sách spec, checklist: [E2E_VERIFY.md](E2E_VERIFY.md).

---

## 8. Tài khoản mặc định (sau khi chạy seed)

- **Username:** admin  
- **Password:** Admin@123  
- Đổi mật khẩu ngay sau lần đăng nhập đầu.

---

## 8.1. Tài liệu người dùng và Demo

- **Hướng dẫn sử dụng:** [USER_GUIDE.md](USER_GUIDE.md) – Auth, Đơn vị, User, Form, Submission, Workflow, Dashboard, PDF, Thông báo.
- **Kịch bản demo:** [DEMO_SCRIPT.md](DEMO_SCRIPT.md) – Core flow, P8 (dòng/cột động), edge case; dùng cho UAT và bàn giao.

---

## 8.2. Kiểm tra cho AI (khi verify sau task)

Khi AI thực hiện phase Verify (rule always-verify-after-work):

1. **Build BE:** Trước khi build, tắt process BCDT.Api (mục 6.1); chạy `dotnet build src/BCDT.Api/BCDT.Api.csproj`.
2. **Chạy API / FE:** Theo mục 6 (Backend) và 7 (Frontend).
3. **E2E (nếu task đụng FE):** BE tại 5080; chạy `npm run test:e2e` trong `src/bcdt-web`; báo Pass/Fail từng spec theo [E2E_VERIFY.md](E2E_VERIFY.md) mục 5.

---

## 8.3. Static & cache nội bộ (khi deploy production – Perf-6, Perf-15)

Không dùng CDN công cộng; host static (build FE) trên IIS/nginx trong mạng nội bộ; cấu hình Cache-Control cho file có hash; reverse proxy cache. Chi tiết và checklist: [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md) mục 0.6, 3.4, "Triển khai Perf-6", **"Triển khai Perf-15 – Reverse proxy cache" (3.4.2)**, 5.8 và 5.15.

---

## 9. Troubleshooting nhanh

| Vấn đề | Gợi ý |
|--------|--------|
| **Build BE báo lỗi file/DLL bị lock** | Process BCDT.Api đang chạy. Hủy process rồi build lại: `Get-Process -Name "BCDT.Api" -ErrorAction SilentlyContinue \| Stop-Process -Force` (xem mục 6.1). |
| Backend không kết nối DB | Kiểm tra connection string, SQL Server đang chạy, đã chạy đủ script 01–14. |
| 401 Unauthorized | Kiểm tra JWT config; đăng nhập lại để lấy token mới. |
| Frontend không gọi được API | Kiểm tra CORS, base URL API trong env (vd `VITE_API_BASE`). |
| Thiếu Redis | Tắt cache/Redis trong config dev hoặc chạy Redis local. |

---

## 10. Triển khai Production / Cả nước

Rà soát đầy đủ và checklist cho triển khai production quy mô cả nước: **[REVIEW_PRODUCTION_CA_NUOC.md](REVIEW_PRODUCTION_CA_NUOC.md)**.

### 10.1. Production – Biến môi trường bắt buộc

**Không được** commit connection string, JWT secret hoặc giá trị nhạy cảm vào repo. Production dùng **biến môi trường** (hoặc secret store: Azure Key Vault, HashiCorp Vault, …). Tên biến theo convention ASP.NET Core (`__` thay cho `:` trong section).

| Tên biến | Mô tả | Bắt buộc | Ghi chú |
|----------|--------|----------|---------|
| `ConnectionStrings__DefaultConnection` | Chuỗi kết nối SQL Server (primary) | **Có** | Ứng dụng throw nếu thiếu. |
| `Jwt__SecretKey` | Khóa bí mật ký JWT (đủ dài, ví dụ 256-bit) | **Có** | Section `Jwt`; không dùng giá trị mặc định dev. |
| `Jwt__Issuer` | Issuer claim (vd. `BCDT`) | Khuyến nghị | Mặc định từ config base nếu không set. |
| `Jwt__Audience` | Audience claim (vd. `BCDT-Users`) | Khuyến nghị | Mặc định từ config base nếu không set. |
| `Cors__AllowedOrigins` | Danh sách origin frontend (vd. `https://bcdt.example.vn`) | **Có** | Production không dùng `*` khi có credential. Mảng: `Cors__AllowedOrigins__0`, `__1`, ... |
| `Hangfire__ServerEnabled` | `true` hoặc `false` | Khuyến nghị | Chỉ **một** instance sau LB đặt `true`; instance còn lại `false`. Mặc định `true`. |
| `ConnectionStrings__Redis` | Chuỗi kết nối Redis (khi scale > 1 instance) | Khi scale > 1 | Single/Sentinel/Cluster: xem DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG. |
| `ConnectionStrings__ReadReplica` | Chuỗi kết nối read replica (tùy chọn) | Không | Khi có: Dashboard/query chỉ đọc dùng replica; lưu ý RLS (REVIEW_PRODUCTION_CA_NUOC R1). |

**Ví dụ (PowerShell, không đưa vào repo):**
```powershell
$env:ConnectionStrings__DefaultConnection = "Server=...;Database=BCDT;User Id=...;Password=...;Encrypt=...;"
$env:Jwt__SecretKey = "<secret-256-bit>"
$env:Cors__AllowedOrigins__0 = "https://bcdt.example.vn"
$env:Hangfire__ServerEnabled = "false"
```

**Ví dụ (Linux/macOS):**
```bash
export ConnectionStrings__DefaultConnection="Server=...;Database=BCDT;..."
export Jwt__SecretKey="<secret-256-bit>"
export Cors__AllowedOrigins__0="https://bcdt.example.vn"
export Hangfire__ServerEnabled="false"
```

### 10.2. Tóm tắt cấu hình Production

| Nội dung | Ghi chú |
|----------|--------|
| **Secrets** | Không commit connection string, JWT secret. Dùng biến môi trường hoặc secret store (mục 10.1). |
| **Biến bắt buộc** | Xem bảng mục **10.1**. |
| **CORS** | `Cors:AllowedOrigins` = origin frontend thật (không dùng `*` với credential). |
| **Load balancer** | Health probe GET /health; nhiều instance API; chỉ **một** instance có `Hangfire:ServerEnabled = true`. |
| **Redis** | Khi chạy > 1 instance: bắt buộc cấu hình Redis; thêm health check Redis (xem REVIEW_TRIEN_KHAI_PRODUCT, REVIEW_PRODUCTION_CA_NUOC). |
| **RLS + ReadReplica** | Khi bật ReadReplica: Dashboard không dùng replica cho query có RLS (hoặc set session context trên replica). |
| **Backup & DR** | Tài liệu hóa chính sách backup DB, RPO/RTO; dữ liệu và hạ tầng trong nước theo quy định. |
| **Timeout (R10, Prod-14)** | Kestrel Limits: RequestHeadersTimeout (1 phút), KeepAliveTimeout (2 phút) trong appsettings; API dài (workbook-data, aggregate) lan truyền CancellationToken. Khi cần giới hạn thời gian request toàn bộ: cấu hình timeout tại reverse proxy / load balancer (nginx, IIS). |
| **Dữ liệu trong nước (R15, Prod-15)** | Đảm bảo SQL Server, Redis, máy chủ ứng dụng (API, FE) đặt trong lãnh thổ Việt Nam; không đưa dữ liệu ra nước ngoài trừ khi có phê duyệt. Xem mục **10.5**. |

### 10.3. Checklist triển khai Production (tóm tắt)

Đối chiếu với [REVIEW_PRODUCTION_CA_NUOC.md](REVIEW_PRODUCTION_CA_NUOC.md) mục 5. Trước khi đưa production cả nước, Ops nên rà:

| # | Nội dung | Tham chiếu |
|---|----------|------------|
| 1 | **Secrets:** Không commit; dùng biến môi trường hoặc secret store. RUNBOOK liệt kê biến Production. | Mục 10.1 |
| 2 | **Deploy:** Build ứng dụng; cấu hình biến môi trường (10.1); khởi động API. | Mục 10.1, 6 |
| 3 | **Health:** Endpoint GET /health cho load balancer probe (DB check; khi dùng Redis thì thêm health Redis). | Program.cs AddHealthChecks; REVIEW_PRODUCTION_CA_NUOC Prod-6 |
| 4 | **Load balancer:** Nhiều instance API sau LB; health probe GET /health; không bắt buộc sticky session (JWT stateless). | Mục 10.2; DE_XUAT Perf-19 |
| 5 | **Hangfire:** Chỉ **một** instance có `Hangfire__ServerEnabled = true`; instance còn lại `false`. | Mục 10.1, 10.2 |
| 6 | **Redis:** Khi chạy > 1 instance: bắt buộc cấu hình `ConnectionStrings__Redis`. | Mục 10.1, 10.2 |
| 7 | **RLS + ReadReplica:** Dashboard dùng primary (đã sửa Prod-3). Khi bật ReadReplica: không dùng replica cho Dashboard. | Mục 10.2; Prod-3 |
| 8 | **Giới hạn:** List API max pageSize = 500 (Prod-1). | REVIEW_PRODUCTION_CA_NUOC R8 |
| 9 | **Backup & DR:** Tài liệu hóa chính sách backup DB, RPO/RTO; kịch bản khôi phục. | Mục **10.4**; Prod-9 |
| 10 | **CORS:** AllowedOrigins = origin frontend thật; không dùng `*` với credential. | Mục 10.1 |
| 11 | **Timeout (R10):** Kestrel Limits đã cấu hình (Perf-4); API dài lan truyền CancellationToken. LB/proxy timeout khi cần. | Mục 10.2; Prod-14 |
| 12 | **Dữ liệu trong nước (R15):** DB, Redis, server ứng dụng đặt trong nước; không dùng dịch vụ lưu/xử lý dữ liệu ra nước ngoài trừ khi được phép. | Mục **10.5**; Prod-15 |

Chi tiết rủi ro, đề xuất ưu tiên và checklist 15 mục: [REVIEW_PRODUCTION_CA_NUOC.md](REVIEW_PRODUCTION_CA_NUOC.md) mục 4, 5.

### 10.4. Backup & DR (Prod-9, R14)

Tài liệu hóa để Ops triển khai và vận hành đúng chuẩn production cả nước.

| Nội dung | Gợi ý / Mô tả |
|----------|----------------|
| **Phạm vi backup** | Database SQL Server (BCDT); cấu hình ứng dụng (biến môi trường / secret store) lưu riêng, không backup qua DB. |
| **Tần suất** | Full backup: ít nhất hàng ngày (hoặc theo chính sách đơn vị). Differential/transaction log: tùy RPO. |
| **Retention** | Giữ tối thiểu 7–30 ngày (hoặc theo quy định); backup off-site hoặc copy sang hạ tầng khác để DR. |
| **RPO (Recovery Point Objective)** | Mức tổn thất dữ liệu chấp nhận được (vd. &lt; 1 giờ → cần backup log thường xuyên). |
| **RTO (Recovery Time Objective)** | Thời gian phục hồi dịch vụ mục tiêu (vd. &lt; 4 giờ); ảnh hưởng đến kế hoạch restore và HA. |
| **Kịch bản khôi phục** | 1) Xác định bản backup gần nhất đủ RPO. 2) Restore DB lên server (primary hoặc standby). 3) Kiểm tra integrity (script, ứng dụng đọc/ghi). 4) Cập nhật connection string nếu đổi server. 5) Khởi động lại ứng dụng; kiểm tra GET /health và luồng chính. |
| **Lưu ý** | Hangfire state lưu trong DB → restore DB đủ cho job queue. Redis (nếu dùng): xem xét persistence hoặc chấp nhận mất cache khi DR. |

Chi tiết triển khai cụ thể (tool, schedule, script) do đơn vị vận hành quyết định theo hạ tầng (SQL Server backup/maintenance plan, replica, Always On, v.v.).

### 10.5. Dữ liệu trong nước (R15, Prod-15)

Tuân thủ quy định: dữ liệu và hạ tầng phục vụ hệ thống BCDT đặt trong lãnh thổ Việt Nam; không đưa dữ liệu ra nước ngoài trừ khi có phê duyệt theo quy định.

| Thành phần | Yêu cầu / Checklist |
|------------|---------------------|
| **Database (SQL Server)** | Máy chủ / instance SQL Server chạy trong nước (data center Việt Nam hoặc hạ tầng được phê duyệt). Connection string trỏ tới server trong nước. |
| **Redis** | Khi dùng Redis (scale > 1 instance): instance Redis đặt trong nước; không dùng Redis managed từ nhà cung cấp đám mây nước ngoài trừ khi có phê duyệt. |
| **Máy chủ ứng dụng** | API (BCDT.Api), frontend (static), Hangfire worker chạy trên server / container trong nước. |
| **Backup / DR** | Bản backup và hạ tầng khôi phục (replica, standby) trong nước hoặc theo quy định. |
| **Lưu ý** | Không dùng CDN/dịch vụ đám mây công cộng nước ngoài cho dữ liệu hoặc tài nguyên nhạy cảm (xem DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG). Nếu có ngoại lệ: phải có văn bản phê duyệt và đảm bảo tuân thủ. |

Trước khi đưa production cả nước, đơn vị vận hành xác nhận từng hạng mục trên (checklist mục 10.3 #12).

---

**Version:** 1.7  
**Last Updated:** 2026-02-26 (Prod-15: mục 10.5 Dữ liệu trong nước R15)
