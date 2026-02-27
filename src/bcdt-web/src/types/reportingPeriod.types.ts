export interface ReportingFrequencyDto {
  id: number
  code: string
  name: string
  nameEn?: string
  daysInPeriod: number
  cronExpression?: string
  description?: string
  displayOrder: number
  isActive: boolean
  createdAt: string
}

export interface CreateReportingFrequencyRequest {
  code: string
  name: string
  nameEn?: string
  daysInPeriod: number
  cronExpression?: string
  description?: string
  displayOrder: number
  isActive: boolean
}

export interface UpdateReportingFrequencyRequest {
  name: string
  nameEn?: string
  daysInPeriod: number
  cronExpression?: string
  description?: string
  displayOrder: number
  isActive: boolean
}

export interface ReportingPeriodDto {
  id: number
  reportingFrequencyId: number
  periodCode: string
  periodName: string
  year: number
  quarter?: number
  month?: number
  week?: number
  day?: number
  startDate: string
  endDate: string
  deadline?: string
  status: string
  isCurrent: boolean
  isLocked: boolean
  createdAt: string
}

export interface CreateReportingPeriodRequest {
  reportingFrequencyId: number
  periodCode: string
  periodName: string
  year: number
  quarter?: number
  month?: number
  startDate: string
  endDate: string
  deadline?: string
  status?: string
  isCurrent?: boolean
}

export interface UpdateReportingPeriodRequest {
  status?: string
  isCurrent?: boolean
  isLocked?: boolean
}
