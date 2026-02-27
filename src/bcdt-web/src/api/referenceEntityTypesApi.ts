import { apiClient } from './apiClient'
import type {
  ReferenceEntityTypeDto,
  CreateReferenceEntityTypeRequest,
  UpdateReferenceEntityTypeRequest,
} from '../types/referenceEntity.types'

export const referenceEntityTypesApi = {
  getList: async (params?: { includeInactive?: boolean }): Promise<ReferenceEntityTypeDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: ReferenceEntityTypeDto[] }>(
      '/api/v1/reference-entity-types',
      { params }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<ReferenceEntityTypeDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: ReferenceEntityTypeDto }>(
      `/api/v1/reference-entity-types/${id}`
    )
    return res.data?.data ?? null
  },

  create: async (body: CreateReferenceEntityTypeRequest): Promise<ReferenceEntityTypeDto> => {
    const res = await apiClient.post<{ success: boolean; data: ReferenceEntityTypeDto }>(
      '/api/v1/reference-entity-types',
      body
    )
    if (!res.data?.data) throw new Error('Tạo loại thực thể thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateReferenceEntityTypeRequest): Promise<ReferenceEntityTypeDto> => {
    const res = await apiClient.put<{ success: boolean; data: ReferenceEntityTypeDto }>(
      `/api/v1/reference-entity-types/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật loại thực thể thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/reference-entity-types/${id}`)
  },
}
