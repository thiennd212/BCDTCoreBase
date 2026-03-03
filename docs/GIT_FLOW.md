# Git Flow – BCDT

## Cấu trúc branch

```
main
 └── sprint/N                          ← sprint chính (tạo từ main)
       ├── feature/sprint-N/s{N}-name  ← task MEDIUM/LARGE
       └── feature/sprint-N/s{N}-name
hotfix/issue-name                      ← fix khẩn (từ main)
```

## Quy tắc

| Loại | Tạo từ | Merge vào | Ghi chú |
|------|--------|-----------|---------|
| `sprint/N` | `main` | `main` (PR + squash) | Tạo đầu sprint |
| `feature/sprint-N/task` | `sprint/N` | `sprint/N` (PR + no-ff) | Task MEDIUM/LARGE |
| Commit nhỏ | — | thẳng `sprint/N` | Task SMALL, fix nhỏ |
| `hotfix/name` | `main` | `main` + `sprint/N` hiện tại | Fix khẩn production |

## Workflow một sprint

```bash
# 1. Tạo sprint branch từ main
git checkout main && git pull
git checkout -b sprint/4
git push -u origin sprint/4

# 2. Làm task lớn (MEDIUM/LARGE) → feature branch
git checkout sprint/4
git checkout -b feature/sprint-4/s4-1-load-test
git push -u origin feature/sprint-4/s4-1-load-test
# ... implement, commit, push ...

# 3. Merge feature → sprint (sau khi hoàn thành)
git checkout sprint/4
git merge --no-ff feature/sprint-4/s4-1-load-test
git push origin sprint/4

# 4. Khi sprint xong → PR sprint/N → main
# Tạo PR trên GitHub: sprint/4 → main (squash merge)
```

## Commit message

```
feat(scope): mô tả ngắn (≤72 ký tự)

- chi tiết 1
- chi tiết 2

Co-Authored-By: ThienND <thiennd212@gmail.com>
```

**Prefix:**
- `feat` – tính năng mới
- `fix` – sửa lỗi
- `chore` – cấu hình, tooling, không ảnh hưởng logic
- `docs` – tài liệu
- `refactor` – tái cấu trúc không thay đổi behavior
- `test` – thêm/sửa test

## Hiện trạng (2026-02-27)

| Branch | Trạng thái | Ghi chú |
|--------|-----------|---------|
| `main` | ✅ stable | Sprint 1+2 chưa merge (PR `speckit → main` pending) |
| `speckit` | PR pending → main | Sprint 1+2 complete |
| `sprint/3` | 🔄 active | Sprint 3 UX/UI Overhaul |
| `feature/sprint-3/s3-3-dashboard` | pending | S3.3 Dashboard filter + export FE |
| `feature/sprint-3/s3-1-form-split` | pending | S3.1 FormConfigPage split |
| `feature/sprint-3/s3-2-submission-ux` | pending | S3.2 SubmissionDataEntry UX |
