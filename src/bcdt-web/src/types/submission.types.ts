export interface ReportSubmissionDto {
  id: number
  formDefinitionId: number
  formVersionId: number
  organizationId: number
  reportingPeriodId: number
  status: string
  submittedAt?: string
  submittedBy?: number
  approvedAt?: string
  approvedBy?: number
  workflowInstanceId?: number
  currentWorkflowStep?: number
  isLocked: boolean
  version: number
  revisionNumber: number
  createdAt: string
  createdBy: number
  updatedAt?: string
  updatedBy?: number
}

export interface CreateReportSubmissionRequest {
  formDefinitionId: number
  formVersionId: number
  organizationId: number
  reportingPeriodId: number
  status?: string
}

export interface WorkflowInstanceDto {
  id: number
  submissionId: number
  workflowDefinitionId: number
  currentStep: number
  status: string
  startedAt: string
  completedAt?: string
}

/** Presentation (Layer 1) – WorkbookJson lưu dữ liệu nhập trên web hoặc từ upload Excel */
export interface ReportPresentationDto {
  id: number
  submissionId: number
  workbookJson: string
  workbookHash: string
  fileSize: number
  sheetCount: number
  lastModifiedAt: string
  lastModifiedBy: number
}

export interface CreateReportPresentationRequest {
  submissionId?: number
  workbookJson: string
  workbookHash: string
  fileSize: number
  sheetCount: number
}

/** Cấu trúc workbook trong FE (khớp backend: sheets[].name, sheets[].rows[] = { A: value, B: value, ... }) */
export interface WorkbookSheetData {
  name: string
  rows: Record<string, unknown>[]
}

/** Header cột (B12: colspan = số cột lá) */
export interface WorkbookColumnHeaderDto {
  excelColumn: string
  columnName: string
  colspan: number
  parentId?: number | null
  displayOrder: number
}

/** Một dòng chỉ tiêu động trong vùng */
export interface WorkbookDynamicIndicatorRowDto {
  indicatorName: string
  indicatorValue?: string | null
}

/** Vùng chỉ tiêu động trong sheet (B12) */
export interface WorkbookDynamicRegionDto {
  formDynamicRegionId: number
  excelRowStart: number
  excelColName: string
  excelColValue: string
  rows: WorkbookDynamicIndicatorRowDto[]
}

/** Sheet trong workbook-data (có thể có columnHeaders, dynamicRegions) */
export interface WorkbookSheetFromSubmissionDto {
  name: string
  rows: Record<string, unknown>[]
  columnHeaders?: WorkbookColumnHeaderDto[] | null
  dynamicRegions?: WorkbookDynamicRegionDto[] | null
}

/** Workbook xây từ cấu trúc biểu mẫu + ReportDataRow (tiêu chí hàng cột theo đơn vị). B12: columnHeaders, dynamicRegions. */
export interface WorkbookFromSubmissionDto {
  sheets: WorkbookSheetFromSubmissionDto[]
}

/** Một chỉ tiêu động (API GET dynamic-indicators) */
export interface ReportDynamicIndicatorItemDto {
  id: number
  formDynamicRegionId: number
  rowOrder: number
  indicatorId?: number | null
  indicatorName: string
  indicatorValue?: string | null
  dataType?: string | null
}

/** Body PUT dynamic-indicators */
export interface DynamicIndicatorItemRequest {
  formDynamicRegionId: number
  rowOrder: number
  indicatorId?: number | null
  indicatorName: string
  indicatorValue?: string | null
  dataType?: string | null
}

export interface PutDynamicIndicatorsRequest {
  items: DynamicIndicatorItemRequest[]
}
