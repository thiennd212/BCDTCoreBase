// ─── WorkflowDefinition ─────────────────────────────────────────

export interface WorkflowDefinitionDto {
  id: number
  code: string
  name: string
  description?: string | null
  totalSteps: number
  isDefault: boolean
  isActive: boolean
  createdAt: string
  createdBy: number
  updatedAt?: string | null
  updatedBy?: number | null
}

export interface CreateWorkflowDefinitionRequest {
  code: string
  name: string
  description?: string | null
  totalSteps: number
  isDefault: boolean
  isActive: boolean
}

export interface UpdateWorkflowDefinitionRequest {
  code: string
  name: string
  description?: string | null
  totalSteps: number
  isDefault: boolean
  isActive: boolean
}

// ─── WorkflowStep ───────────────────────────────────────────────

export interface WorkflowStepDto {
  id: number
  workflowDefinitionId: number
  stepOrder: number
  stepName: string
  stepDescription?: string | null
  approverRoleId?: number | null
  approverRoleCode?: string | null
  approverUserId?: number | null
  canReject: boolean
  canRequestRevision: boolean
  autoApproveAfterDays?: number | null
  notifyOnPending: boolean
  notifyOnApprove: boolean
  notifyOnReject: boolean
  isActive: boolean
}

export interface CreateWorkflowStepRequest {
  stepOrder: number
  stepName: string
  stepDescription?: string | null
  approverRoleId?: number | null
  approverUserId?: number | null
  canReject: boolean
  canRequestRevision: boolean
  autoApproveAfterDays?: number | null
  notifyOnPending: boolean
  notifyOnApprove: boolean
  notifyOnReject: boolean
  isActive: boolean
}

export interface UpdateWorkflowStepRequest extends CreateWorkflowStepRequest {}

// ─── FormWorkflowConfig ─────────────────────────────────────────

export interface FormWorkflowConfigDto {
  id: number
  formDefinitionId: number
  formDefinitionCode?: string | null
  workflowDefinitionId: number
  workflowDefinitionCode?: string | null
  organizationTypeId?: number | null
  organizationTypeCode?: string | null
  isActive: boolean
  createdAt: string
  createdBy: number
}

export interface CreateFormWorkflowConfigRequest {
  formDefinitionId: number
  workflowDefinitionId: number
  organizationTypeId?: number | null
  isActive: boolean
}
