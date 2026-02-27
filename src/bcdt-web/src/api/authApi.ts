import { apiClient, tokenStore } from './apiClient'
import type { LoginRequest, LoginResponse, RefreshResponse, UserInfoDto, UserRoleItemDto } from '../types/auth.types'

export const authApi = {
  login: async (body: LoginRequest): Promise<LoginResponse> => {
    const res = await apiClient.post<{ success: boolean; data: LoginResponse }>(
      '/api/v1/auth/login',
      body,
      { withCredentials: true },
    )
    const data = res.data?.data
    if (!data?.accessToken) throw new Error('Đăng nhập thất bại')
    tokenStore.set(data.accessToken)
    return data
  },

  refresh: async (): Promise<RefreshResponse> => {
    const res = await apiClient.post<{ success: boolean; data: RefreshResponse }>(
      '/api/v1/auth/refresh',
      {},
      { withCredentials: true },
    )
    const data = res.data?.data
    if (!data?.accessToken) throw new Error('Refresh thất bại')
    tokenStore.set(data.accessToken)
    return data
  },

  logout: async (): Promise<void> => {
    await apiClient.post(
      '/api/v1/auth/logout',
      {},
      { withCredentials: true },
    )
    tokenStore.clear()
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
