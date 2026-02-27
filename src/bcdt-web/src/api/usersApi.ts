import { apiClient } from './apiClient'
import type { UserDto, CreateUserRequest, UpdateUserRequest } from '../types/user.types'

export const usersApi = {
  getList: async (params?: { organizationId?: number; includeInactive?: boolean }): Promise<UserDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: UserDto[] }>('/api/v1/users', { params })
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<UserDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: UserDto }>(`/api/v1/users/${id}`)
    return res.data?.data ?? null
  },

  create: async (body: CreateUserRequest): Promise<UserDto> => {
    const res = await apiClient.post<{ success: boolean; data: UserDto }>('/api/v1/users', body)
    if (!res.data?.data) throw new Error('Tạo người dùng thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateUserRequest): Promise<UserDto> => {
    const res = await apiClient.put<{ success: boolean; data: UserDto }>(`/api/v1/users/${id}`, body)
    if (!res.data?.data) throw new Error('Cập nhật người dùng thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/users/${id}`)
  },
}
