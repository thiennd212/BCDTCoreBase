import { apiClient } from './apiClient'
import type { PermissionDto, CreatePermissionRequest, UpdatePermissionRequest } from '../types/permission.types'

export const permissionsApi = {
  /** Lấy danh sách quyền (flat, không nhóm) */
  getAll: async (): Promise<PermissionDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: PermissionDto[] }>('/api/v1/permissions/flat')
    return res.data?.data ?? []
  },

  /** Lấy chi tiết quyền theo Id */
  getById: async (id: number): Promise<PermissionDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: PermissionDto }>(`/api/v1/permissions/${id}`)
    return res.data?.data ?? null
  },

  /** Tạo quyền mới */
  create: async (body: CreatePermissionRequest): Promise<PermissionDto> => {
    const res = await apiClient.post<{ success: boolean; data: PermissionDto }>('/api/v1/permissions', body)
    return res.data.data
  },

  /** Cập nhật quyền */
  update: async (id: number, body: UpdatePermissionRequest): Promise<PermissionDto> => {
    const res = await apiClient.put<{ success: boolean; data: PermissionDto }>(`/api/v1/permissions/${id}`, body)
    return res.data.data
  },

  /** Xóa quyền */
  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/permissions/${id}`)
  },
}
