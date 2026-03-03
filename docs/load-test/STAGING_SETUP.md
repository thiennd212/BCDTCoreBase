# BCDT Load Test – Staging Environment Setup (P5–P6)

**Mục đích:** Hướng dẫn setup staging server để chạy P5 Stress (500 VU) và P6 Spike (1000 VU).
**Lý do cần staging riêng:** Dev machine (laptop) bị giới hạn phần cứng → P7 Soak cho thấy avg=20s
với 100 VU; 500 VU trên dev machine sẽ cho kết quả không đại diện production.

---

## 1. Yêu cầu phần cứng Staging Server

| Thành phần | Tối thiểu | Khuyến nghị |
|------------|-----------|-------------|
| CPU | 4 core | 8 core (để tách biệt BCrypt CPU với query DB) |
| RAM | 8 GB | 16 GB |
| Ổ cứng | 50 GB SSD | 100 GB SSD |
| Network | LAN nội bộ | Gigabit LAN (giữa load test machine và staging) |
| OS | Windows Server 2022 / Ubuntu 22.04 | Windows Server 2022 |

> **Quan trọng:** Máy chạy k6 (load test client) và staging server phải là **hai máy riêng biệt**.
> Chạy k6 cùng máy với BE sẽ gây CPU contention → kết quả sai lệch.

---

## 2. Phần mềm cần cài trên Staging Server

### 2.1 SQL Server

```powershell
# Option A: SQL Server 2022 Developer Edition (miễn phí cho test)
# Tải từ: https://www.microsoft.com/en-us/sql-server/sql-server-downloads
# Cấu hình sau khi cài:
# - Bật TCP/IP trên port 1433 (SQL Server Configuration Manager)
# - Tạo login: sa / <mật khẩu mạnh>
# - Tắt Windows Firewall cho port 1433 (hoặc thêm inbound rule)
```

```sql
-- Sau khi cài, tạo database:
CREATE DATABASE BCDT COLLATE Vietnamese_CI_AS;
GO
```

### 2.2 .NET 8 Runtime

```powershell
# Cài .NET 8 SDK hoặc Runtime
winget install Microsoft.DotNet.Runtime.8
# Verify:
dotnet --version  # phải là 8.x
```

### 2.3 Redis (tùy chọn – chỉ cần khi test multi-instance)

```powershell
# Cho P5 đơn instance: bỏ qua Redis
# Nếu muốn test với Redis:
winget install Redis.Redis
```

---

## 3. Deploy BCDT lên Staging

### 3.1 Publish từ dev machine

```bash
# Từ dev machine:
cd D:/00.AEQUITAS/MOF/BCDT/BCDTCoreBase/src/BCDT.Api
dotnet publish -c Release -o ./publish
# Copy toàn bộ thư mục ./publish sang staging server (qua network share hoặc SCP)
```

### 3.2 Cấu hình appsettings trên Staging

