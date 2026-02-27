import { apiClient } from './apiClient'
import type {
  OrganizationTypeDto,
  CreateOrganizationTypeRequest,
  UpdateOrganizationTypeRequest,
} from '../types/organization.types'

export const organizationTypesApi = {
  getList: async (params?: { includeInactive?: boolean }): Promise<OrganizationTypeDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: OrganizationTypeDto[] }>(
      '/api/v1/organization-types',
      { params }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<OrganizationTypeDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: OrganizationTypeDto }>(
      `/api/v1/organization-types/${id}`
    )
    return res.data?.data ?? null
  },

  create: async (body: CreateOrganizationTypeRequest): Promise<OrganizationTypeDto> => {
    const res = await apiClient.post<{ success: boolean; data: OrganizationTypeDto }>(
      '/api/v1/organization-types',
      body
    )
    if (!res.data?.data) throw new Error('Tạo loại đơn vị thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateOrganizationTypeRequest): Promise<OrganizationTypeDto> => {
    const res = await apiClient.put<{ success: boolean; data: OrganizationTypeDto }>(
      `/api/v1/organization-types/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật loại đơn vị thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/organization-types/${id}`)
  },
}
