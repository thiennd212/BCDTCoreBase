---
agent: Agent_DevOps
task_ref: Task 2.3 – CI/CD Pipeline (GitHub Actions)
status: Completed
important_findings: false
compatibility_issues: false
---

# Task Log: Task 2.3 – CI/CD Pipeline GitHub Actions

## Summary

Tạo workflow GitHub Actions để tự động build Backend (.NET 8) và Frontend (Node/npm) khi push hoặc pull_request lên branch `main`. Hai job chạy song song, không cần DB hay test runner.

## Output

- `.github/workflows/ci.yml` – workflow với trigger push/PR vào main; job `build-backend` (checkout → setup-dotnet 8 → restore → build Release); job `build-frontend` (checkout → setup-node 20 → npm ci → npm run build trong src/bcdt-web). Hai job độc lập.
- `docs/RUNBOOK.md` – thêm mục **8.4. CI/CD (GitHub Actions)** mô tả trigger, lệnh build BE/FE, đường dẫn file workflow.

## Verify

- YAML hợp lệ (cấu trúc workflow chuẩn GitHub Actions).
- Build local không bị ảnh hưởng (không sửa code BE/FE).

## User action required

- Push/merge lên branch `main` (hoặc mở PR vào main) để kích hoạt workflow lần đầu; kiểm tra tab Actions trên GitHub.

## Next Steps

- Có thể bổ sung bước lint/test (khi đã ổn định) hoặc artifact upload (build output) nếu cần deploy từ CI.