Tạo file `appsettings.Staging.json` (KHÔNG commit vào repo) trên staging server:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=localhost,1433;Database=BCDT;User Id=sa;Password=<STRONG_PASSWORD>;TrustServerCertificate=True;Max Pool Size=1000;Min Pool Size=20;Connection Timeout=60;"
  },
  "Jwt": {
    "SecretKey": "<STRONG_256_BIT_SECRET>",
    "Issuer": "BCDT",
    "Audience": "BCDT-Users",
    "AccessTokenExpirationMinutes": 60,
    "RefreshTokenExpirationDays": 30
  },
  "Cors": {
    "AllowedOrigins": ["http://localhost:5173"]
  },
  "RateLimiting": {
    "PermitLimit": 100000,
    "WindowSeconds": 60
  },
  "Hangfire": {
    "ServerEnabled": true
  }
}
```

> **Key differences vs dev:**
> - `Max Pool Size=1000` (dev=500, staging P5 cần 1000)
> - `PermitLimit=100000` (dev=10000, P5 có 500 VU × nhiều request/iter)
> - `Min Pool Size=20` (warm up pool sẵn)

### 3.3 Setup biến môi trường (PowerShell)

```powershell
# Thay vì appsettings.Staging.json, có thể dùng biến môi trường:
$env:ASPNETCORE_ENVIRONMENT = "Staging"
$env:ConnectionStrings__DefaultConnection = "Server=localhost,1433;Database=BCDT;User Id=sa;Password=<PWD>;TrustServerCertificate=True;Max Pool Size=1000;Min Pool Size=20;Connection Timeout=60;"
$env:Jwt__SecretKey = "<SECRET>"
$env:RateLimiting__PermitLimit = "100000"
```

### 3.4 Chạy SQL scripts để tạo DB

```bash
# Chạy toàn bộ scripts theo thứ tự từ docs/script_core/sql/v2/
# Xem README trong thư mục đó để biết thứ tự đúng
```

### 3.5 Khởi động BE

```powershell
# Trên staging server, trong thư mục publish:
$env:ASPNETCORE_ENVIRONMENT = "Staging"
$env:ConnectionStrings__DefaultConnection = "..."
dotnet BCDT.Api.dll --urls "http://0.0.0.0:5080"
```

Verify:
```bash
curl http://staging-ip:5080/health
# Expected: Healthy
```

---

## 4. Cấu hình k6 trên Load Test Machine

### 4.1 Cài k6

```powershell
# Windows:
winget install k6.k6
# Verify:
k6 version
```

### 4.2 Cập nhật BASE_URL trong common.js

```javascript
// docs/load-test/common.js
export const BASE_URL = 'http://STAGING_SERVER_IP:5080'
// Thay STAGING_SERVER_IP bằng IP thực của staging server
```

> **Không commit** thay đổi này vào repo (hoặc dùng environment variable k6).

### 4.3 Cách dùng biến môi trường k6

```bash
# Tốt hơn: truyền BASE_URL qua biến môi trường thay vì sửa file
k6 run --vus 500 --duration 20m \
  -e BASE_URL=http://STAGING_IP:5080 \
  docs/load-test/scenarios.js
```

Cập nhật `common.js` để đọc biến:
```javascript
export const BASE_URL = __ENV.BASE_URL || 'http://localhost:5080'
```

---

## 5. Checklist trước khi chạy P5

```
Pre-flight checklist P5 (500 VU, 20 phút):

Staging Server:
□ SQL Server running, DB BCDT tồn tại với đủ dữ liệu seed
□ BE BCDT.Api running trên port 5080
□ GET http://staging-ip:5080/health → "Healthy"
□ Max Pool Size=1000 trong connection string
□ PermitLimit=100000 trong RateLimiting config
□ ~10 GB RAM free trên staging server

Load Test Machine (máy riêng):
□ k6 cài đúng (k6 version)
□ BASE_URL trỏ đúng staging server
□ Network ping staging < 5ms (nếu cùng LAN)
□ Không chạy BE trên cùng máy với k6

Monitoring (để quan sát trong lúc chạy):
□ SQL Server Activity Monitor mở (xem active connections, CPU, memory)
□ Task Manager / htop trên staging (xem CPU% của dotnet process)
□ Ghi chú thời gian bắt đầu để correlate với metrics

Sau khi chạy:
□ Ghi kết quả vào docs/load-test/W17_LOAD_TEST_CCU.md mục P5
□ Screenshot SQL Server Activity Monitor (peak connections)
□ Rollback BASE_URL về localhost nếu đã sửa common.js
```

---

## 6. Lệnh chạy P5

```bash
# P5 – Stress (500 VU, 20 phút):
k6 run --vus 500 --duration 20m \
  -e BASE_URL=http://STAGING_IP:5080 \
  docs/load-test/scenarios.js

# P6 – Spike (1000 VU, 10 phút) – cần MUST-ASK riêng:
# k6 run --vus 1000 --duration 10m \
#   -e BASE_URL=http://STAGING_IP:5080 \
#   docs/load-test/scenarios.js
```

---

## 7. Cập nhật common.js để nhận BASE_URL từ env

```javascript
// docs/load-test/common.js – thêm dòng này:
export const BASE_URL = __ENV.BASE_URL || 'http://localhost:5080'
```

Thay đổi nhỏ này cho phép chạy test trên bất kỳ môi trường nào mà không sửa file.

---

## 8. Tham chiếu

| Doc | Nội dung |
|-----|---------|
| `docs/RUNBOOK.md` mục 10.1 | Biến môi trường bắt buộc |
| `docs/RUNBOOK.md` mục 10.3 | Checklist deployment |
| `docs/load-test/W17_LOAD_TEST_CCU.md` | Kết quả CCU hiện tại |
| `docs/appsettings.Development.example.json` | Mẫu config dev (tham khảo) |
