# Sprint 7 – Load Test CCU Tăng Dần (Pre-Go-Live)

**PM:** APM Agent | **Ngày lập:** 2026-03-02 | **Version:** 1.0
**Nền tảng:** Sprint 1–6 ✅ · Build 0W/0E · Tests 33/33 · Prod checklist 15/15 ✅
**Nguồn bối cảnh:** REVIEW_PRODUCTION_CA_NUOC.md (R8/R10) · W16_PERFORMANCE_SECURITY.md · TONG_HOP 3.8

---

## Sprint Goal

> **"Xác nhận hệ thống BCDT chịu tải tốt ở quy mô cả nước: đo CCU từ 10 → 1000, phát hiện điểm nghẽn, đề xuất và triển khai fix trước go-live."**

---

## 1. Ước lượng tải thực tế (cả nước)

| Yếu tố | Ước tính | Nguồn |
|--------|----------|-------|
| Số đơn vị báo cáo | ~1.000–5.000 tổ chức | REVIEW_PRODUCTION_CA_NUOC mục 1 |
| Tổng user | ~10.000–50.000 | Ước tính 5–10 user/đơn vị |
| CCU bình thường (giờ làm việc) | ~100–300 | ~1% tổng user |
| CCU cao điểm (hạn nộp báo cáo) | ~500–1.500 | ~3–5% tổng user |
| CCU spike (đồng loạt nộp ngày chót) | ~2.000–5.000 | ~10% tổng user |
| **Mục tiêu SLA (P95)** | **< 3s** | W16 MVP baseline |
| **Mục tiêu SLA (P99)** | **< 5s** | Đề xuất thêm cho cả nước |
| **Error rate tối đa** | **< 1%** | Production standard |

**Kết luận:** W16 đo single user (1 CCU). Sprint 7 phải kiểm tra từ 10 → 1.000 CCU với API nặng nhất (workbook-data, submit, bulk-approve).

---

## 2. Công cụ đề xuất

