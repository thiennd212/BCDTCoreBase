import { apiClient } from './apiClient'
import type {
  ReportingFrequencyDto,
  CreateReportingFrequencyRequest,
  UpdateReportingFrequencyRequest,
} from '../types/reportingPeriod.types'

export const reportingFrequenciesApi = {
  getList: async (params?: { includeInactive?: boolean }): Promise<ReportingFrequencyDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: ReportingFrequencyDto[] }>(
      '/api/v1/reporting-frequencies',
      { params }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<ReportingFrequencyDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: ReportingFrequencyDto }>(
      `/api/v1/reporting-frequencies/${id}`
    )
    return res.data?.data ?? null
  },

  create: async (body: CreateReportingFrequencyRequest): Promise<ReportingFrequencyDto> => {
    const res = await apiClient.post<{ success: boolean; data: ReportingFrequencyDto }>(
      '/api/v1/reporting-frequencies',
      body
    )
    if (!res.data?.data) throw new Error('Tạo chu kỳ thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateReportingFrequencyRequest): Promise<ReportingFrequencyDto> => {
    const res = await apiClient.put<{ success: boolean; data: ReportingFrequencyDto }>(
      `/api/v1/reporting-frequencies/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật chu kỳ thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/reporting-frequencies/${id}`)
  },
}
