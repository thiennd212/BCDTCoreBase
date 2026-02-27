import { apiClient } from './apiClient'
import type { RoleDto, CreateRoleRequest, UpdateRoleRequest } from '../types/role.types'

export const rolesApi = {
  getList: async (params?: { includeInactive?: boolean }): Promise<RoleDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: RoleDto[] }>('/api/v1/roles', { params })
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<RoleDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: RoleDto }>(`/api/v1/roles/${id}`)
    return res.data?.data ?? null
  },

  create: async (body: CreateRoleRequest): Promise<RoleDto> => {
    const res = await apiClient.post<{ success: boolean; data: RoleDto }>('/api/v1/roles', body)
    if (!res.data?.data) throw new Error('Tạo vai trò thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateRoleRequest): Promise<RoleDto> => {
    const res = await apiClient.put<{ success: boolean; data: RoleDto }>(`/api/v1/roles/${id}`, body)
    if (!res.data?.data) throw new Error('Cập nhật vai trò thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/roles/${id}`)
  },

  getPermissions: async (roleId: number): Promise<number[]> => {
    const res = await apiClient.get<{ success: boolean; data: { roleId: number; roleName: string; permissionIds: number[] } }>(`/api/v1/roles/${roleId}/permissions`)
    return res.data?.data?.permissionIds ?? []
  },

  setPermissions: async (roleId: number, permissionIds: number[]): Promise<void> => {
    await apiClient.put(`/api/v1/roles/${roleId}/permissions`, { permissionIds })
  },
}
