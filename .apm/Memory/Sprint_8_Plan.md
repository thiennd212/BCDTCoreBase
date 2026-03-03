# Sprint 8 – Stabilize Production: SessionContext Fix + P7 Soak + PR Merge

**PM:** APM Agent | **Ngày lập:** 2026-03-03 | **Version:** 1.0
**Nền tảng:** Sprint 1–7 ✅ · Build 0W/0E · Tests 33/33 · TONG_HOP v2.81
**Sprint Goal:** "Ổn định production: fix bottleneck SQL session context, xác nhận P7 Soak pass trong fresh env, merge toàn bộ PRs vào main."

---

## Tasks Sprint 8

| # | Task ID | Mô tả | Effort | Depends | MUST-ASK |
|---|---------|-------|--------|---------|----------|
| 1 | **S8.1** | Fix `sp_ClearUserContext` exception handling | S | — | ✅ SessionContext/RLS |
| 2 | **S8.2** | Re-run P7 Soak trong fresh environment | S | S8.1 | — |
| 3 | **S8.3** | Merge PRs sprint/3→6 → main | S | — | — |
| 4 | **S8.4** | P5 Stress 500 VU (MUST-ASK staging) | M | S8.1, S8.2 | ✅ Staging env |
| 5 | **S8.5** | FormRow Phase 3 – hàng từ danh mục (tùy chọn) | M | — | — |

---

## S8.1 – Fix `sp_ClearUserContext` exception handling

**Vấn đề:**
Trong `SessionContextMiddleware.cs`, block `finally` gọi `sp_ClearUserContext` nhưng exception bị catch silently:
```csharp
finally {
    try { await _context.Database.ExecuteSqlRawAsync("EXEC sp_ClearUserContext"); }
    catch { /* Best effort clear */ }
}
```
Khi `sp_ClearUserContext` fail (do SQL overload, timeout, connection issue) → connection được trả về pool với **stale session context** → RLS filter sai hoặc chậm cho request kế tiếp.

**Fix approach (PHẢI MUST-ASK trước khi implement):**
1. Log exception khi sp_ClearUserContext fail (thay vì silently swallow)
2. Cân nhắc invalidate connection thay vì trả về pool nếu clear fail
3. Hoặc: set CONTEXT_INFO(0x00) trực tiếp qua SqlCommand (lightweight, không cần stored procedure)
4. Thêm retry logic (1 retry với short timeout)

**Impact analysis (cần xem xét trước khi sửa):**
- `SessionContextMiddleware.cs` – file MUST-ASK (RLS/session context)
- Mọi authenticated request đều đi qua middleware này
- Thay đổi behavior khi clear fail có thể ảnh hưởng connection pool strategy
- Nếu throw exception từ `finally` → connection bị abort → pool shrinks → có thể gây cascade

**Verify:**
- Build 0W/0E
- `dotnet test` 33/33 pass
- Run P3 (100 VU, 5m) để xác nhận SESSION_CONTEXT không storm
- Re-run P7 Soak (S8.2) để confirm fix

---

## S8.2 – Re-run P7 Soak (fresh environment)

**Điều kiện:**
- BE phải restart fresh (không accumulated load từ P0→P4)
- S8.1 phải xong trước
- Chạy P7 standalone: `k6 run docs/load-test/p7-soak.js`
- SLA: p95 < 5s, error < 1%

**Lệnh:**
```bash
# Restart BE trước
/c/Program Files/k6/k6.exe run docs/load-test/p7-soak.js
```

**Document kết quả:** Cập nhật `docs/load-test/W17_LOAD_TEST_CCU.md` mục P7 (replace kết quả cũ)

---

## S8.3 – Merge PRs sprint/3→6 → main

**PRs cần merge (theo thứ tự):**
1. `sprint/3` → `main` (FormConfigPage split, SubmissionDataEntry UX, Dashboard filter)
2. `sprint/4` → `main` (UserDelegations FE, FluentValidation, Zero-warning build)
3. `sprint/5` → `main` (Notification module, Bell badge, E2E UserDelegations)
4. `sprint/6` → `main` (Bulk Approve FE, WorkflowExecution tests, E2E Notifications + Sprint 7 docs)

**Cách thực hiện:** GitHub UI hoặc gh CLI (`/c/Program Files/GitHub CLI/gh pr merge`)
**Ghi chú:** Merge theo thứ tự từ cũ đến mới để tránh conflict.

---

## S8.4 – P5 Stress 500 VU ⚠️ MUST-ASK

**Điều kiện MUST-ASK:**
- [ ] Staging environment riêng (KHÔNG chạy trên production)
- [ ] `PermitLimit ≥ 50000` trong appsettings
- [ ] `Max Pool Size ≥ 1000` trong connection string
- [ ] Monitor SQL Server CPU/memory khi chạy
- [ ] RAM staging ≥ 8GB free
- [ ] S8.1 và S8.2 phải xong trước

**Lệnh (khi điều kiện đủ):**
```bash
/c/Program Files/k6/k6.exe run --vus 500 --duration 20m docs/load-test/scenarios.js
```

---

## S8.5 – FormRow Phase 3 – hàng từ danh mục (tùy chọn)

**Context:** Phase 1 (BE copy metadata từ Indicator) + Phase 2a/2b (FormColumn.IndicatorId bắt buộc) đã xong (2026-02-24). Phase 3: áp dụng tương tự cho **FormRow** – cho phép hàng biểu mẫu liên kết với Indicator catalog.

**Tài liệu tham chiếu:** `docs/de_xuat_trien_khai/KE_HOACH_COT_HANG_TU_DANH_MUC_CHI_TIEU.md`

**Chỉ làm khi User xác nhận business cần Phase 3 (hàng).**

---

## Định nghĩa "Done" Sprint 8

- [ ] S8.1: `sp_ClearUserContext` exception được log; connection pool không bị stale dưới load. Build pass, 33 tests pass.
- [ ] S8.2: P7 Soak fresh env → p95 < 5s, error < 1% → ghi vào W17_LOAD_TEST_CCU.md
- [ ] S8.3: 4 PRs merged vào main; `main` branch có đầy đủ Sprint 1–7 code
- [ ] S8.4: P5 (500 VU) chạy xong → bottleneck documented (MUST-ASK confirmed)
- [ ] TONG_HOP cập nhật Sprint 8 ✅

---

## Tham chiếu

| Doc | Mục |
|-----|-----|
| `docs/load-test/W17_LOAD_TEST_CCU.md` | CCU results, bottleneck table |
| `src/BCDT.Api/Middleware/SessionContextMiddleware.cs` | File cần sửa S8.1 (MUST-ASK) |
| `memory/DECISIONS.md` | Ghi khi sửa SessionContext |
| `.apm/Memory/Sprint_7_Plan.md` | Sprint 7 context |
