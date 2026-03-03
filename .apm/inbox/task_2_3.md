---
task_ref: "Task 2.3 – CI/CD Pipeline (GitHub Actions)"
agent_assignment: "Agent_DevOps"
phase: "Phase_02_Sprint_1_Security_Quality"
memory_log_path: ".apm/Memory/Phase_02_Sprint_1_Security_Quality/Task_2_3_CICD_Pipeline.md"
execution_type: single-step
---

# Task Assignment: Task 2.3 – CI/CD Pipeline GitHub Actions

## Mục tiêu

Tạo GitHub Actions workflow tự động build BE + FE khi có push/PR lên `main`. Loại bỏ rủi ro "không có automated build gate".

## Bối cảnh

- **BE:** .NET 8, solution file tại root, build target: `src/BCDT.Api`
- **FE:** Node/npm, source tại `src/bcdt-web`, build command: `npm run build`
- **Không cần:** DB service, test runner (chưa có tests ổn định), Docker
- **Build commands từ RUNBOOK:**
  - BE: `dotnet restore && dotnet build src/BCDT.Api --no-restore --configuration Release`
  - FE: `cd src/bcdt-web && npm ci && npm run build`

## Các việc cần làm

- Tạo `.github/workflows/ci.yml` với:
  - Trigger: `push` và `pull_request` vào branch `main`
  - Job `build-backend`:
    - runs-on: `ubuntu-latest`
    - steps: checkout → setup .NET 8 → dotnet restore → dotnet build (Release, no-restore, treat warnings as errors nếu được)
  - Job `build-frontend`:
    - runs-on: `ubuntu-latest`
    - steps: checkout → setup Node 20 → npm ci → npm run build
  - Hai job chạy song song (không phụ thuộc nhau)

- Thêm mục **CI/CD** vào `docs/RUNBOOK.md` (tìm vị trí phù hợp, append hoặc insert):
  ```
  ## CI/CD
  GitHub Actions tự động chạy khi push/PR lên main.
  - Build BE: dotnet build src/BCDT.Api --configuration Release
  - Build FE: npm ci && npm run build (trong src/bcdt-web)
  - File workflow: .github/workflows/ci.yml
  ```

- Ghi Memory Log vào `memory_log_path`

## Output mong đợi

1. `.github/workflows/ci.yml` tồn tại và đúng cú pháp YAML
2. `docs/RUNBOOK.md` có mục CI/CD
3. Memory Log ghi đầy đủ
