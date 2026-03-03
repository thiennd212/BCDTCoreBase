/**
 * BCDT Load Test – P0 Smoke (1 VU, 2 phút)
 * Mục tiêu: Xác nhận scripts chạy đúng, API trả 2xx.
 * Chạy: k6 run docs/load-test/p0-smoke.js
 */
import http from 'k6/http'
import { check, sleep } from 'k6'
import { BASE_URL, THRESHOLDS, login, authHeaders } from './common.js'

export const options = {
  vus: 1,
  duration: '2m',
  thresholds: {
    ...THRESHOLDS,
    http_req_failed: ['rate<0.001'], // smoke: 0% error
  },
}

let token = null

export default function () {
  // Login nếu chưa có token
  if (!token) {
    token = login(http)
    check(token, { 'login: got token': (t) => t !== null })
    if (!token) { sleep(1); return }
  }

  const hdrs = authHeaders(token)

  // A – GET submissions list
  let r = http.get(`${BASE_URL}/api/v1/submissions?pageSize=10`, hdrs)
  check(r, { 'submissions list 200': (res) => res.status === 200 })

  // B – GET forms list
  r = http.get(`${BASE_URL}/api/v1/forms?pageSize=10`, hdrs)
  check(r, { 'forms list 200': (res) => res.status === 200 })

  // C – GET dashboard stats
  r = http.get(`${BASE_URL}/api/v1/dashboard/admin/stats`, hdrs)
  check(r, { 'dashboard 200': (res) => res.status === 200 })

  // D – GET notifications
  r = http.get(`${BASE_URL}/api/v1/notifications?pageSize=10`, hdrs)
  check(r, { 'notifications 200 or 401': (res) => [200, 401].includes(res.status) })

  sleep(1)
}
