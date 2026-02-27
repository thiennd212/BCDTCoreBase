---
task_ref: "Task 2.3 – CI/CD Pipeline (GitHub Actions)"
agent: "Agent_DevOps"
status: DONE
timestamp: 2026-02-27
---

## Kết quả thực thi

- Tạo `.github/workflows/ci.yml`: trigger `push` và `pull_request` vào branch `main`; job `build-backend` (ubuntu-latest, checkout → setup .NET 8 → dotnet restore → dotnet build src/BCDT.Api/BCDT.Api.csproj --no-restore --configuration Release); job `build-frontend` (ubuntu-latest, checkout → setup Node 20, cache npm → npm ci → npm run build trong src/bcdt-web). Hai job chạy song song.
- Thêm mục **8.4. CI/CD (GitHub Actions)** vào `docs/RUNBOOK.md`: mô tả trigger, lệnh build BE/FE, đường dẫn file workflow.
- Ghi Memory Log vào `.apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_3_CICD_Pipeline.md`.

## Files đã thay đổi

- `.github/workflows/ci.yml` – Tạo mới (workflow CI: build-backend, build-frontend)
- `docs/RUNBOOK.md` – Thêm mục 8.4. CI/CD (GitHub Actions)
- `.apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_3_CICD_Pipeline.md` – Memory Log

## Memory Log

Đã ghi vào `.apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_3_CICD_Pipeline.md` (Summary, Output, Verify, User action required, Next Steps).

## Flags

- important_findings: false
- compatibility_issue: false
- ad_hoc_delegation: false

## Ghi chú cho Manager

- Workflow dùng `src/BCDT.Api/BCDT.Api.csproj` cho build BE (khớp RUNBOOK 6.1). Frontend dùng `npm ci` (cần có package-lock.json, đã có trong repo). Lần đầu chạy CI cần push/PR lên `main` để xác nhận trên GitHub Actions.
