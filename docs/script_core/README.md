# BCDT - Hệ thống Báo cáo Điện tử Động

## Tổng quan

Hệ thống Báo cáo Điện tử Động (BCDT) là nền tảng **tổng quát** cho phép:
- Định nghĩa động các biểu mẫu báo cáo Excel
- Nhập liệu trực tiếp trên Excel Web
- Quy trình phê duyệt linh hoạt 1-5 cấp
- Tổng hợp báo cáo tự động
- Triển khai toàn quốc (63 tỉnh, 5000+ users)

## Nguyên tắc thiết kế

| Nguyên tắc | Mô tả |
|------------|-------|
| **EXCEL-FIRST** | Mọi tương tác qua Excel trên Web |
| **NO FORM INPUT** | Không dùng form nhập liệu truyền thống |
| **CONFIG-DRIVEN** | Định nghĩa động 100% qua cấu hình |
| **DESIGN FOR SCALE** | Thiết kế sẵn cho triển khai toàn quốc |
| **PLUGIN ARCH** | Mở rộng bằng plugin, không sửa core |

## Cấu trúc thư mục

```
docs/script_core/
├── sql/
│   ├── legacy/                     # SQL gốc (tham khảo)
│   │   ├── 1.script_struct_bieu_mau.sql
│   │   ├── 2.script_struct_bieu_mau_tong_hop.sql
│   │   ├── 3.script_struct_du_lieu_bieu_mau.sql
│   │   ├── 4.script_function.sql
│   │   └── 5.script_store_procedure.sql
│   │
│   └── v2/                         # SQL mới (44 bảng)
│       ├── 01.organization.sql     # Tổ chức (4 bảng)
│       ├── 02.authorization.sql    # Phân quyền (9 bảng)
│       ├── 03.authentication.sql   # Xác thực (5 bảng)
│       ├── 04.form_definition.sql  # Biểu mẫu (8 bảng)
│       ├── 05.data_storage.sql     # Lưu trữ (5 bảng)
│       ├── 06.workflow.sql         # Quy trình (5 bảng)
│       ├── 07.reporting_period.sql # Chu kỳ (3 bảng)
│       ├── 08.signature.sql        # Chữ ký (2 bảng)
│       ├── 09.reference_data.sql   # Tham chiếu (3 bảng)
│       ├── 10.notification.sql     # Thông báo (3 bảng)
│       ├── 11.indexes.sql          # Indexes
│       ├── 12.row_level_security.sql # RLS
│       ├── 13.functions.sql        # Functions
│       └── 14.seed_data.sql        # Dữ liệu khởi tạo
│
├── README.md                       # File này
├── 01.YEU_CAU_HE_THONG.md         # Yêu cầu hệ thống
├── 02.KIEN_TRUC_TONG_QUAN.md      # Kiến trúc
├── 03.DATABASE_SCHEMA.md          # Database schema
├── 04.GIAI_PHAP_KY_THUAT.md       # Giải pháp kỹ thuật
├── 05.EXTENSION_POINTS.md         # Extension points
├── 06.KE_HOACH_MVP.md             # Kế hoạch MVP
└── 07.DANH_GIA_TONG_HOP.md        # Đánh giá tổng hợp
```

## Tài liệu

| File | Mô tả |
|------|-------|
| [01.YEU_CAU_HE_THONG.md](01.YEU_CAU_HE_THONG.md) | 104 yêu cầu hệ thống (30 BM + 22 FR + 20 NFR + 32 Aspects) |
| [02.KIEN_TRUC_TONG_QUAN.md](02.KIEN_TRUC_TONG_QUAN.md) | Kiến trúc tổng quan, layers, HA/DR |
| [03.DATABASE_SCHEMA.md](03.DATABASE_SCHEMA.md) | 44 bảng database với ERD |
| [04.GIAI_PHAP_KY_THUAT.md](04.GIAI_PHAP_KY_THUAT.md) | Giải pháp kỹ thuật chi tiết |
| [05.EXTENSION_POINTS.md](05.EXTENSION_POINTS.md) | Plugin architecture (Auth, 2FA, Signature) |
| [06.KE_HOACH_MVP.md](06.KE_HOACH_MVP.md) | Kế hoạch MVP 17 tuần |
| [07.DANH_GIA_TONG_HOP.md](07.DANH_GIA_TONG_HOP.md) | Ma trận đánh giá 104 yêu cầu |
| [../CẤU_TRÚC_CODEBASE.md](../CẤU_TRÚC_CODEBASE.md) | Cấu trúc codebase (src/, 10 module) |
| [../RUNBOOK.md](../RUNBOOK.md) | Runbook: Prerequisites, DB, config, chạy API & Web local |
| [../../CHANGELOG.md](../../CHANGELOG.md) | Lịch sử thay đổi phiên bản (Keep a Changelog) |
| [../../CONTRIBUTING.md](../../CONTRIBUTING.md) | Hướng dẫn đóng góp (branch, commit, test, CHANGELOG) |
| [../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md](../TONG_HOP_TIEN_DO_VA_CONG_VIEC_TIEP_THEO.md) | Tổng hợp tiến độ và công việc tiếp theo (để duyệt) |

