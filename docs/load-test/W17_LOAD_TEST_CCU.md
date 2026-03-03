# BCDT Load Test – Kết quả CCU (Sprint 7)

**Môi trường:** localhost (dev) | **BE:** http://localhost:5080 | **Tool:** k6 v1.6.1
**Ngày chạy:** 2026-03-03

---

## Thiết lập

- **k6 path:** `C:\Program Files\k6\k6.exe`
- **Rate Limiter:** Tăng `PermitLimit` từ 200 → 10000 trong `appsettings.Development.json`
  - Root cause: 10 VU đều login bằng `admin` → chia sẻ 1 rate bucket → 429 khi vượt 200 req/60s
  - Fix: Thêm section `RateLimiting` vào `appsettings.Development.json` (xem README)

---

## P0 – Smoke (1 VU, 2 phút) ✅ PASS

```
CCU: 1 VU | Duration: 2m | Date: 2026-03-03
```

| Metric | Kết quả | SLA | Status |
|--------|---------|-----|--------|
| http_req_failed | 0.00% | <0.1% | ✅ |
| p(95) latency | 2.29s | <3s | ✅ |
| p(99) latency | 2.89s | <5s | ✅ |
| checks pass | 100% (105/105) | 100% | ✅ |

**Checks:**
- ✅ login: got token
- ✅ submissions list 200
- ✅ forms list 200
- ✅ dashboard 200
- ✅ notifications 200 or 401

**Throughput:** 105 requests / 2m = 0.87 req/s | 26 iterations
**avg latency:** 897ms | **med:** 313ms | **max:** 3.31s

**Ghi chú:** p95=2.29s cao hơn dự kiến cho 1 VU → nghi ngờ EF lazy loading lần đầu
hoặc BCrypt login (CPU-bound). Cần warm-up trước khi đo.

---

## P1 – Light (10 VU, 5 phút) ✅ PASS

```
CCU: 10 VU | Duration: 5m | Date: 2026-03-03
Command: k6 run --vus 10 --duration 5m docs/load-test/scenarios.js
```

**Lần 1 (trước fix Rate Limiter):** ❌ FAIL – 49.77% error (429 Too Many Requests)
**Lần 2 (sau fix Rate Limiter, hot-reload):** ❌ FAIL – 46.44% error (rate limiter chưa reload)
**Lần 3 (sau restart BE):** ✅ PASS

| Metric | Kết quả | SLA | Status |
|--------|---------|-----|--------|
| http_req_failed | 0.00% | <1% | ✅ |
| p(95) latency | 45.54ms | <3s | ✅ |
| p(99) latency | 4.40s | <5s | ✅ (borderline) |
| checks pass | 100% (2684/2684) | 100% | ✅ |

**Checks:**
- ✅ A: submissions list 200 (all 10 VU là submitter do vuId 1-10 < 12)
- ✅ A: workbook-data 200

**Throughput:** 2694 requests / 5m = 8.9 req/s | 1342 iterations
**avg latency:** 127ms | **med:** 12.51ms | **max:** 11.57s

**Ghi chú:**
- p99=4.4s gần sát ngưỡng 5s → cần theo dõi khi tăng CCU
- max=11.57s → spike lớn, có thể từ BCrypt login (CPU-bound) hoặc N+1 query
- Tất cả 10 VU đều là `submitter` (vuId 1-10, r<12) → không test approver/bulk/manager
- Scenario distribution sẽ đa dạng hơn từ P2+ (50+ VU)

---

## P2 – Normal (50 VU, 10 phút)

> Kết quả: (chờ cập nhật)

---

## P3 – Busy (100 VU, 15 phút)

> Kết quả: (chờ cập nhật)

---

## P4 – Peak (200 VU, 20 phút)

> Kết quả: (chờ cập nhật)

---

## P5 – Stress (500 VU, 20 phút) ⚠️ MUST-ASK

> Kết quả: (chờ cập nhật) | Cần điều chỉnh RateLimiter và monitor SQL pool

---

## P6 – Spike (1000 VU, 10 phút) ⚠️ MUST-ASK

> Kết quả: (chờ cập nhật) | Breaking point test

---

## P7 – Soak (100 VU, 60 phút)

> Kết quả: (chờ cập nhật) | Memory/connection leak check

---

## Bottleneck phát hiện

| # | Bottleneck | Phase phát hiện | Mức độ | Fix |
|---|-----------|----------------|--------|-----|
| 1 | Rate Limiter 200/60s per user | P1 | HIGH | Tăng PermitLimit trong appsettings.Development.json |
| 2 | p99=4.4s tại P1 (10 VU) | P1 | MEDIUM | Theo dõi khi tăng CCU |
| 3 | max=11.57s spike | P1 | MEDIUM | BCrypt CPU-bound hoặc N+1 query cần profile |
