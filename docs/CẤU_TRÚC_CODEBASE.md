# Cấu trúc codebase BCDT

Tài liệu mô tả cấu trúc thư mục và quy ước tổ chức code khi triển khai backend (.NET 8) và frontend (React). **Cấu trúc mẫu đã được tạo trong `src/`** — có thể bắt đầu phát triển theo cây thư mục dưới đây.

**Tham chiếu:** [03.DATABASE_SCHEMA.md](script_core/03.DATABASE_SCHEMA.md) — 44 bảng, 10 module.

---

## 1. Nguyên tắc

- **Mọi code nguồn** nằm trong thư mục **`src/`** (backend + frontend).
- **Backend:** Kiến trúc phân lớp (Clean Architecture): **API → Application → Domain → Infrastructure**.
- **Domain và Application** nhóm theo **10 module** của 03.DATABASE_SCHEMA để dễ map bảng và bảo trì.
- **Frontend** đặt trong **`src/bcdt-web/`** (cùng cấp với các project .NET).

---

## 2. Cây thư mục gợi ý

```
src/
├── BCDT.sln
│
├── BCDT.Api/                        # API Layer
│   ├── BCDT.Api.csproj
│   ├── Program.cs
│   ├── appsettings.json
│   ├── Controllers/
│   ├── Hubs/
│   ├── Middleware/
│   └── Extensions/
│
├── BCDT.Application/                # Application Layer
│   ├── BCDT.Application.csproj
│   ├── Common/                      # Result, ApiResponse, PagedList, CacheKeys
│   ├── DTOs/                        # Nhóm theo module (xem bảng 10 module)
│   ├── Services/                    # Nhóm theo module
│   ├── Validators/
│   └── Mappings/
│
├── BCDT.Domain/                     # Domain Layer
│   ├── BCDT.Domain.csproj
│   ├── Entities/                    # Nhóm theo 10 module (xem bảng)
│   ├── Enums/
│   └── Interfaces/
│
├── BCDT.Infrastructure/             # Infrastructure Layer
│   ├── BCDT.Infrastructure.csproj
│   ├── Persistence/                 # DbContext, Configurations
│   ├── Repositories/
│   ├── Services/                    # ExcelGenerator, DataBinding, SaveOrchestrator, ...
│   ├── Jobs/                        # Hangfire
│   └── External/
│
└── bcdt-web/                        # Frontend (React 18 + TypeScript + Vite + DevExtreme)
    ├── package.json
    ├── vite.config.ts
    ├── tsconfig.json
    └── src/
        ├── main.tsx
        ├── App.tsx
        ├── api/
        ├── hooks/
        ├── pages/
        ├── components/
        ├── routes/
        └── types/
```

---

## 3. Bảng 10 module (theo 03.DATABASE_SCHEMA)

| # | Module | Số bảng | Domain.Entities | Application (Services / DTOs) |
|---|--------|---------|-----------------|--------------------------------|
| 1 | Organization | 4 | Organization/ | Organization/ |
| 2 | Authorization | 9 | Authorization/ | Authorization/ |
| 3 | Authentication | 5 | Authentication/ | Authentication/ |
| 4 | Form Definition | 8 | Form/ | Form/ |
| 5 | Data Storage | 5 | Data/ | Data/ |
| 6 | Workflow | 5 | Workflow/ | Workflow/ |
| 7 | Reporting Period | 3 | ReportingPeriod/ | ReportingPeriod/ |
| 8 | Signature | 2 | Signature/ | Signature/ |
| 9 | Reference Data | 3 | ReferenceData/ | ReferenceData/ |
| 10 | Notification | 3 | Notification/ | Notification/ |

**Ví dụ entity theo module:**

- **Organization:** OrganizationType, Organization, User, UserOrganization.
- **Form:** FormDefinition, FormVersion, FormSheet, FormColumn, FormRow, FormCell, FormDataBinding, FormColumnMapping.
- **Data:** ReportSubmission, ReportPresentation, ReportDataRow, ReportSummary, ReportDataAudit.
- **Workflow:** WorkflowDefinition, WorkflowStep, WorkflowInstance, WorkflowApproval, FormWorkflowConfig.

