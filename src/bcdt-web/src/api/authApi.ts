import { apiClient } from './apiClient'
import type { LoginRequest, LoginResponse, RefreshResponse, UserInfoDto, UserRoleItemDto } from '../types/auth.types'
import { setStoredToken, setStoredRefreshToken, getStoredRefreshToken } from './apiClient'

export const authApi = {
  login: async (body: LoginRequest): Promise<LoginResponse> => {
    const res = await apiClient.post<{ success: boolean; data: LoginResponse }>('/api/v1/auth/login', body)
    const data = res.data?.data
    if (!data?.accessToken) throw new Error('Đăng nhập thất bại')
    setStoredToken(data.accessToken)
    if (data.refreshToken) setStoredRefreshToken(data.refreshToken)
    return data
  },

  refresh: async (): Promise<RefreshResponse> => {
    const refreshToken = getStoredRefreshToken()
    if (!refreshToken) throw new Error('Không có refresh token')
    const res = await apiClient.post<{ success: boolean; data: RefreshResponse }>('/api/v1/auth/refresh', {
      refreshToken,
    })
    const data = res.data?.data
    if (!data?.accessToken) throw new Error('Refresh thất bại')
    return data
  },

  logout: async (): Promise<void> => {
    const refreshToken = getStoredRefreshToken()
    if (refreshToken) {
      try {
        await apiClient.post('/api/v1/auth/logout', { refreshToken })
      } catch {
        // Bỏ qua lỗi (mạng, 401): vẫn xóa token ở client
      }
    }
  },

  me: async (): Promise<UserInfoDto> => {
    const res = await apiClient.get<{ success: boolean; data: UserInfoDto }>('/api/v1/auth/me')
    return res.data?.data as UserInfoDto
  },

  /** Danh sách vai trò của user hiện tại (để chuyển vai trò) */
  getMyRoles: async (): Promise<UserRoleItemDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: UserRoleItemDto[] }>('/api/v1/auth/me/roles')
    return res.data?.data ?? []
  },

  changePassword: async (currentPassword: string, newPassword: string): Promise<void> => {
    await apiClient.post('/api/v1/auth/change-password', {
      currentPassword,
      newPassword,
    })
  },
}
