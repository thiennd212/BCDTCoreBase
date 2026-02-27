import { apiClient } from './apiClient'
import type {
  OrganizationDto,
  CreateOrganizationRequest,
  UpdateOrganizationRequest,
} from '../types/organization.types'

export const organizationsApi = {
  getList: async (params?: { parentId?: number; organizationTypeId?: number; includeInactive?: boolean; all?: boolean }): Promise<OrganizationDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: OrganizationDto[] }>('/api/v1/organizations', { params })
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<OrganizationDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: OrganizationDto }>(`/api/v1/organizations/${id}`)
    return res.data?.data ?? null
  },

  create: async (body: CreateOrganizationRequest): Promise<OrganizationDto> => {
    const res = await apiClient.post<{ success: boolean; data: OrganizationDto }>('/api/v1/organizations', body)
    if (!res.data?.data) throw new Error('Tạo đơn vị thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateOrganizationRequest): Promise<OrganizationDto> => {
    const res = await apiClient.put<{ success: boolean; data: OrganizationDto }>(`/api/v1/organizations/${id}`, body)
    if (!res.data?.data) throw new Error('Cập nhật đơn vị thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/organizations/${id}`)
  },
}
