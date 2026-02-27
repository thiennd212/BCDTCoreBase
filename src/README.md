# BCDT – Source code

Cấu trúc theo [docs/CẤU_TRÚC_CODEBASE.md](../docs/CẤU_TRÚC_CODEBASE.md).

## Backend (.NET 8)

- **BCDT.Api** – Web API, Controllers, Middleware, Hubs
- **BCDT.Application** – Services, DTOs, Validators, Mappings (Common: Result, ApiResponse)
- **BCDT.Domain** – Entities (10 module), Enums, Interfaces
- **BCDT.Infrastructure** – Persistence, Repositories, Services, Jobs, External

**Chạy API:**

```bash
cd BCDT.Api
dotnet run
```

Swagger: `https://localhost:7xxx/swagger` (xem output hoặc `Properties/launchSettings.json`).

**Config local:** Copy `docs/appsettings.Development.example.json` vào `BCDT.Api/`, đổi tên thành `appsettings.Development.json`, điền connection string và JWT secret.

## Frontend (React 18 + TypeScript + Vite)

- **bcdt-web** – Vite + React + TypeScript. Thư mục: `api/`, `hooks/`, `pages/`, `components/`, `routes/`, `types/`.

**Chạy Web:**

```bash
cd bcdt-web
npm install
npm run dev
```

## Build solution

```bash
dotnet build
```

## Tham chiếu

- Database: chạy SQL `docs/script_core/sql/v2/` 01→14
- Runbook: [docs/RUNBOOK.md](../docs/RUNBOOK.md)
