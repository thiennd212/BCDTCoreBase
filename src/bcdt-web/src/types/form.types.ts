export interface FormDefinitionDto {
  id: number
  code: string
  name: string
  description?: string
  formType?: string
  reportingFrequencyId?: number
  status: string
  isActive?: boolean
  isDeleted?: boolean
  deadlineOffsetDays?: number
  allowLateSubmission?: boolean
  requireApproval?: boolean
  autoCreateReport?: boolean
  templateFileName?: string
  /** True nếu đã upload template và có template display (dùng làm base hiển thị nhập liệu). */
  hasTemplateDisplay?: boolean
  createdAt: string
}

export interface CreateFormDefinitionRequest {
  code: string
  name: string
  description?: string
  formType?: string
  reportingFrequencyId?: number
  deadlineOffsetDays?: number
  allowLateSubmission?: boolean
  requireApproval?: boolean
  autoCreateReport?: boolean
  isActive?: boolean
}

export interface UpdateFormDefinitionRequest extends CreateFormDefinitionRequest {
  status?: string
}

export interface FormVersionDto {
  id: number
  formDefinitionId: number
  versionName: string
  changeDescription?: string
  isActive: boolean
  createdAt: string
}

// --- Sheet ---
export interface FormSheetDto {
  id: number
  formDefinitionId: number
  sheetIndex: number
  sheetName: string
  displayName?: string
  description?: string
  isDataSheet: boolean
  isVisible: boolean
  displayOrder: number
  /** Hàng bắt đầu dữ liệu (1-based). Dùng cho template: từ hàng này trở đi điền dữ liệu. Để trống = tự động từ header cột. */
  dataStartRow?: number | null
  createdAt: string
}

export interface CreateFormSheetRequest {
  sheetIndex: number
  sheetName: string
  displayName?: string
  description?: string
  isDataSheet?: boolean
  isVisible?: boolean
  displayOrder: number
  dataStartRow?: number | null
}

export interface UpdateFormSheetRequest extends CreateFormSheetRequest {}

// --- Column ---
export interface FormColumnDto {
  id: number
  formSheetId: number
  parentId?: number | null
  indicatorId?: number | null
  columnCode: string
  columnName: string
  /** Nhóm cột tầng 1 (header cha) cho phân cấp Excel */
  columnGroupName?: string | null
  /** Nhóm cột tầng 2–4 cho header nhiều tầng */
  columnGroupLevel2?: string | null
  columnGroupLevel3?: string | null
  columnGroupLevel4?: string | null
  /** Ký tự cột Excel (A, B, ...). Null/undefined → tính tại runtime theo LayoutOrder. */
  excelColumn?: string | null
  /** Thứ tự trong layout tổng của sheet. Dùng chung namespace với PlaceholderOccurrence để gán ExcelColumn runtime. */
  layoutOrder: number
  dataType: string
  isRequired: boolean
  isEditable: boolean
  isHidden: boolean
  defaultValue?: string
  formula?: string
  validationRule?: string
  validationMessage?: string
  displayOrder: number
  width?: number
  format?: string
  createdAt: string
}

export interface FormColumnTreeDto extends FormColumnDto {
  children?: FormColumnTreeDto[]
}

export interface CreateFormColumnRequest {
  parentId?: number | null
  indicatorId?: number | null
  columnCode: string
  columnName: string
  columnGroupName?: string | null
  columnGroupLevel2?: string | null
  columnGroupLevel3?: string | null
  columnGroupLevel4?: string | null
  excelColumn?: string | null
  layoutOrder?: number
  dataType?: string
  isRequired?: boolean
  isEditable?: boolean
  isHidden?: boolean
  defaultValue?: string
  formula?: string
  validationRule?: string
  validationMessage?: string
  displayOrder?: number
  width?: number
  format?: string
}

export interface UpdateFormColumnRequest extends CreateFormColumnRequest {}

// --- Data Binding (bộ lọc dữ liệu / nguồn dữ liệu) ---
export interface FormDataBindingDto {
  id: number
  formColumnId: number
  bindingType: string
  sourceTable?: string
  sourceColumn?: string
  sourceCondition?: string
  apiEndpoint?: string
  apiMethod?: string
  apiResponsePath?: string
  formula?: string
  referenceEntityTypeId?: number
  referenceDisplayColumn?: string
  defaultValue?: string
  transformExpression?: string
  cacheMinutes: number
  isActive: boolean
  createdAt: string
}

export interface CreateFormDataBindingRequest {
  bindingType?: string
  sourceTable?: string
  sourceColumn?: string
  sourceCondition?: string
  apiEndpoint?: string
  apiMethod?: string
  apiResponsePath?: string
  formula?: string
  referenceEntityTypeId?: number
  referenceDisplayColumn?: string
  defaultValue?: string
  transformExpression?: string
  cacheMinutes?: number
  isActive?: boolean
}

export interface UpdateFormDataBindingRequest extends CreateFormDataBindingRequest {}

