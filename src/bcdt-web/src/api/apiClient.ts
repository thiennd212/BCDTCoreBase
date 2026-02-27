import axios from 'axios'

const baseURL = import.meta.env.VITE_API_BASE_URL || ''

export const apiClient = axios.create({
  baseURL: baseURL || undefined,
  headers: { 'Content-Type': 'application/json' },
})

// --- Kiểu response chuẩn BCDT (khớp backend ApiSuccessResponse / ApiErrorResponse) ---
export interface ApiSuccessResponse<T> {
  success: true
  data: T
}
export interface ApiErrorItem {
  code: string
  message: string
  field?: string
}
export interface ApiErrorResponseBody {
  success: false
  errors: ApiErrorItem[]
}

/** Trích HTTP status từ lỗi (404, 400, 409, 401, 403, 500). Hoạt động với lỗi từ interceptor (có .status). */
export function getApiErrorStatus(err: unknown): number | undefined {
  if (err != null && typeof (err as { status?: number }).status === 'number')
    return (err as { status: number }).status
  return axios.isAxiosError(err) ? err.response?.status : undefined
}

/** Trích mã lỗi nghiệp vụ từ body (errors[0].code): NOT_FOUND, CONFLICT, VALIDATION_FAILED, ... Hoạt động với lỗi từ interceptor (có .code). */
export function getApiErrorCode(err: unknown): string | undefined {
  if (err != null && typeof (err as { code?: string }).code === 'string')
    return (err as { code: string }).code
  if (!axios.isAxiosError(err) || !err.response?.data) return undefined
  const data = err.response.data as ApiErrorResponseBody
  return data.errors?.[0]?.code
}

/** Chuẩn hóa lỗi API: ưu tiên message nghiệp vụ từ backend (errors[0].message), fallback theo HTTP status. */
export function getApiErrorMessage(err: unknown): string {
  if (axios.isAxiosError(err) && err.response?.data) {
    const data = err.response.data as ApiErrorResponseBody & { message?: string }
    if (data.errors?.length && data.errors[0].message) return data.errors[0].message
    if (typeof data.message === 'string') return data.message
  }
  if (axios.isAxiosError(err)) {
    const status = err.response?.status
    if (status === 404) return 'Không tìm thấy dữ liệu.'
    if (status === 403) return 'Bạn không có quyền thực hiện thao tác này.'
    if (status === 409) return 'Dữ liệu trùng hoặc xung đột.'
    if (status && status >= 500) return 'Lỗi hệ thống, vui lòng thử lại sau.'
    if (err.code === 'ERR_NETWORK') return 'Không kết nối được máy chủ.'
  }
  return err instanceof Error ? err.message : 'Đã xảy ra lỗi.'
}

/** Lỗi do không tìm thấy (HTTP 404 hoặc code NOT_FOUND). */
export function isApiNotFound(err: unknown): boolean {
  if (getApiErrorStatus(err) === 404) return true
  return getApiErrorCode(err) === 'NOT_FOUND'
}

/** Lỗi xung đột/trùng (HTTP 409 hoặc code CONFLICT). */
export function isApiConflict(err: unknown): boolean {
  if (getApiErrorStatus(err) === 409) return true
  return getApiErrorCode(err) === 'CONFLICT'
}

const TOKEN_KEY = 'bcdt_access_token'
const REFRESH_TOKEN_KEY = 'bcdt_refresh_token'

export function getStoredToken(): string | null {
  return localStorage.getItem(TOKEN_KEY)
}

export function setStoredToken(token: string): void {
  localStorage.setItem(TOKEN_KEY, token)
}

export function clearStoredToken(): void {
  localStorage.removeItem(TOKEN_KEY)
}

export function getStoredRefreshToken(): string | null {
  return localStorage.getItem(REFRESH_TOKEN_KEY)
}

export function setStoredRefreshToken(token: string): void {
  localStorage.setItem(REFRESH_TOKEN_KEY, token)
}

export function clearStoredRefreshToken(): void {
  localStorage.removeItem(REFRESH_TOKEN_KEY)
}

