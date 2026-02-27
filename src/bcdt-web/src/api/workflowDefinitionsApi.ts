import { apiClient } from './apiClient'
import type {
  WorkflowDefinitionDto,
  CreateWorkflowDefinitionRequest,
  UpdateWorkflowDefinitionRequest,
  WorkflowStepDto,
  CreateWorkflowStepRequest,
  UpdateWorkflowStepRequest,
  FormWorkflowConfigDto,
  CreateFormWorkflowConfigRequest,
} from '../types/workflow.types'

// ─── WorkflowDefinitions ────────────────────────────────────────

export const workflowDefinitionsApi = {
  getList: async (params?: { includeInactive?: boolean }): Promise<WorkflowDefinitionDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: WorkflowDefinitionDto[] }>(
      '/api/v1/workflow-definitions',
      { params },
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<WorkflowDefinitionDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: WorkflowDefinitionDto }>(
      `/api/v1/workflow-definitions/${id}`,
    )
    return res.data?.data ?? null
  },

  create: async (body: CreateWorkflowDefinitionRequest): Promise<WorkflowDefinitionDto> => {
    const res = await apiClient.post<{ success: boolean; data: WorkflowDefinitionDto }>(
      '/api/v1/workflow-definitions',
      body,
    )
    if (!res.data?.data) throw new Error('Tạo quy trình thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateWorkflowDefinitionRequest): Promise<WorkflowDefinitionDto> => {
    const res = await apiClient.put<{ success: boolean; data: WorkflowDefinitionDto }>(
      `/api/v1/workflow-definitions/${id}`,
      body,
    )
    if (!res.data?.data) throw new Error('Cập nhật quy trình thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/workflow-definitions/${id}`)
  },
}

// ─── WorkflowSteps ──────────────────────────────────────────────

export const workflowStepsApi = {
  getList: async (workflowDefinitionId: number): Promise<WorkflowStepDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: WorkflowStepDto[] }>(
      `/api/v1/workflow-definitions/${workflowDefinitionId}/steps`,
    )
    return res.data?.data ?? []
  },

  getById: async (workflowDefinitionId: number, stepId: number): Promise<WorkflowStepDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: WorkflowStepDto }>(
      `/api/v1/workflow-definitions/${workflowDefinitionId}/steps/${stepId}`,
    )
    return res.data?.data ?? null
  },

  create: async (workflowDefinitionId: number, body: CreateWorkflowStepRequest): Promise<WorkflowStepDto> => {
    const res = await apiClient.post<{ success: boolean; data: WorkflowStepDto }>(
      `/api/v1/workflow-definitions/${workflowDefinitionId}/steps`,
      body,
    )
    if (!res.data?.data) throw new Error('Tạo bước duyệt thất bại')
    return res.data.data
  },

  update: async (
    workflowDefinitionId: number,
    stepId: number,
    body: UpdateWorkflowStepRequest,
  ): Promise<WorkflowStepDto> => {
    const res = await apiClient.put<{ success: boolean; data: WorkflowStepDto }>(
      `/api/v1/workflow-definitions/${workflowDefinitionId}/steps/${stepId}`,
      body,
    )
    if (!res.data?.data) throw new Error('Cập nhật bước duyệt thất bại')
    return res.data.data
  },

  delete: async (workflowDefinitionId: number, stepId: number): Promise<void> => {
    await apiClient.delete(`/api/v1/workflow-definitions/${workflowDefinitionId}/steps/${stepId}`)
  },
}

// ─── FormWorkflowConfig ─────────────────────────────────────────

export const formWorkflowConfigApi = {
  getByFormId: async (formId: number): Promise<FormWorkflowConfigDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormWorkflowConfigDto[] }>(
      `/api/v1/forms/${formId}/workflow-config`,
    )
    return res.data?.data ?? []
  },

  create: async (formId: number, body: CreateFormWorkflowConfigRequest): Promise<FormWorkflowConfigDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormWorkflowConfigDto }>(
      `/api/v1/forms/${formId}/workflow-config`,
      body,
    )
    if (!res.data?.data) throw new Error('Gắn workflow cho biểu mẫu thất bại')
    return res.data.data
  },

  delete: async (formId: number, configId: number): Promise<void> => {
    await apiClient.delete(`/api/v1/forms/${formId}/workflow-config/${configId}`)
  },
}
