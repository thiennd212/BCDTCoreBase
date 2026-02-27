import { apiClient } from './apiClient'
import type {
  ReportingPeriodDto,
  CreateReportingPeriodRequest,
  UpdateReportingPeriodRequest,
} from '../types/reportingPeriod.types'

export const reportingPeriodsApi = {
  getList: async (params?: {
    frequencyId?: number
    year?: number
    status?: string
    isCurrent?: boolean
  }): Promise<ReportingPeriodDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: ReportingPeriodDto[] }>(
      '/api/v1/reporting-periods',
      { params }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<ReportingPeriodDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: ReportingPeriodDto }>(
      `/api/v1/reporting-periods/${id}`
    )
    return res.data?.data ?? null
  },

  getCurrent: async (frequencyId?: number): Promise<ReportingPeriodDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: ReportingPeriodDto }>(
      '/api/v1/reporting-periods/current',
      { params: frequencyId != null ? { frequencyId } : undefined }
    )
    return res.data?.data ?? null
  },

  create: async (body: CreateReportingPeriodRequest): Promise<ReportingPeriodDto> => {
    const res = await apiClient.post<{ success: boolean; data: ReportingPeriodDto }>(
      '/api/v1/reporting-periods',
      body
    )
    if (!res.data?.data) throw new Error('Tạo kỳ báo cáo thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateReportingPeriodRequest): Promise<ReportingPeriodDto> => {
    const res = await apiClient.put<{ success: boolean; data: ReportingPeriodDto }>(
      `/api/v1/reporting-periods/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật kỳ báo cáo thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/reporting-periods/${id}`)
  },
}