## Database setup

Script tạo schema **44 bảng** nằm trong thư mục:

- **Từ root repo:** `docs/script_core/sql/v2/`
- **Trong thư mục này:** `sql/v2/`

### Thứ tự chạy

Chạy lần lượt các file SQL theo thứ tự **01 → 14**:

| # | File | Mô tả |
|---|------|-------|
| 1 | 01.organization.sql | Cơ cấu tổ chức (4 bảng) |
| 2 | 02.authorization.sql | Phân quyền RBAC (9 bảng) |
| 3 | 03.authentication.sql | Xác thực (5 bảng) |
| 4 | 04.form_definition.sql | Định nghĩa biểu mẫu (8 bảng) |
| 5 | 05.data_storage.sql | Hybrid 2-Layer storage (5 bảng) |
| 6 | 06.workflow.sql | Workflow phê duyệt (5 bảng) |
| 7 | 07.reporting_period.sql | Chu kỳ báo cáo (3 bảng) |
| 8 | 08.signature.sql | Chữ ký số (2 bảng) |
| 9 | 09.reference_data.sql | Dữ liệu tham chiếu (3 bảng) |
| 10 | 10.notification.sql | Thông báo (3 bảng) |
| 11 | 11.indexes.sql | Indexes |
| 12 | 12.row_level_security.sql | Row-Level Security |
| 13 | 13.functions.sql | Functions |
| 14 | 14.seed_data.sql | Dữ liệu seed |

### Lưu ý

- Tạo database **BCDT** trước (nếu script không tự tạo).
- Chạy bằng SQL Server Management Studio hoặc `sqlcmd` (SQL Server LocalDB / Express / Developer).

---

## Quick Start

Chi tiết từng bước: [RUNBOOK.md](../RUNBOOK.md).

### Prerequisites (khi đã có source)

| Công cụ | Phiên bản gợi ý |
|---------|------------------|
| .NET SDK | 8.x |
| Node.js | 20+ (LTS) |
| SQL Server | 2022 hoặc LocalDB / Express |
| Redis | 7.x (nếu dùng cache/real-time) |

### 1. Tạo Database

Chạy các file trong `docs/script_core/sql/v2/` theo thứ tự 01 → 14 (xem bảng trên).

### 2. Tài khoản mặc định

- **Username:** admin
- **Password:** Admin@123 (thay đổi ngay sau khi đăng nhập)
- **Role:** System Administrator

### 3. Backend config (khi đã có source)

- Copy **`docs/appsettings.Development.example.json`** vào thư mục project API (vd **`src/BCDT.Api/`**), đổi tên thành **`appsettings.Development.json`**.
- Điền **connection string** và **JWT secret** (SecretKey) phù hợp môi trường local.
- **Không commit** `appsettings.Development.json` (đã có trong .gitignore).

### 4. Chạy Backend (khi đã có source)

```bash
cd src/BCDT.Api
dotnet run
```

API thường chạy tại `https://localhost:7xxx` hoặc `http://localhost:5xxx` (xem output hoặc `launchSettings.json`).

### 5. Chạy Frontend (khi đã có source)

```bash
cd src/bcdt-web
npm install
npm run dev
```

Mở URL mà Vite in ra (vd `http://localhost:5173`).

## Technology Stack

| Layer | Technology |
|-------|------------|
| Frontend | React 18 + TypeScript + DevExtreme |
| Excel Component | DevExpress Spreadsheet |
| Backend | .NET 8 Web API |
| Database | SQL Server 2022 |
| Cache | Redis |
| Real-time | SignalR |

## Thống kê

- **Database:** 44 bảng
- **Yêu cầu:** 104 items (100% đáp ứng)
- **Timeline MVP:** 17 tuần
- **Team:** 9-11 người

---

**Version:** 2.0  
**Last Updated:** 2026-02-03
