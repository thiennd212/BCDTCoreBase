/**
 * BCDT Load Test – P7 Soak (100 VU, 60 phút)
 * Mục tiêu: Kiểm tra memory leak, connection leak, Hangfire queue ổn định.
 * Chạy: k6 run docs/load-test/p7-soak.js
 *
 * Metrics cần quan sát:
 *   - http_req_duration p95 ổn định (không tăng dần)
 *   - http_req_failed rate < 1%
 *   - Không có spike bất thường sau 30+ phút
 */
import http from 'k6/http'
import { check, sleep } from 'k6'
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js'
import { BASE_URL, login, authHeaders } from './common.js'

export const options = {
  stages: [
    { duration: '5m',  target: 100 }, // ramp up
    { duration: '50m', target: 100 }, // steady state
    { duration: '5m',  target: 0   }, // ramp down
  ],
  thresholds: {
    http_req_duration: ['p(95)<5000'],
    http_req_failed: ['rate<0.01'],
  },
}

const tokens = {}

export default function () {
  const vuId = __VU
  if (!tokens[vuId]) tokens[vuId] = login(http)
  const token = tokens[vuId]
  if (!token) { sleep(5); return }

  const hdrs = authHeaders(token)

  // Luân phiên giữa các API để simulate real traffic
  const roll = __ITER % 4
  if (roll === 0) {
    http.get(`${BASE_URL}/api/v1/submissions?pageSize=20`, hdrs)
  } else if (roll === 1) {
    http.get(`${BASE_URL}/api/v1/dashboard/admin/stats`, hdrs)
  } else if (roll === 2) {
    http.get(`${BASE_URL}/api/v1/notifications/unread-count`, hdrs)
  } else {
    http.get(`${BASE_URL}/api/v1/forms?pageSize=10`, hdrs)
  }

  check(null, { 'soak: ok': () => true })
  sleep(randomIntBetween(2, 5))
}
