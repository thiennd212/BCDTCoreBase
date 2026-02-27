import { apiClient } from './apiClient'
import type { WorkflowInstanceDto } from '../types/submission.types'

export interface WorkflowActionRequest {
  comments?: string
}

export const workflowInstancesApi = {
  approve: async (id: number, body?: WorkflowActionRequest): Promise<WorkflowInstanceDto> => {
    const res = await apiClient.post<{ success: boolean; data: WorkflowInstanceDto }>(
      `/api/v1/workflow-instances/${id}/approve`,
      body ?? {}
    )
    if (!res.data?.data) throw new Error('Duyệt thất bại')
    return res.data.data
  },

  reject: async (id: number, body?: WorkflowActionRequest): Promise<WorkflowInstanceDto> => {
    const res = await apiClient.post<{ success: boolean; data: WorkflowInstanceDto }>(
      `/api/v1/workflow-instances/${id}/reject`,
      body ?? {}
    )
    if (!res.data?.data) throw new Error('Từ chối thất bại')
    return res.data.data
  },

  requestRevision: async (id: number, body?: WorkflowActionRequest): Promise<WorkflowInstanceDto> => {
    const res = await apiClient.post<{ success: boolean; data: WorkflowInstanceDto }>(
      `/api/v1/workflow-instances/${id}/request-revision`,
      body ?? {}
    )
    if (!res.data?.data) throw new Error('Yêu cầu chỉnh sửa thất bại')
    return res.data.data
  },
}
