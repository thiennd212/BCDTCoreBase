export interface SubmissionsByPeriodDto {
  reportingPeriodId: number
  periodCode: string
  periodName: string
  count: number
}

export interface SubmissionsByFormDto {
  formDefinitionId: number
  formCode: string
  formName: string
  count: number
}

export interface DashboardAdminStatsDto {
  totalSubmissions: number
  draftCount: number
  submittedCount: number
  approvedCount: number
  rejectedCount: number
  revisionCount: number
  submissionsByPeriod: SubmissionsByPeriodDto[]
  submissionsByForm: SubmissionsByFormDto[]
}

export interface SubmissionTaskDto {
  submissionId: number
  formDefinitionId: number
  formName: string
  reportingPeriodId: number
  periodName: string
  deadline?: string
  status: string
}

export interface PeriodDeadlineDto {
  reportingPeriodId: number
  periodCode: string
  periodName: string
  deadline: string
  formCount: number
}

export interface PendingApprovalTaskDto {
  workflowInstanceId: number
  submissionId: number
  formName: string
  organizationName: string
  periodName: string
  currentStep: number
  totalSteps: number
  submittedAt?: string
}

export interface DashboardUserTasksDto {
  drafts: SubmissionTaskDto[]
  revisions: SubmissionTaskDto[]
  upcomingDeadlines: PeriodDeadlineDto[]
  pendingApprovals: PendingApprovalTaskDto[]
}
