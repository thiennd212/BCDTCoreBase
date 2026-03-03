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

### 1. Đánh giá rủi ro (Risk Assessment)

| Loại rủi ro | Mức độ | Mô tả |
|-------------|--------|-------|
| Production data | High | Nếu chạy nhầm lên production: 500 VU tạo load thật → ảnh hưởng user thật |
| SQL Server stability | High | 500 × concurrent queries → connection exhaustion nếu MaxPoolSize < 1000 → cascading failures |
| Rate Limiter | Medium | Nếu PermitLimit < 50000 → 429 storm → test vô nghĩa |
| Dev machine crash | Medium | Laptop dev không đủ tài nguyên cho 500 CCU → kết quả sai lệch, BE có thể crash |
| BCrypt CPU storm | Medium | 500 VU login đồng thời → CPU saturation → p99 > 60s khi ramp |

- **Production impact:** Nếu chạy nhầm môi trường → DDoS chính hệ thống. Risk cao nhất.
- **Rollback effort:** Chỉ cần stop k6; không thay đổi code → rollback ngay lập tức.

### 2. Phương án (Options)

**Phương án A – Chạy trên dev machine (localhost) sau khi fix BCrypt/pool:**
- Mô tả: Cấu hình appsettings.Development.json với PermitLimit=50000, MaxPoolSize=1000; chạy `k6 run --vus 500 --duration 20m`
- Ưu điểm: Không cần staging server; có thể chạy ngay
- Nhược điểm: Dev laptop CPU/RAM không đủ cho 500 CCU → kết quả không đại diện production; p99 spike do hardware limit, không phải code

**Phương án B – Chờ staging server (khuyến nghị):**
- Mô tả: Chuẩn bị dedicated server (≥8 core, ≥16GB RAM, SQL Server separate) → deploy BCDT → chạy P5 từ máy ngoài
- Ưu điểm: Kết quả có giá trị thực; tách biệt dev machine limit; gần production hơn
- Nhược điểm: Cần effort setup staging (~2-4h); cần server phần cứng

**Phương án C – Chạy P5 ramp nhỏ (200→300→500 VU, 5 phút/bước):**
- Mô tả: Thay vì 500 VU ngay, ramp dần: 200 VU 5m → 300 VU 5m → 500 VU 10m để phát hiện breaking point
- Ưu điểm: Ít rủi ro crash máy; dữ liệu breaking point rõ hơn; có thể dừng sớm nếu hệ thống fail ở 300
- Nhược điểm: Vẫn trên dev machine nếu không có staging

### 3. Đề xuất (Recommendation)

→ **Chọn Phương án C** (ramp nhỏ trên dev machine) nếu muốn chạy ngay để có dữ liệu sơ bộ.
→ **Chọn Phương án B** nếu muốn kết quả có giá trị cho production planning (khuyến nghị trước go-live).

Lý do: Dev machine đã cho thấy giới hạn ở P7 Soak (20s avg cho 100 CCU); 500 CCU trên dev sẽ cho kết quả sai lệch hoàn toàn. Nếu mục tiêu là kiểm chứng production capacity, cần staging.

### 4. Pre-conditions (phải đáp ứng trước khi proceed)

- [ ] Xác nhận môi trường: DEV localhost (chấp nhận kết quả không chính xác) hay STAGING (kết quả production-like)?
- [ ] `PermitLimit ≥ 50000` trong `appsettings.Development.json` (hoặc staging env)
- [ ] `Max Pool Size ≥ 1000` trong connection string
- [ ] S8.1 (SessionContext fix) ✅ đã xong
- [ ] Monitor SQL Server CPU/memory trong khi chạy (SQL Server Profiler hoặc Activity Monitor)
- [ ] **KHÔNG chạy trên production** – xác nhận endpoint là localhost hoặc staging URL

**Lệnh (Phương án C – ramp):**
```bash
# Bước 1: 200 VU 5m (đã biết pass từ P4)
/c/Program Files/k6/k6.exe run --vus 200 --duration 5m docs/load-test/scenarios.js
# Bước 2: 300 VU 5m (territory mới)
/c/Program Files/k6/k6.exe run --vus 300 --duration 5m docs/load-test/scenarios.js
# Bước 3: 500 VU 10m (P5 target)
/c/Program Files/k6/k6.exe run --vus 500 --duration 10m docs/load-test/scenarios.js
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
