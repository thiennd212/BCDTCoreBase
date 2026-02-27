import { apiClient } from './apiClient'
import type {
  ReferenceEntityDto,
  CreateReferenceEntityRequest,
  UpdateReferenceEntityRequest,
} from '../types/referenceEntity.types'

export const referenceEntitiesApi = {
  getList: async (params?: {
    entityTypeId?: number
    parentId?: number
    includeInactive?: boolean
    all?: boolean
  }): Promise<ReferenceEntityDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: ReferenceEntityDto[] }>(
      '/api/v1/reference-entities',
      { params }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<ReferenceEntityDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: ReferenceEntityDto }>(
      `/api/v1/reference-entities/${id}`
    )
    return res.data?.data ?? null
  },

  create: async (body: CreateReferenceEntityRequest): Promise<ReferenceEntityDto> => {
    const res = await apiClient.post<{ success: boolean; data: ReferenceEntityDto }>(
      '/api/v1/reference-entities',
      body
    )
    if (!res.data?.data) throw new Error('Tạo thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateReferenceEntityRequest): Promise<ReferenceEntityDto> => {
    const res = await apiClient.put<{ success: boolean; data: ReferenceEntityDto }>(
      `/api/v1/reference-entities/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/reference-entities/${id}`)
  },
}
