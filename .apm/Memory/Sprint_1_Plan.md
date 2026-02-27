# BCDT – Sprint 1 Plan: Bảo mật & Nền tảng kiểm thử

**Ngày lập:** 2026-02-27 | **PM Agent**
**Sprint Goal:** Khắc phục rủi ro bảo mật JWT + xây dựng CI/CD + unit tests trước khi thêm feature mới.

---

## Tasks

### Task S1.1 – Fix JWT Token Storage (🔴 MUST-ASK)

**Objective:** Chuyển JWT access token từ localStorage sang memory (in-memory JS variable), refresh token sang httpOnly cookie. Loại bỏ XSS attack vector.

**Lý do ưu tiên:** project_state.md + apm-agent-security checklist: "Không store token trong localStorage".

**Tài liệu đọc:**
- `docs/de_xuat_trien_khai/B1_JWT.md` – JWT flow hiện tại
- `docs/de_xuat_trien_khai/RA_SOAT_REFRESH_TOKEN.md` – refresh flow đã verify
- `src/bcdt-web/src/api/axiosInstance.ts` – axios interceptor hiện tại
- `src/bcdt-web/src/context/AuthContext.tsx` – auth state management

**MUST-ASK:** Dừng, xác nhận với User trước khi thay đổi:
- Chiến lược lưu trữ: memory (mất khi refresh tab) vs httpOnly cookie (cần BE set-cookie endpoint)
- BE endpoint `/auth/refresh` có cần thay đổi response format không?
- Impact tới E2E tests (localStorage access)

**Agents:** Agent_Security (thiết kế) → Agent_Backend (BE: set-cookie nếu cần) → Agent_Frontend (FE: auth context, interceptor)

**Verify:**
- Build BE + FE pass
- E2E full run pass (21 tests)
- Manual: login → refresh tab → vẫn auth; logout → token cleared

---

### Task S1.2 – Fix Auth Minor Gaps (B1-B3 Review)

**Objective:** Fix 2 gap Minor từ REVIEW_NGHIEP_VU_MODULE_AUTH_B1_B3.md:
1. Policy permission – xem xét gap cụ thể trong report
2. Refresh token rotation – xem xét rotation đã implement đúng chưa

**Tài liệu đọc:**
- `docs/de_xuat_trien_khai/REVIEW_NGHIEP_VU_MODULE_AUTH_B1_B3.md` – gap list
- `docs/de_xuat_trien_khai/B1_JWT.md`, `B2_RBAC.md`

**Dependency:** S1.1 phải xong trước (cùng auth flow).

**Agent:** Agent_Backend (sau Agent_Security review từ S1.1)

**Verify:** Build pass + Postman auth flow test

---

### Task S1.3 – CI/CD Pipeline

**Objective:** Tạo GitHub Actions workflow: build BE → build FE → chạy E2E (nếu có runner với DB).

**Tài liệu đọc:**
- `docs/RUNBOOK.md` mục 6 (build steps)
- `src/bcdt-web/package.json` (scripts)
- `.github/` (nếu tồn tại)

**Deliverable:**
- `.github/workflows/ci.yml`: trigger on PR/push main
  - Job 1: `dotnet build` (BCDT.Api)
  - Job 2: `npm run build` (bcdt-web)
  - Job 3: (optional nếu có DB service) `npm run test:e2e`

**Agent:** Agent_DevOps

**Verify:** Push nhánh test → CI pipeline chạy green

---

### Task S1.4 – Backend Unit Tests

**Objective:** Tạo `BCDT.Tests` project + unit tests cho 3 service quan trọng nhất.

**Scope (< L effort):**
- `FormDefinitionService`: test Create, GetById, GetAll (paginated)
- `WorkflowService`: test Submit, Approve, Reject (state transitions)
- `SubmissionService`: test Create, GetWorkbookData (mock dependencies)

**Tech:** xUnit + Moq + EF Core InMemory provider (hoặc SQLite)

**Tài liệu:**
- `src/BCDT.Application/Services/` – service interfaces
- `src/BCDT.Infrastructure/Services/` – service implementations

**Agent:** Agent_Backend

**Verify:** `dotnet test` → all tests pass; coverage report (nếu có coverlet)

---

## Execution Order

```
Ngày 1-2:  S1.1 (MUST-ASK confirm) → thiết kế storage strategy
Ngày 3-5:  S1.1 implement (BE + FE) ─────────────────────────┐
           S1.3 CI/CD pipeline ────────────────────────────── │ song song
           S1.4 Unit tests bắt đầu ───────────────────────── ─┘
Ngày 6-7:  S1.1 E2E verify → S1.2 Auth gaps fix
Ngày 8-10: S1.4 Unit tests hoàn thành
Ngày 10:   Quality gate: TechLead → Security → QA → Docs
```

---

## Definition of Done

- [ ] S1.1: JWT không còn trong localStorage; refresh token flow hoạt động; E2E pass
- [ ] S1.2: 2 auth gaps closed; Postman auth tests pass
- [ ] S1.3: CI green trên GitHub Actions cho build BE + FE
- [ ] S1.4: ≥ 15 unit tests pass; `dotnet test` run clean
- [ ] TONG_HOP cập nhật sau sprint (Agent_Docs)

---

## Memory Log Path

`.apm/Memory/Phase_02_Post_MVP_Quality/`