// --- Column Mapping (ánh xạ cột khi lưu) ---
export interface FormColumnMappingDto {
  id: number
  formColumnId: number
  targetColumnName: string
  targetColumnIndex: number
  aggregateFunction?: string
  createdAt: string
}

export interface CreateFormColumnMappingRequest {
  targetColumnName: string
  targetColumnIndex: number
  aggregateFunction?: string
}

export interface UpdateFormColumnMappingRequest extends CreateFormColumnMappingRequest {}

// --- Dynamic Region (B12 – vùng chỉ tiêu động) ---
export interface FormDynamicRegionDto {
  id: number
  formSheetId: number
  excelRowStart: number
  excelRowEnd?: number | null
  excelColName: string
  excelColValue: string
  maxRows: number
  indicatorExpandDepth: number
  indicatorCatalogId?: number | null
  displayOrder: number
  createdAt: string
  createdBy: number
}

export interface CreateFormDynamicRegionRequest {
  excelRowStart: number
  excelRowEnd?: number | null
  excelColName: string
  excelColValue: string
  maxRows?: number
  indicatorExpandDepth?: number
  indicatorCatalogId?: number | null
  displayOrder?: number
}

export interface UpdateFormDynamicRegionRequest {
  excelRowStart: number
  excelRowEnd?: number | null
  excelColName: string
  excelColValue: string
  maxRows: number
  indicatorExpandDepth: number
  indicatorCatalogId?: number | null
  displayOrder: number
}

// --- Form Row (B12 P2a – hàng trong sheet, phân cấp) ---
export interface FormRowDto {
  id: number
  formSheetId: number
  rowCode?: string | null
  rowName?: string | null
  excelRowStart: number
  excelRowEnd?: number | null
  rowType: string
  isRepeating: boolean
  referenceEntityTypeId?: number | null
  parentId?: number | null
  formDynamicRegionId?: number | null
  displayOrder: number
  height?: number | null
  /** Hàng có cho nhập dữ liệu không. false = Fortune Sheet cell read-only. */
  isEditable: boolean
  /** Bắt buộc nhập dữ liệu cho hàng này. */
  isRequired: boolean
  /** Công thức cấp hàng (placeholder-based). Kết hợp với FormRowFormulaScope. */
  formula?: string | null
  /** Liên kết tới Indicator trong danh mục dùng chung. null = hàng tự định nghĩa. */
  indicatorId?: number | null
  createdAt: string
  createdBy: number
}

export interface FormRowTreeDto extends FormRowDto {
  children?: FormRowTreeDto[]
}

export interface CreateFormRowRequest {
  rowCode?: string | null
  rowName?: string | null
  excelRowStart: number
  excelRowEnd?: number | null
  rowType?: string
  isRepeating?: boolean
  referenceEntityTypeId?: number | null
  parentId?: number | null
  formDynamicRegionId?: number | null
  displayOrder?: number
  height?: number | null
  isEditable?: boolean
  isRequired?: boolean
  formula?: string | null
  /** Liên kết tới Indicator trong danh mục dùng chung. */
  indicatorId?: number | null
}

export interface UpdateFormRowRequest extends CreateFormRowRequest {}

// --- FormRowFormulaScope ---
export interface FormRowFormulaScopeDto {
  id: number
  formRowId: number
  formColumnId: number
  createdAt: string
  createdBy: number
}

export interface CreateFormRowFormulaScopeRequest {
  formColumnId: number
}

// --- FormCellFormula ---
export interface FormCellFormulaDto {
  id: number
  formSheetId: number
  formColumnId: number
  formRowId: number
  formula?: string | null
  isEditable?: boolean | null
  createdAt: string
  createdBy: number
  updatedAt?: string | null
  updatedBy?: number | null
}

export interface CreateFormCellFormulaRequest {
  formColumnId: number
  formRowId: number
  formula?: string | null
  isEditable?: boolean | null
}

// --- P8: DataSource, FilterDefinition, FormPlaceholderOccurrence ---
export interface DataSourceDto {
  id: number
  code: string
  name: string
  sourceType: string
  sourceRef?: string | null
  indicatorCatalogId?: number | null
  displayColumn?: string | null
  valueColumn?: string | null
  isActive: boolean
  createdAt: string
  createdBy: number
}

export interface CreateDataSourceRequest {
  code: string
  name: string
  sourceType?: string
  sourceRef?: string | null
  indicatorCatalogId?: number | null
  displayColumn?: string | null
  valueColumn?: string | null
  isActive?: boolean
}

export interface UpdateDataSourceRequest {
  name: string
  sourceType: string
  sourceRef?: string | null
  indicatorCatalogId?: number | null
  displayColumn?: string | null
  valueColumn?: string | null
  isActive: boolean
}

export interface DataSourceColumnDto {
  columnName: string
  dataType?: string
}