const CURRENT_ROLE_KEY = 'bcdt_current_role'

export function getStoredCurrentRole(): { id: number; code: string; name: string } | null {
  try {
    const raw = localStorage.getItem(CURRENT_ROLE_KEY)
    if (!raw) return null
    const o = JSON.parse(raw) as { id?: number; code?: string; name?: string }
    if (typeof o?.id === 'number' && o?.code != null && o?.name != null) return { id: o.id, code: o.code, name: o.name }
    return null
  } catch {
    return null
  }
}

export function setStoredCurrentRole(role: { id: number; code: string; name: string }): void {
  localStorage.setItem(CURRENT_ROLE_KEY, JSON.stringify(role))
}

export function clearStoredCurrentRole(): void {
  localStorage.removeItem(CURRENT_ROLE_KEY)
}

apiClient.interceptors.request.use((config) => {
  const token = getStoredToken()
  if (token) config.headers.Authorization = `Bearer ${token}`
  return config
})

const LOGIN_PATH = '/login'

let isRefreshing = false
let refreshSubscribers: Array<(token: string) => void> = []

function onRefreshed(token: string): void {
  refreshSubscribers.forEach((cb) => cb(token))
  refreshSubscribers = []
}

function addRefreshSubscriber(cb: (token: string) => void): void {
  refreshSubscribers.push(cb)
}

apiClient.interceptors.response.use(
  (res) => res,
  async (err) => {
    const originalRequest = err.config

    if (err.response?.status !== 401) {
      const msg = getApiErrorMessage(err)
      const e = new Error(msg) as Error & { code?: string; status?: number }
      e.code = getApiErrorCode(err)
      e.status = getApiErrorStatus(err)
      return Promise.reject(e)
    }

    const refreshToken = getStoredRefreshToken()
    const isLoginOrRefresh =
      originalRequest.url?.includes('/auth/login') ||
      originalRequest.url?.includes('/auth/refresh') ||
      originalRequest.url?.includes('/auth/logout')

    if (isLoginOrRefresh || !refreshToken) {
      clearStoredToken()
      clearStoredRefreshToken()
      if (!window.location.pathname.endsWith(LOGIN_PATH)) window.location.href = LOGIN_PATH
      const msg = getApiErrorMessage(err)
      const e = new Error(msg) as Error & { code?: string; status?: number }
      e.code = getApiErrorCode(err)
      e.status = getApiErrorStatus(err)
      return Promise.reject(e)
    }

    if (originalRequest._retry) {
      clearStoredToken()
      clearStoredRefreshToken()
      if (!window.location.pathname.endsWith(LOGIN_PATH)) window.location.href = LOGIN_PATH
      const msg = getApiErrorMessage(err)
      const e = new Error(msg) as Error & { code?: string; status?: number }
      e.code = getApiErrorCode(err)
      e.status = getApiErrorStatus(err)
      return Promise.reject(e)
    }

    if (isRefreshing) {
      return new Promise<unknown>((resolve, reject) => {
        addRefreshSubscriber((token: string) => {
          originalRequest.headers.Authorization = `Bearer ${token}`
          apiClient(originalRequest).then(resolve).catch(reject)
        })
      })
    }

    originalRequest._retry = true
    isRefreshing = true

    try {
      const { authApi } = await import('./authApi')
      const data = await authApi.refresh()
      setStoredToken(data.accessToken)
      if (data.refreshToken) setStoredRefreshToken(data.refreshToken)
      onRefreshed(data.accessToken)
      originalRequest.headers.Authorization = `Bearer ${data.accessToken}`
      return apiClient(originalRequest)
    } catch {
      clearStoredToken()
      clearStoredRefreshToken()
      if (!window.location.pathname.endsWith(LOGIN_PATH)) window.location.href = LOGIN_PATH
      const msg = getApiErrorMessage(err)
      const e = new Error(msg) as Error & { code?: string; status?: number }
      e.code = getApiErrorCode(err)
      e.status = getApiErrorStatus(err)
      return Promise.reject(e)
    } finally {
      isRefreshing = false
    }
  }
)
