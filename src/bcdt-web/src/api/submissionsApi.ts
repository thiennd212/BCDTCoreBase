import { apiClient } from './apiClient'
import type {
  ReportSubmissionDto,
  CreateReportSubmissionRequest,
  WorkflowInstanceDto,
  ReportPresentationDto,
  CreateReportPresentationRequest,
  WorkbookFromSubmissionDto,
  ReportDynamicIndicatorItemDto,
  PutDynamicIndicatorsRequest,
} from '../types/submission.types'

export const submissionsApi = {
  getList: async (params?: {
    formDefinitionId?: number
    organizationId?: number
    reportingPeriodId?: number
    status?: string
    includeDeleted?: boolean
  }): Promise<ReportSubmissionDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: ReportSubmissionDto[] }>(
      '/api/v1/submissions',
      { params }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<ReportSubmissionDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: ReportSubmissionDto }>(
      `/api/v1/submissions/${id}`
    )
    return res.data?.data ?? null
  },

  create: async (body: CreateReportSubmissionRequest): Promise<ReportSubmissionDto> => {
    const res = await apiClient.post<{ success: boolean; data: ReportSubmissionDto }>(
      '/api/v1/submissions',
      body
    )
    if (!res.data?.data) throw new Error('Tạo báo cáo thất bại')
    return res.data.data
  },

  submit: async (id: number): Promise<WorkflowInstanceDto> => {
    const res = await apiClient.post<{ success: boolean; data: WorkflowInstanceDto }>(
      `/api/v1/submissions/${id}/submit`
    )
    if (!res.data?.data) throw new Error('Gửi duyệt thất bại')
    return res.data.data
  },

  getWorkflowInstance: async (submissionId: number): Promise<WorkflowInstanceDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: WorkflowInstanceDto }>(
      `/api/v1/submissions/${submissionId}/workflow-instance`
    )
    return res.data?.data ?? null
  },

  uploadExcel: async (id: number, file: File): Promise<unknown> => {
    const formData = new FormData()
    formData.append('file', file)
    const res = await apiClient.post<{ success: boolean; data: unknown }>(
      `/api/v1/submissions/${id}/upload-excel`,
      formData,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    )
    return res.data?.data
  },

  /** Dữ liệu workbook từ cấu trúc biểu mẫu và ReportDataRow (tiêu chí hàng cột theo đơn vị). 404 = chưa có, trả null không báo lỗi. */
  getWorkbookData: async (submissionId: number): Promise<WorkbookFromSubmissionDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: WorkbookFromSubmissionDto }>(
      `/api/v1/submissions/${submissionId}/workbook-data`,
      { validateStatus: (status) => status === 200 || status === 404 }
    )
    if (res.status === 404) return null
    return res.data?.data ?? null
  },

  /** Presentation (workbookJson đã lưu). Backend trả 200 với data = null khi chưa có (không dùng 404). */
  getPresentation: async (submissionId: number): Promise<ReportPresentationDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: ReportPresentationDto | null }>(
      `/api/v1/submissions/${submissionId}/presentation`
    )
    return res.data?.data ?? null
  },

  putPresentation: async (
    submissionId: number,
    body: CreateReportPresentationRequest
  ): Promise<ReportPresentationDto> => {
    const res = await apiClient.put<{ success: boolean; data: ReportPresentationDto }>(
      `/api/v1/submissions/${submissionId}/presentation`,
      { ...body, submissionId: submissionId }
    )
    if (!res.data?.data) throw new Error('Lưu dữ liệu thất bại')
    return res.data.data
  },

  /** Đồng bộ ReportDataRow từ WorkbookJson đã lưu (sau khi nhập liệu web). */
  syncFromPresentation: async (submissionId: number): Promise<{ dataRowCount: number; message?: string }> => {
    const res = await apiClient.post<{ success: boolean; data: { dataRowCount: number; message?: string } }>(
      `/api/v1/submissions/${submissionId}/sync-from-presentation`
    )
    if (!res.data?.data) throw new Error('Đồng bộ thất bại')
    return res.data.data
  },

  /** Danh sách chỉ tiêu động của submission (B12). */
  getDynamicIndicators: async (submissionId: number): Promise<ReportDynamicIndicatorItemDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: ReportDynamicIndicatorItemDto[] }>(
      `/api/v1/submissions/${submissionId}/dynamic-indicators`
    )
    return res.data?.data ?? []
  },

  /** Ghi đè danh sách chỉ tiêu động (batch). */
  putDynamicIndicators: async (
    submissionId: number,
    body: PutDynamicIndicatorsRequest
  ): Promise<void> => {
    await apiClient.put(
      `/api/v1/submissions/${submissionId}/dynamic-indicators`,
      body
    )
  },
}
