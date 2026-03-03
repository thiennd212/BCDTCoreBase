# BCDT Load Test – Hướng dẫn chạy CCU

**Tool:** k6 v1.6+ | **Môi trường:** Staging (KHÔNG chạy production)

## Cài đặt

```bash
winget install k6
# Hoặc: choco install k6
```

## Kế hoạch CCU tăng dần (Sprint 7)

| Phase | Script | Lệnh | CCU | Thời gian | SLA |
|-------|--------|------|-----|-----------|-----|
| P0 Smoke | p0-smoke.js | `k6 run docs/load-test/p0-smoke.js` | 1 | 2 phút | 0% error |
| P1 Light | scenarios.js | `k6 run --vus 10 --duration 5m docs/load-test/scenarios.js` | 10 | 5 phút | p95<3s, err<0.1% |
| P2 Normal | scenarios.js | `k6 run --vus 50 --duration 10m docs/load-test/scenarios.js` | 50 | 10 phút | p95<3s, err<0.5% |
| P3 Busy | scenarios.js | `k6 run --vus 100 --duration 15m docs/load-test/scenarios.js` | 100 | 15 phút | p95<3s, err<0.5% |
| P4 Peak | scenarios.js | `k6 run --vus 200 --duration 20m docs/load-test/scenarios.js` | 200 | 20 phút | p95<3s, err<1% |
| P5 Stress | scenarios.js | `k6 run --vus 500 --duration 20m -e STRESS=1 docs/load-test/scenarios.js` | 500 | 20 phút | p95<5s, err<2% |
| P6 Spike | scenarios.js | `k6 run --vus 1000 --duration 10m -e STRESS=1 docs/load-test/scenarios.js` | 1000 | 10 phút | tìm breaking point |
| P7 Soak | p7-soak.js | `k6 run docs/load-test/p7-soak.js` | 100 | 60 phút | p95 ổn định, no leak |

## Chuẩn bị trước khi chạy (BẮT BUỘC)

**Rate Limiter**: Mặc định `PermitLimit=200/60s` per user. Vì các VU đều login với cùng user `admin`,
chúng chia sẻ 1 rate bucket → 429 ngay từ P1. Phải điều chỉnh trước khi chạy bất kỳ phase nào:

```json
// src/BCDT.Api/appsettings.Development.json – thêm section này
"RateLimiting": {
  "PermitLimit": 10000,
  "WindowSeconds": 60
}
```

Sau khi sửa file, restart BE để config có hiệu lực.

## Quy tắc

1. **Chạy tuần tự**: P0 → P1 → ... Phase sau phải pass trước khi tăng
2. **Rate limiter**: Điều chỉnh `PermitLimit` TRƯỚC KHI chạy P1+ (xem mục trên)
3. **Quan sát**: CPU, RAM, SQL connection pool, Hangfire queue trong quá trình test
4. **Ghi nhận**: Copy kết quả k6 vào `docs/load-test/W17_LOAD_TEST_CCU.md`

## Bottleneck đã biết trước (cần monitor)

- `GET /submissions/{id}/workbook-data` – N+1 query FilterDefinition
- `POST /auth/login` – BCrypt CPU-bound khi nhiều CCU
- `POST /workflow-instances/bulk-approve` – N × sequential ApproveAsync
- SQL connection pool – kiểm tra MaxPoolSize trong connection string