---

## 4. Quy ước

### Domain (BCDT.Domain)

- Entity đặt trong thư mục tương ứng module: `Entities/Form/FormDefinition.cs`, `Entities/Data/ReportSubmission.cs`, …
- Namespace: `BCDT.Domain.Entities.Form`, `BCDT.Domain.Entities.Data`, …
- `BaseEntity.cs`, `Enums/`, `Interfaces/` có thể đặt ngoài (không theo module).

### Application (BCDT.Application)

- **Services:** Nhóm theo module: `Services/Form/`, `Services/Workflow/`, `Services/Data/`, …
- **DTOs:** Nhóm theo module: `DTOs/Form/`, `DTOs/Workflow/`, …
- **Validators:** Có thể theo module: `Validators/Form/`, …
- **Common:** Giữ ở ngoài (Result, ApiResponse, PagedList, CacheKeys).

### API (BCDT.Api)

- Controllers có thể giữ **phẳng**: FormsController, SubmissionsController, WorkflowController, … (map rõ resource).
- Hoặc nhóm: `Controllers/Form/`, `Controllers/Workflow/` (tùy quy ước team).
- **Config local:** Dùng [docs/appsettings.Development.example.json](appsettings.Development.example.json) làm mẫu; copy vào `src/BCDT.Api/` và đổi tên thành `appsettings.Development.json`; điền connection string và JWT secret; **không commit** file này (đã có trong .gitignore).

### Frontend (src/bcdt-web)

- Luôn nằm trong **`src/bcdt-web/`**.
- Cấu trúc: `api/`, `hooks/`, `pages/`, `components/`, `routes/`, `types/` theo [bcdt-frontend.mdc](../.cursor/rules/bcdt-frontend.mdc) và [02.KIEN_TRUC_TONG_QUAN.md](script_core/02.KIEN_TRUC_TONG_QUAN.md).

---

## 5. Tests

- **Rule:** [bcdt-testing.mdc](../.cursor/rules/bcdt-testing.mdc) — naming `should_Behavior_When_Condition`, Arrange–Act–Assert, Backend xUnit/Moq, Frontend Vitest + React Testing Library.
- **Vị trí:**
  - **Backend:** Thư mục **`tests/`** ở root repo (cùng cấp với `src/`): `tests/BCDT.Api.Tests/`, `tests/BCDT.Application.Tests/`. Hoặc đặt trong `src/`: `src/BCDT.Api.Tests/`, `src/BCDT.Application.Tests/` (tùy quy ước team).
  - **Frontend:** File test trong **`src/bcdt-web/src/`** với pattern **`**/*.test.tsx`** hoặc **`**/*.spec.tsx`**, hoặc thư mục **`src/bcdt-web/__tests__/`**.
- **Lệnh chạy:**
  - Backend: **`dotnet test`** (từ thư mục chứa solution, vd `src/`).
  - Frontend: **`npm run test`** (trong `src/bcdt-web`).

---

## 6. Tham chiếu

| Tài liệu | Nội dung |
|----------|----------|
| [03.DATABASE_SCHEMA.md](script_core/03.DATABASE_SCHEMA.md) | 44 bảng, 10 module, ERD |
| [02.KIEN_TRUC_TONG_QUAN.md](script_core/02.KIEN_TRUC_TONG_QUAN.md) | Stack, phân lớp, URLs |
| [.cursor/rules/bcdt-project.mdc](../.cursor/rules/bcdt-project.mdc) | Naming, patterns (BCDT_, /api/v1/, Result\<T\>) |
| [.cursor/rules/bcdt-testing.mdc](../.cursor/rules/bcdt-testing.mdc) | Convention test (naming, Arrange–Act–Assert, Backend/Frontend) |

---

**Version:** 1.0