**Tool chính: [k6](https://k6.io/)** (khuyến nghị)

| Tiêu chí | k6 | Lý do chọn |
|----------|----|-----------|
| Ngôn ngữ script | JavaScript/TypeScript | Dev team quen thuộc |
| Metrics built-in | VU, RPS, p50/p95/p99, error rate | Đủ cho báo cáo |
| CI/CD | GitHub Actions plugin sẵn có | Tích hợp pipeline Sprint 4 |
| License | Open-source (Grafana) | Không tốn phí |
| Cài đặt | `winget install k6` / Docker | Đơn giản |

**Alternative:** Artillery (YAML config, Node.js) nếu team thích cấu hình YAML hơn code.

---

## 3. Kịch bản test (User Journeys)

### Scenario A – Submitter (người nộp báo cáo) · 60% traffic
```
Login → GET /submissions (list) → GET /submissions/{id}/workbook-data → POST /submissions/{id}/submit
```

### Scenario B – Approver (người duyệt) · 25% traffic
```
Login → GET /submissions?status=Submitted → POST /workflow-instances/{id}/approve
```

### Scenario C – Bulk Approver (quản lý duyệt hàng loạt) · 10% traffic
```
Login → GET /submissions?status=Submitted → POST /workflow-instances/bulk-approve
```

### Scenario D – Manager/Viewer (xem báo cáo) · 5% traffic
```
Login → GET /dashboard/admin/stats → GET /reporting-periods (list)
```

---

## 4. Kế hoạch CCU tăng dần (7 phases)

| Phase | CCU | Thời gian | Ramp-up | Mục tiêu | Pass/Fail |
|-------|-----|-----------|---------|-----------|-----------|
| **P0 – Smoke** | 1 | 2 phút | Ngay | Scripts chạy đúng, API trả 2xx | 0% error, p95 < 3s |
| **P1 – Light** | 10 | 5 phút | 30s | Baseline nhiều CCU, so sánh W16 | p95 < 3s, error < 0.1% |
| **P2 – Normal Day** | 50 | 10 phút | 2 phút | Mô phỏng ngày làm việc bình thường | p95 < 3s, error < 0.5% |
| **P3 – Busy Day** | 100 | 15 phút | 3 phút | Giờ cao điểm ngày thường | p95 < 3s, error < 0.5% |
| **P4 – Peak Load** | 200 | 20 phút | 5 phút | Cao điểm cuối tháng/quý | p95 < 3s, error < 1% |
| **P5 – Stress** | 500 | 20 phút | 5 phút | Hạn nộp báo cáo toàn quốc | p95 < 5s, error < 2% |
| **P6 – Spike** | 1.000 | 10 phút | 2 phút | Spike đồng loạt (ngày chót kỳ báo cáo) | Tìm breaking point |
| **P7 – Soak** | 100 | 60 phút | 5 phút | Ổn định dài hạn, memory leak | p95 ổn định, no leak |

**Thứ tự thực hiện:** P0 → P1 → P2 → P3 → dừng nếu fail → fix → P4 → P5 → P6 → P7

---

## 5. API trọng điểm cần đo riêng

| # | API | Lý do quan trọng | Nguy cơ |
|---|-----|-----------------|---------|
| 1 | `POST /auth/login` | Spike đăng nhập sáng sớm (~8:00–8:30) | BCrypt CPU-bound |
| 2 | `GET /submissions/{id}/workbook-data` | API nặng nhất (N+1 query còn tồn tại – W16 mục 2.1) | DB timeout |
| 3 | `POST /submissions/{id}/submit` | Trigger Hangfire + notify + status change | DB lock |
| 4 | `POST /workflow-instances/bulk-approve` | N × ApproveAsync tuần tự (Sprint 6 mới) | Tải DB tích lũy |
| 5 | `GET /dashboard/admin/stats` | Manager polling thường xuyên | Query tổng hợp |
| 6 | `GET /api/v1/forms` | Baseline 1418ms ngay cả single user (W16) | Cold start / cache |

---

## 6. Điểm nghẽn dự kiến & fix plan

| Điểm nghẽn | Khả năng xảy ra | Fix đề xuất | Sprint |
|------------|----------------|------------|--------|
| **BCrypt login chậm** dưới nhiều CCU | 🔴 Cao (CPU-bound) | Tăng BCrypt worker threads; rate limit /login nghiêm hơn | S7.3 |
| **workbook-data N+1 query** (FilterDefinition/FilterCondition) | 🔴 Cao | Batch cache FilterDefinition+Condition trong DataSourceQueryService (W16 mục 2.2) | S7.3 |
| **bulk-approve tuần tự** (N × ApproveAsync) | 🟡 Trung bình | Parallel.ForEachAsync với concurrency limit | S7.3 |
| **GET /forms 1418ms** single user | 🟡 Trung bình | Warm-up cache; DistributedCache cho FormDefinition list | S7.3 |
| **Rate limiter 429** khi test | 🟡 Trung bình | Điều chỉnh PermitLimit/WindowSeconds cho production scale; bypass cho load test env | S7.2 |
| **SQL connection pool** cạn kiệt | 🔴 Cao khi >200 CCU | Tăng Max Pool Size; kiểm tra connection leak | S7.3 |
| **Hangfire job queue** tắc nghẽn | 🟡 Trung bình khi spam submit | Tăng Worker count; hoặc batch job | S7.3 |

---

## 7. Tasks Sprint 7

| # | Task | Mô tả | Effort | Depends |
|---|------|-------|--------|---------|
| **S7.1** | Full E2E verify | Chạy `npm run test:e2e` (BE 5080), xác nhận 17+ tests pass sau Sprint 6 changes | **S** | — |
| **S7.2** | k6 setup + scripts | Cài k6; viết scripts 4 scenarios (A/B/C/D); chạy P0 + P1; document kết quả | **M** | S7.1 |
| **S7.3** | CCU ramp P2→P6 + fix | Chạy P2→P6 theo kế hoạch; ghi nhận bottleneck; implement fixes (batch cache, parallel bulk-approve, connection pool); re-test | **L** | S7.2 |
| **S7.4** | Soak test P7 | Chạy 100 CCU × 60 phút; kiểm tra memory leak, connection leak, Hangfire queue | **M** | S7.3 |
| **S7.5** | Fortune Sheet perf | Đo rendering với form >100 dòng/cột; lazy load rows; profiling FE bundle | **M** | — |

**Sprint 7 total effort:** S + M + L + M + M ≈ 2–3 tuần

---

## 8. Định nghĩa "Done" Sprint 7

- [ ] P0–P4 (1–200 CCU): p95 < 3s, error < 1% trên **tất cả** scenarios
- [ ] P5 (500 CCU): p95 < 5s, error < 2%
- [ ] P6 (1000 CCU): breaking point được xác định + documented
- [ ] P7 (soak 60 min): không memory leak, p95 ổn định (±20%)
- [ ] Bảng kết quả đầy đủ lưu trong `docs/de_xuat_trien_khai/W17_LOAD_TEST_CCU.md`
- [ ] Các fix từ bottleneck (S7.3) đã pass build + 33 tests
- [ ] TONG_HOP cập nhật Sprint 7 ✅

---

## 9. Lưu ý triển khai test

```
⚠️  MUST-ASK trước khi chạy P5+ (500 CCU):
- Hangfire RLS: job notification sẽ trigger với mỗi submit/approve → tải DB tăng
- Rate limiter: cần tăng PermitLimit trong môi trường load test hoặc bypass bằng header
- Connection pool: kiểm tra appsettings MaxPoolSize trước
- Chạy trên môi trường staging, KHÔNG chạy trên production
```

```
Tool cài đặt (Windows):
winget install k6
k6 run scripts/load-test/smoke.js
k6 run --vus 50 --duration 10m scripts/load-test/normal-day.js
```

---

## 10. Tham chiếu

| Doc | Mục liên quan |
|-----|---------------|
| `docs/REVIEW_PRODUCTION_CA_NUOC.md` | Bối cảnh cả nước, R8/R10 |
| `docs/de_xuat_trien_khai/W16_PERFORMANCE_SECURITY.md` | Baseline single user, bottleneck mục 2.1–2.2 |
| `docs/DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md` | Perf-1..19 (đã xong) |
| `docs/RUNBOOK.md` | Mục 10.3 checklist production |
| `.apm/Memory/Sprint_Roadmap.md` | Sprint 4 load test (chưa làm) |
