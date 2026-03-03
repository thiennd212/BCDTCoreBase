/**
 * BCDT Load Test – Common utilities
 * k6 v1.6+
 */

export const BASE_URL = __ENV.BASE_URL || 'http://localhost:5080'

export const THRESHOLDS = {
  // P95 < 3000ms (MVP SLA)
  http_req_duration: ['p(95)<3000', 'p(99)<5000'],
  // Error rate < 1%
  http_req_failed: ['rate<0.01'],
}

export const THRESHOLDS_STRESS = {
  // P5 – Stress (500 CCU): P95 < 5s
  http_req_duration: ['p(95)<5000', 'p(99)<8000'],
  http_req_failed: ['rate<0.02'],
}

/**
 * Login và trả về accessToken.
 * Dùng trong setup() hoặc đầu mỗi VU nếu cần token riêng.
 */
export function login(http, username = 'admin', password = 'Admin@123') {
  const res = http.post(
    `${BASE_URL}/api/v1/auth/login`,
    JSON.stringify({ username, password }),
    { headers: { 'Content-Type': 'application/json' } },
  )
  if (res.status !== 200) return null
  const body = JSON.parse(res.body)
  return body?.data?.accessToken ?? null
}

export function authHeaders(token) {
  return {
    headers: {
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
    },
  }
}
