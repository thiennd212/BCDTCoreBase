# Changelog

Mọi thay đổi đáng chú ý của dự án BCDT sẽ được ghi lại trong file này.

Format dựa trên [Keep a Changelog](https://keepachangelog.com/vi/1.1.0/), versioning theo [Semantic Versioning](https://semver.org/lang/vi/).

## [Unreleased]

### Added
- **Cấu trúc codebase `src/`:** BCDT.sln, BCDT.Api (net8, Swagger, Controllers/Middleware/Hubs/Extensions), BCDT.Application (Common, DTOs, Services, Validators, Mappings theo module), BCDT.Domain (Entities/10 module, Enums, Interfaces), BCDT.Infrastructure (Persistence, Repositories, Services, Jobs, External), bcdt-web (Vite + React + TypeScript, api/hooks/pages/components/routes/types). README trong src/.
- 04.GIAI_PHAP_KY_THUAT: mục 7 API Response & Error Format (schema, mã lỗi, ví dụ)
- 04.GIAI_PHAP_KY_THUAT: mục 8 Security Checklist (8 mục kiểm tra khi review)
- CONTRIBUTING.md: branch, commit, test, CHANGELOG, link từ docs/script_core/README
- docs/RUNBOOK.md: Prerequisites, DB, config, chạy API & Web local, troubleshooting
- docs/script_core/README: Prerequisites, bước 4–5 chạy Backend/Frontend, link RUNBOOK & CONTRIBUTING

### Changed
- (Thay đổi hiện có sẽ liệt kê tại đây)

### Deprecated
- (Tính năng sắp bị loại bỏ)

### Removed
- (Tính năng đã loại bỏ)

### Fixed
- (Sửa lỗi)

### Security
- (Cập nhật bảo mật)

---

## [0.1.0] - 2026-02-03

### Added
- Tài liệu yêu cầu, kiến trúc, schema DB (44 bảng), giải pháp kỹ thuật
- SQL v2: organization, authorization, form, data, workflow, RLS, seed
- WORKFLOW_GUIDE: workflows, skills, agents, Task → Skill/Agent
- CẤU_TRÚC_CODEBASE: src/, 10 module, tests
- Rules: senior-fullstack-standards, bcdt-project, bcdt-testing
- Skills: sql-migration, entity-crud, api-endpoint, react-page, form-builder, hangfire-jobs, dashboard-charts, test, workflow-config, external-api
- Agents: workflow-designer, data-binding, hybrid-storage, auth-expert, form-analyst, excel-generator, aggregation-builder, notification, org-admin, report-period, submission-processor, reference-data, auth-extension, digital-signature
- docs/appsettings.Development.example.json, .gitignore
- 04.GIAI_PHAP_KY_THUAT: RLS & Session Context, SaveOrchestrator transaction

[Unreleased]: https://github.com/your-org/BCDTCoreBase/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/your-org/BCDTCoreBase/releases/tag/v0.1.0
