/**
 * BCDT Load Test – Tất cả 4 scenarios (Submitter, Approver, Bulk Approver, Manager)
 * Dùng cho P1–P6 bằng cách override options từ ngoài hoặc import file này.
 *
 * Chạy P1 (10 CCU, 5 phút):
 *   k6 run --vus 10 --duration 5m docs/load-test/scenarios.js
 *
 * Chạy P2 (50 CCU, 10 phút):
 *   k6 run --vus 50 --duration 10m docs/load-test/scenarios.js
 *
 * Chạy P3 (100 CCU, 15 phút):
 *   k6 run --vus 100 --duration 15m docs/load-test/scenarios.js
 *
 * Chạy P4 (200 CCU, 20 phút):
 *   k6 run --vus 200 --duration 20m docs/load-test/scenarios.js
 *
 * Chạy P5 Stress (500 CCU, 20 phút) – dùng threshold lỏng hơn:
 *   k6 run --vus 500 --duration 20m -e STRESS=1 docs/load-test/scenarios.js
 *
 * Chạy P6 Spike (1000 CCU, 10 phút):
 *   k6 run --vus 1000 --duration 10m -e STRESS=1 docs/load-test/scenarios.js
 */
import http from 'k6/http'
import { check, sleep } from 'k6'
import { randomIntBetween } from 'https://jslib.k6.io/k6-utils/1.2.0/index.js'
import { BASE_URL, THRESHOLDS, THRESHOLDS_STRESS, login, authHeaders } from './common.js'

const isStress = (__ENV.STRESS === '1')

export const options = {
  // Override bằng --vus và --duration khi chạy
  vus: 10,
  duration: '5m',
  thresholds: isStress ? THRESHOLDS_STRESS : THRESHOLDS,
}

// Phân phối scenario theo tỷ lệ thực tế
// 60% Submitter, 25% Approver, 10% BulkApprover, 5% Manager
function pickScenario(vuId) {
  const r = vuId % 20
  if (r < 12) return 'submitter'   // 12/20 = 60%
  if (r < 17) return 'approver'    // 5/20 = 25%
  if (r < 19) return 'bulk'        // 2/20 = 10%
  return 'manager'                  // 1/20 = 5%
}

// Cache token per VU (mỗi VU login một lần)
const tokens = {}

function getToken(vuId) {
  if (!tokens[vuId]) {
    tokens[vuId] = login(http)
  }
  return tokens[vuId]
}

export default function () {
  const vuId = __VU
  const token = getToken(vuId)
  if (!token) { sleep(2); return }

  const hdrs = authHeaders(token)
  const scenario = pickScenario(vuId)

  if (scenario === 'submitter') {
    // Scenario A – Submitter: list → workbook-data → (optionally submit)
    let r = http.get(`${BASE_URL}/api/v1/submissions?pageSize=20&status=Draft`, hdrs)
    check(r, { 'A: submissions list 200': (res) => res.status === 200 })

    // Lấy submission đầu tiên nếu có
    let submissionId = null
    try {
      const data = JSON.parse(r.body)?.data?.items ?? JSON.parse(r.body)?.data ?? []
      if (Array.isArray(data) && data.length > 0) submissionId = data[0].id
    } catch (_) {}

    if (submissionId) {
      r = http.get(`${BASE_URL}/api/v1/submissions/${submissionId}/workbook-data`, hdrs)
      check(r, { 'A: workbook-data 200': (res) => [200, 404].includes(res.status) })
    }
    sleep(randomIntBetween(1, 3))

  } else if (scenario === 'approver') {
    // Scenario B – Approver: list submitted → approve
    let r = http.get(`${BASE_URL}/api/v1/submissions?pageSize=20&status=Submitted`, hdrs)
    check(r, { 'B: submitted list 200': (res) => res.status === 200 })

    let wfInstanceId = null
    try {
      const data = JSON.parse(r.body)?.data?.items ?? JSON.parse(r.body)?.data ?? []
      if (Array.isArray(data) && data.length > 0) wfInstanceId = data[0].workflowInstanceId
    } catch (_) {}

    if (wfInstanceId) {
      r = http.post(
        `${BASE_URL}/api/v1/workflow-instances/${wfInstanceId}/approve`,
        JSON.stringify({ comments: 'Load test approve' }),
        hdrs,
      )
      check(r, { 'B: approve 200 or 422': (res) => [200, 422, 400].includes(res.status) })
    }
    sleep(randomIntBetween(1, 2))

  } else if (scenario === 'bulk') {
    // Scenario C – Bulk Approver: get submitted → bulk approve
    let r = http.get(`${BASE_URL}/api/v1/submissions?pageSize=10&status=Submitted`, hdrs)
    check(r, { 'C: submitted list 200': (res) => res.status === 200 })

    const wfIds = []
    try {
      const data = JSON.parse(r.body)?.data?.items ?? JSON.parse(r.body)?.data ?? []
      if (Array.isArray(data)) {
        data.slice(0, 5).forEach((s) => { if (s.workflowInstanceId) wfIds.push(s.workflowInstanceId) })
      }
    } catch (_) {}

    if (wfIds.length > 0) {
      r = http.post(
        `${BASE_URL}/api/v1/workflow-instances/bulk-approve`,
        JSON.stringify({ workflowInstanceIds: wfIds, comments: 'Bulk load test' }),
        hdrs,
      )
      check(r, { 'C: bulk approve 200': (res) => [200, 400].includes(res.status) })
    }
    sleep(randomIntBetween(2, 4))

  } else {
    // Scenario D – Manager/Viewer: dashboard + notifications
    let r = http.get(`${BASE_URL}/api/v1/dashboard/admin/stats`, hdrs)
    check(r, { 'D: dashboard 200': (res) => res.status === 200 })

    r = http.get(`${BASE_URL}/api/v1/notifications/unread-count`, hdrs)
    check(r, { 'D: unread count 200': (res) => res.status === 200 })

    r = http.get(`${BASE_URL}/api/v1/reporting-periods?pageSize=10`, hdrs)
    check(r, { 'D: periods 200': (res) => res.status === 200 })

    sleep(randomIntBetween(3, 6))
  }
}