export interface FilterConditionDto {
  id: number
  filterDefinitionId: number
  conditionOrder: number
  field: string
  operator: string
  valueType: string
  value?: string | null
  value2?: string | null
  dataType?: string | null
}

export interface FilterDefinitionDto {
  id: number
  code: string
  name: string
  logicalOperator: string
  dataSourceId?: number | null
  conditions: FilterConditionDto[]
  createdAt: string
  createdBy: number
}

export interface CreateFilterConditionItem {
  conditionOrder: number
  field: string
  operator: string
  valueType?: string
  value?: string | null
  value2?: string | null
  dataType?: string | null
}

export interface CreateFilterDefinitionRequest {
  code: string
  name: string
  logicalOperator?: string
  dataSourceId?: number | null
  conditions?: CreateFilterConditionItem[]
}

export interface UpdateFilterConditionItem {
  id: number
  conditionOrder: number
  field: string
  operator: string
  valueType?: string
  value?: string | null
  value2?: string | null
  dataType?: string | null
}

export interface UpdateFilterDefinitionRequest {
  name: string
  logicalOperator: string
  dataSourceId?: number | null
  conditions: UpdateFilterConditionItem[]
}

export interface FormPlaceholderOccurrenceDto {
  id: number
  formSheetId: number
  formDynamicRegionId: number
  excelRowStart: number
  filterDefinitionId?: number | null
  dataSourceId?: number | null
  displayOrder: number
  maxRows?: number | null
  createdAt: string
  createdBy: number
}

export interface CreateFormPlaceholderOccurrenceRequest {
  formDynamicRegionId: number
  excelRowStart: number
  filterDefinitionId?: number | null
  dataSourceId?: number | null
  displayOrder: number
  maxRows?: number | null
}

export interface UpdateFormPlaceholderOccurrenceRequest extends CreateFormPlaceholderOccurrenceRequest {}

// P8e – Placeholder cột (FormDynamicColumnRegion, FormPlaceholderColumnOccurrence)
export interface FormDynamicColumnRegionDto {
  id: number
  formSheetId: number
  code: string
  name: string
  columnSourceType: string
  columnSourceRef?: string | null
  labelColumn?: string | null
  displayOrder: number
  isActive: boolean
  createdAt: string
  createdBy: number
}

export interface CreateFormDynamicColumnRegionRequest {
  code: string
  name: string
  columnSourceType: string
  columnSourceRef?: string | null
  labelColumn?: string | null
  displayOrder: number
  isActive?: boolean
}

export interface UpdateFormDynamicColumnRegionRequest extends CreateFormDynamicColumnRegionRequest {}

export interface FormPlaceholderColumnOccurrenceDto {
  id: number
  formSheetId: number
  formDynamicColumnRegionId: number
  excelColStart: number
  filterDefinitionId?: number | null
  displayOrder: number
  maxColumns?: number | null
  createdAt: string
  createdBy: number
}

export interface CreateFormPlaceholderColumnOccurrenceRequest {
  formDynamicColumnRegionId: number
  excelColStart: number
  filterDefinitionId?: number | null
  displayOrder: number
  maxColumns?: number | null
}

export interface UpdateFormPlaceholderColumnOccurrenceRequest extends CreateFormPlaceholderColumnOccurrenceRequest {}

// ─── IndicatorCatalog ───────────────────────────────────────────

export interface IndicatorCatalogDto {
  id: number
  code: string
  name: string
  description?: string | null
  scope: string
  displayOrder: number
  isActive: boolean
  createdAt: string
  createdBy: number
  indicatorCount: number
}

export interface CreateIndicatorCatalogRequest {
  code: string
  name: string
  description?: string | null
  scope?: string
  displayOrder?: number
  isActive?: boolean
}

export interface UpdateIndicatorCatalogRequest {
  name: string
  description?: string | null
  scope?: string
  displayOrder?: number
  isActive?: boolean
}

// ─── Indicator ──────────────────────────────────────────────────

export interface IndicatorDto {
  id: number
  indicatorCatalogId?: number | null
  parentId?: number | null
  code: string
  name: string
  description?: string | null
  dataType: string
  unit?: string | null
  formulaTemplate?: string | null
  validationRule?: string | null
  defaultValue?: string | null
  displayOrder: number
  isActive: boolean
  createdAt: string
  createdBy: number
  children?: IndicatorDto[] | null
}

export interface CreateIndicatorRequest {
  indicatorCatalogId: number
  parentId?: number | null
  code: string
  name: string
  description?: string | null
  dataType?: string
  unit?: string | null
  formulaTemplate?: string | null
  validationRule?: string | null
  defaultValue?: string | null
  displayOrder?: number
  isActive?: boolean
}

export interface UpdateIndicatorRequest {
  parentId?: number | null
  name: string
  description?: string | null
  dataType?: string
  unit?: string | null
  formulaTemplate?: string | null
  validationRule?: string | null
  defaultValue?: string | null
  displayOrder?: number
  isActive?: boolean
}
