import { apiClient } from './apiClient'
import type { SystemConfigDto, UpdateSystemConfigRequest } from '../types/systemConfig.types'

export const systemConfigApi = {
  /** Danh sách tất cả cấu hình */
  getAll: async (): Promise<SystemConfigDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: SystemConfigDto[] }>('/api/v1/system-config')
    return res.data?.data ?? []
  },

  /** Lấy cấu hình theo key */
  getByKey: async (key: string): Promise<SystemConfigDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: SystemConfigDto }>(`/api/v1/system-config/${encodeURIComponent(key)}`)
    return res.data?.data ?? null
  },

  /** Cập nhật giá trị cấu hình */
  update: async (key: string, body: UpdateSystemConfigRequest): Promise<SystemConfigDto> => {
    const res = await apiClient.put<{ success: boolean; data: SystemConfigDto }>(
      `/api/v1/system-config/${encodeURIComponent(key)}`,
      body
    )
    return res.data.data
  },
}
