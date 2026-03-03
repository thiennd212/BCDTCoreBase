import { apiClient } from './apiClient'
import type { WorkflowInstanceDto } from '../types/submission.types'

export interface WorkflowActionRequest {
  comments?: string
}

export interface BulkApproveRequest {
  workflowInstanceIds: number[]
  comments?: string
}

export interface BulkApproveFailureItem {
  workflowInstanceId: number
  code: string
  message: string
}

export interface BulkApproveResultDto {
  succeededIds: number[]
  failed: BulkApproveFailureItem[]
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

  bulkApprove: async (body: BulkApproveRequest): Promise<BulkApproveResultDto> => {
    const res = await apiClient.post<{ success: boolean; data: BulkApproveResultDto }>(
      '/api/v1/workflow-instances/bulk-approve',
      body
    )
    if (!res.data?.data) throw new Error('Duyệt hàng loạt thất bại')
    return res.data.data
  },
}
