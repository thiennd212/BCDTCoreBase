import { useState, useRef, useEffect } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Breadcrumb,
  Card,
  Table,
  Typography,
  Button,
  Space,
  Modal,
  Form,
  Input,
  InputNumber,
  Select,
  Checkbox,
  message,
  TreeSelect,
} from 'antd'
import { PlusOutlined, UploadOutlined, EditOutlined, DeleteOutlined, FilterOutlined, UnorderedListOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { formsApi } from '../api/formsApi'
import { formWorkflowConfigApi, workflowDefinitionsApi } from '../api/workflowDefinitionsApi'
import type { FormWorkflowConfigDto } from '../types/workflow.types'
import {
  formSheetsApi,
  formColumnsApi,
  formDataBindingApi,
  formColumnMappingApi,
  formDynamicRegionsApi,
  formRowsApi,
} from '../api/formStructureApi'
import { indicatorCatalogsApi, indicatorsApi, indicatorsByCodeApi } from '../api/indicatorCatalogsApi'
import {
  dataSourcesApi,
  filterDefinitionsApi,
  formPlaceholderOccurrencesApi,
  formDynamicColumnRegionsApi,
  formPlaceholderColumnOccurrencesApi,
} from '../api/formDataSourceFilterApi'
import type {
  FormSheetDto,
  CreateFormSheetRequest,
  FormColumnDto,
  FormColumnTreeDto,
  CreateFormColumnRequest,
  CreateFormDataBindingRequest,
  CreateFormColumnMappingRequest,
  FormDynamicRegionDto,
  CreateFormDynamicRegionRequest,
  UpdateFormDynamicRegionRequest,
  FormRowDto,
  FormRowTreeDto,
  CreateFormRowRequest,
  UpdateFormRowRequest,
  DataSourceDto,
  CreateDataSourceRequest,
  UpdateDataSourceRequest,
  FilterDefinitionDto,
  CreateFilterDefinitionRequest,
  UpdateFilterDefinitionRequest,
  CreateFilterConditionItem,
  FormPlaceholderOccurrenceDto,
  CreateFormPlaceholderOccurrenceRequest,
  UpdateFormPlaceholderOccurrenceRequest,
  FormDynamicColumnRegionDto,
  CreateFormDynamicColumnRegionRequest,
  UpdateFormDynamicColumnRegionRequest,
  FormPlaceholderColumnOccurrenceDto,
  CreateFormPlaceholderColumnOccurrenceRequest,
  UpdateFormPlaceholderColumnOccurrenceRequest,
} from '../types/form.types'
import type { IndicatorCatalogDto, IndicatorDto } from '../types/form.types'
import { buildTree, treeExcludeSelfAndDescendants } from '../utils/treeUtils'
import type { TreeNode } from '../utils/treeUtils'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text } = Typography

const BINDING_TYPES = [
  { value: 'Static', label: 'Tĩnh (Static)' },
  { value: 'Database', label: 'Cơ sở dữ liệu' },
  { value: 'API', label: 'API' },
  { value: 'Formula', label: 'Công thức' },
  { value: 'Reference', label: 'Tham chiếu bảng mã' },
  { value: 'Organization', label: 'Đơn vị' },
  { value: 'System', label: 'Hệ thống' },
]

const DATA_TYPES = [
  { value: 'Text', label: 'Text' },
  { value: 'Number', label: 'Number' },
  { value: 'Date', label: 'Date' },
  { value: 'Formula', label: 'Formula' },
  { value: 'Reference', label: 'Reference' },
  { value: 'Boolean', label: 'Boolean' },
]

const ROW_TYPES = [
  { value: 'Header', label: 'Header' },
  { value: 'Data', label: 'Data' },
  { value: 'Total', label: 'Total' },
  { value: 'Static', label: 'Static' },
]

function columnTreeToTableData(nodes: FormColumnTreeDto[]): (FormColumnTreeDto & { key: number; children?: ReturnType<typeof columnTreeToTableData> })[] {
  return nodes.map((n) => ({
    ...n,
    key: n.id,
    children: n.children?.length ? columnTreeToTableData(n.children) : undefined,
  }))
}

function rowTreeToTableData(nodes: FormRowTreeDto[]): (FormRowTreeDto & { key: number; children?: ReturnType<typeof rowTreeToTableData> })[] {
  return nodes.map((n) => ({
    ...n,
    key: n.id,
    children: n.children?.length ? rowTreeToTableData(n.children) : undefined,
  }))
}

function indicatorToTreeSelectOptions(items: IndicatorDto[]): { value: number; label: string; children?: ReturnType<typeof indicatorToTreeSelectOptions> }[] {
  return items.map((i) => ({
    value: i.id,
    label: `${i.code} - ${i.name}`,
    children: i.children?.length ? indicatorToTreeSelectOptions(i.children) : undefined,
  }))
}

function toTreeSelectOptions<T extends { id: number; children?: T[] }>(
  nodes: TreeNode<T>[],
  titleFn: (n: T) => string
): { value: number; title: string; children?: ReturnType<typeof toTreeSelectOptions<T>> }[] {
  return nodes.map((n) => ({
    value: n.id,
    title: titleFn(n),
    children: n.children?.length ? toTreeSelectOptions(n.children, titleFn) : undefined,
  }))
}

export function FormConfigPage() {
  const { formId } = useParams<{ formId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const id = formId ? parseInt(formId, 10) : NaN
  const [selectedSheetId, setSelectedSheetId] = useState<number | null>(null)
  const [selectedColumnId, setSelectedColumnId] = useState<number | null>(null)

  const [sheetModalOpen, setSheetModalOpen] = useState(false)
  const [editingSheetId, setEditingSheetId] = useState<number | null>(null)
  const [columnModalOpen, setColumnModalOpen] = useState(false)
  const [editingColumnId, setEditingColumnId] = useState<number | null>(null)
  const [columnCreateMode, setColumnCreateMode] = useState<'from-catalog' | 'manual'>('from-catalog')
  const [selectedCatalogIdForColumn, setSelectedCatalogIdForColumn] = useState<number | null>(null)
  const [selectedIndicatorIdForColumn, setSelectedIndicatorIdForColumn] = useState<number | null>(null)

  const [sheetForm] = Form.useForm<CreateFormSheetRequest>()
  const [columnForm] = Form.useForm<CreateFormColumnRequest>()
  const [bindingForm] = Form.useForm<CreateFormDataBindingRequest>()
  const [mappingForm] = Form.useForm<CreateFormColumnMappingRequest>()

  const [regionModalOpen, setRegionModalOpen] = useState(false)
  const [editingRegionId, setEditingRegionId] = useState<number | null>(null)
  const [regionForm] = Form.useForm<CreateFormDynamicRegionRequest & { excelRowEnd?: number | null; displayOrder?: number }>()

  const [rowModalOpen, setRowModalOpen] = useState(false)
  const [editingRowId, setEditingRowId] = useState<number | null>(null)
  const [rowForm] = Form.useForm<CreateFormRowRequest>()

  const [dataSourceModalOpen, setDataSourceModalOpen] = useState(false)
  const [editingDataSourceId, setEditingDataSourceId] = useState<number | null>(null)
  const [dataSourceForm] = Form.useForm<CreateDataSourceRequest & { id?: number }>()

  const [filterModalOpen, setFilterModalOpen] = useState(false)
  const [editingFilterId, setEditingFilterId] = useState<number | null>(null)
  const [filterForm] = Form.useForm<CreateFilterDefinitionRequest & { id?: number }>()
  const [filterConditions, setFilterConditions] = useState<(CreateFilterConditionItem & { id?: number })[]>([])

  const [occurrenceModalOpen, setOccurrenceModalOpen] = useState(false)
  const [editingOccurrenceId, setEditingOccurrenceId] = useState<number | null>(null)
  const [occurrenceForm] = Form.useForm<CreateFormPlaceholderOccurrenceRequest>()

  const [columnRegionModalOpen, setColumnRegionModalOpen] = useState(false)
  const [editingColumnRegionId, setEditingColumnRegionId] = useState<number | null>(null)
  const [columnRegionForm] = Form.useForm<CreateFormDynamicColumnRegionRequest & { id?: number }>()
  const [columnOccurrenceModalOpen, setColumnOccurrenceModalOpen] = useState(false)
  const [editingColumnOccurrenceId, setEditingColumnOccurrenceId] = useState<number | null>(null)
  const [columnOccurrenceForm] = Form.useForm<CreateFormPlaceholderColumnOccurrenceRequest>()

  const formContainerRef = useRef<HTMLDivElement>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  // Phase 2b: chỉ tiêu đặc biệt cho "Tạo cột mới" (API bắt buộc indicatorId)
  const { data: specialIndicator } = useQuery({
    queryKey: ['indicators', 'by-code', '_SPECIAL_GENERIC'],
    queryFn: () => indicatorsByCodeApi.getByCode('_SPECIAL_GENERIC'),
    staleTime: 5 * 60 * 1000,
  })
  const specialIndicatorId = specialIndicator?.id ?? null

  useFocusFirstInModal(
    sheetModalOpen || columnModalOpen || regionModalOpen || rowModalOpen ||
    dataSourceModalOpen || filterModalOpen || occurrenceModalOpen ||
    columnRegionModalOpen || columnOccurrenceModalOpen,
    formContainerRef
  )
  useScrollPageTopWhenModalOpen(
    sheetModalOpen || columnModalOpen || regionModalOpen || rowModalOpen ||
    dataSourceModalOpen || filterModalOpen || occurrenceModalOpen ||
    columnRegionModalOpen || columnOccurrenceModalOpen
  )

  const { data: form, isLoading: formLoading } = useQuery({
    queryKey: ['form', id],
    queryFn: () => formsApi.getById(id),
    enabled: Number.isInteger(id),
  })

  const { data: sheets = [], isLoading: sheetsLoading } = useQuery({
    queryKey: ['forms', id, 'sheets'],
    queryFn: () => formSheetsApi.getList(id),
    enabled: Number.isInteger(id),
  })

  const { data: columns = [], isLoading: columnsLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns'],
    queryFn: () => formColumnsApi.getList(id, selectedSheetId!) as Promise<FormColumnDto[]>,
    enabled: Number.isInteger(id) && selectedSheetId != null,
  })

  const { data: indicatorCatalogs = [] } = useQuery({
    queryKey: ['indicator-catalogs'],
    queryFn: () => indicatorCatalogsApi.getList(),
    enabled: columnModalOpen && editingColumnId == null && columnCreateMode === 'from-catalog',
  })

  const { data: indicatorsForColumn = [] } = useQuery({
    queryKey: ['indicators', selectedCatalogIdForColumn],
    queryFn: () => indicatorsApi.getList(selectedCatalogIdForColumn!, true),
    enabled: columnModalOpen && selectedCatalogIdForColumn != null,
  })

  const { data: columnsTree = [], isLoading: columnsTreeLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns', 'tree'],
    queryFn: () => formColumnsApi.getListTree(id, selectedSheetId!),
    enabled: Number.isInteger(id) && selectedSheetId != null,
  })

  const { data: rows = [] } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'rows'],
    queryFn: () => formRowsApi.getList(id, selectedSheetId!),
    enabled: Number.isInteger(id) && selectedSheetId != null,
  })

  const { data: rowsTree = [], isLoading: rowsTreeLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'rows', 'tree'],
    queryFn: () => formRowsApi.getListTree(id, selectedSheetId!),
    enabled: Number.isInteger(id) && selectedSheetId != null,
  })

  const { data: dataBinding, isLoading: bindingLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns', selectedColumnId, 'data-binding'],
    queryFn: () =>
      formDataBindingApi.get(id, selectedSheetId!, selectedColumnId!),
    enabled:
      Number.isInteger(id) &&
      selectedSheetId != null &&
      selectedColumnId != null,
  })

  const { data: columnMapping, isLoading: mappingLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns', selectedColumnId, 'column-mapping'],
    queryFn: () =>
      formColumnMappingApi.get(id, selectedSheetId!, selectedColumnId!),
    enabled:
      Number.isInteger(id) &&
      selectedSheetId != null &&
      selectedColumnId != null,
  })

  const { data: dynamicRegions = [], isLoading: regionsLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'dynamic-regions'],
    queryFn: () => formDynamicRegionsApi.getList(id, selectedSheetId!),
    enabled: Number.isInteger(id) && selectedSheetId != null,
  })

  const { data: dataSources = [] } = useQuery({
    queryKey: ['data-sources'],
    queryFn: () => dataSourcesApi.getList(),
    enabled: Number.isInteger(id),
  })

  const { data: filterDefinitions = [] } = useQuery({
    queryKey: ['filter-definitions'],
    queryFn: () => filterDefinitionsApi.getList(),
    enabled: Number.isInteger(id),
  })

  const { data: placeholderOccurrences = [], isLoading: occurrencesLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-occurrences'],
    queryFn: () => formPlaceholderOccurrencesApi.getList(id, selectedSheetId!),
    enabled: Number.isInteger(id) && selectedSheetId != null,
  })

  const { data: dynamicColumnRegions = [], isLoading: columnRegionsLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'dynamic-column-regions'],
    queryFn: () => formDynamicColumnRegionsApi.getList(id, selectedSheetId!),
    enabled: Number.isInteger(id) && selectedSheetId != null,
  })

  const { data: placeholderColumnOccurrences = [], isLoading: columnOccurrencesLoading } = useQuery({
    queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-column-occurrences'],
    queryFn: () => formPlaceholderColumnOccurrencesApi.getList(id, selectedSheetId!),
    enabled: Number.isInteger(id) && selectedSheetId != null,
  })

  /* ---- FormWorkflowConfig ---- */
  const { data: workflowConfigs = [] } = useQuery({
    queryKey: ['forms', id, 'workflow-config'],
    queryFn: () => formWorkflowConfigApi.getByFormId(id),
    enabled: Number.isInteger(id),
  })

  const { data: allWorkflowDefs = [] } = useQuery({
    queryKey: ['workflow-definitions-for-config'],
    queryFn: () => workflowDefinitionsApi.getList({ includeInactive: false }),
  })

  const createWfConfigMut = useMutation({
    mutationFn: (body: { formDefinitionId: number; workflowDefinitionId: number; isActive: boolean }) =>
      formWorkflowConfigApi.create(id, body),
    onSuccess: () => {
      message.success('Gắn quy trình thành công')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'workflow-config'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Gắn quy trình thất bại'),
  })

  const deleteWfConfigMut = useMutation({
    mutationFn: (configId: number) => formWorkflowConfigApi.delete(id, configId),
    onSuccess: () => {
      message.success('Đã gỡ quy trình')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'workflow-config'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Gỡ quy trình thất bại'),
  })

  useEffect(() => {
    if (selectedColumnId == null) return
    if (dataBinding) {
      bindingForm.setFieldsValue({
        bindingType: dataBinding.bindingType,
        sourceTable: dataBinding.sourceTable ?? '',
        sourceColumn: dataBinding.sourceColumn ?? '',
        sourceCondition: dataBinding.sourceCondition ?? '',
        apiEndpoint: dataBinding.apiEndpoint ?? '',
        apiMethod: dataBinding.apiMethod ?? 'GET',
        apiResponsePath: dataBinding.apiResponsePath ?? '',
        formula: dataBinding.formula ?? '',
        referenceEntityTypeId: dataBinding.referenceEntityTypeId ?? undefined,
        referenceDisplayColumn: dataBinding.referenceDisplayColumn ?? '',
        defaultValue: dataBinding.defaultValue ?? '',
        transformExpression: dataBinding.transformExpression ?? '',
        cacheMinutes: dataBinding.cacheMinutes ?? 0,
        isActive: dataBinding.isActive,
      })
    } else if (!bindingLoading) {
      bindingForm.setFieldsValue({
        bindingType: 'Static',
        sourceTable: '',
        sourceColumn: '',
        sourceCondition: '',
        apiEndpoint: '',
        apiMethod: 'GET',
        apiResponsePath: '',
        formula: '',
        defaultValue: '',
        cacheMinutes: 0,
        isActive: true,
      })
    }
  }, [dataBinding, selectedColumnId, bindingLoading, bindingForm])

  useEffect(() => {
    if (selectedColumnId == null) return
    if (columnMapping) {
      mappingForm.setFieldsValue({
        targetColumnName: columnMapping.targetColumnName,
        targetColumnIndex: columnMapping.targetColumnIndex,
        aggregateFunction: columnMapping.aggregateFunction ?? '',
      })
    } else if (!mappingLoading) {
      mappingForm.setFieldsValue({
        targetColumnName: '',
        targetColumnIndex: 0,
        aggregateFunction: '',
      })
    }
  }, [columnMapping, selectedColumnId, mappingLoading, mappingForm])

  const createSheetMutation = useMutation({
    mutationFn: (body: CreateFormSheetRequest) => formSheetsApi.create(id, body),
    onSuccess: () => {
      message.success('Đã thêm sheet')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets'] })
      setSheetModalOpen(false)
      sheetForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateSheetMutation = useMutation({
    mutationFn: ({ sheetId, body }: { sheetId: number; body: CreateFormSheetRequest }) =>
      formSheetsApi.update(id, sheetId, body),
    onSuccess: () => {
      message.success('Đã cập nhật sheet')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets'] })
      setSheetModalOpen(false)
      setEditingSheetId(null)
      sheetForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteSheetMutation = useMutation({
    mutationFn: (sheetId: number) => formSheetsApi.delete(id, sheetId),
    onSuccess: () => {
      message.success('Đã xóa sheet')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets'] })
      if (selectedSheetId) setSelectedSheetId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const createColumnMutation = useMutation({
    mutationFn: (body: CreateFormColumnRequest) =>
      formColumnsApi.create(id, selectedSheetId!, body),
    onSuccess: () => {
      message.success('Đã thêm cột')
      queryClient.invalidateQueries({
        queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns'],
      })
      setColumnModalOpen(false)
      setColumnCreateMode('from-catalog')
      setSelectedCatalogIdForColumn(null)
      setSelectedIndicatorIdForColumn(null)
      columnForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const handleCreateColumnFromIndicator = () => {
    if (selectedIndicatorIdForColumn == null) {
      message.warning('Vui lòng chọn một chỉ tiêu từ danh mục.')
      return
    }
    const flatColumns = columns as FormColumnDto[]
    createColumnMutation.mutate({
      indicatorId: selectedIndicatorIdForColumn,
      parentId: undefined,
      columnCode: '',
      columnName: '',
      excelColumn: 'A',
      dataType: 'Text',
      isRequired: false,
      isEditable: true,
      isHidden: false,
      displayOrder: flatColumns.length,
    })
  }

  const updateColumnMutation = useMutation({
    mutationFn: ({
      columnId,
      body,
    }: { columnId: number; body: CreateFormColumnRequest }) =>
      formColumnsApi.update(id, selectedSheetId!, columnId, body),
    onSuccess: () => {
      message.success('Đã cập nhật cột')
      queryClient.invalidateQueries({
        queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns'],
      })
      setColumnModalOpen(false)
      setEditingColumnId(null)
      columnForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteColumnMutation = useMutation({
    mutationFn: (columnId: number) =>
      formColumnsApi.delete(id, selectedSheetId!, columnId),
    onSuccess: () => {
      message.success('Đã xóa cột')
      queryClient.invalidateQueries({
        queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns'],
      })
      setSelectedColumnId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const saveBindingMutation = useMutation({
    mutationFn: async (body: CreateFormDataBindingRequest) => {
      if (dataBinding)
        return formDataBindingApi.update(id, selectedSheetId!, selectedColumnId!, body)
      return formDataBindingApi.create(id, selectedSheetId!, selectedColumnId!, body)
    },
    onSuccess: () => {
      message.success('Đã lưu bộ lọc dữ liệu')
      queryClient.invalidateQueries({
        queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns', selectedColumnId, 'data-binding'],
      })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const saveMappingMutation = useMutation({
    mutationFn: async (body: CreateFormColumnMappingRequest) => {
      if (columnMapping)
        return formColumnMappingApi.update(id, selectedSheetId!, selectedColumnId!, body)
      return formColumnMappingApi.create(id, selectedSheetId!, selectedColumnId!, body)
    },
    onSuccess: () => {
      message.success('Đã lưu ánh xạ cột')
      queryClient.invalidateQueries({
        queryKey: ['forms', id, 'sheets', selectedSheetId, 'columns', selectedColumnId, 'column-mapping'],
      })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const createRegionMutation = useMutation({
    mutationFn: (body: CreateFormDynamicRegionRequest) =>
      formDynamicRegionsApi.create(id, selectedSheetId!, body),
    onSuccess: () => {
      message.success('Đã thêm vùng chỉ tiêu động')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'dynamic-regions'] })
      setRegionModalOpen(false)
      regionForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateRegionMutation = useMutation({
    mutationFn: ({ regionId, body }: { regionId: number; body: UpdateFormDynamicRegionRequest }) =>
      formDynamicRegionsApi.update(id, selectedSheetId!, regionId, body),
    onSuccess: () => {
      message.success('Đã cập nhật vùng chỉ tiêu động')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'dynamic-regions'] })
      setRegionModalOpen(false)
      setEditingRegionId(null)
      regionForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteRegionMutation = useMutation({
    mutationFn: (regionId: number) =>
      formDynamicRegionsApi.delete(id, selectedSheetId!, regionId),
    onSuccess: () => {
      message.success('Đã xóa vùng chỉ tiêu động')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'dynamic-regions'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const createRowMutation = useMutation({
    mutationFn: (body: CreateFormRowRequest) =>
      formRowsApi.create(id, selectedSheetId!, body),
    onSuccess: () => {
      message.success('Đã thêm hàng')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'rows'] })
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'rows', 'tree'] })
      setRowModalOpen(false)
      rowForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateRowMutation = useMutation({
    mutationFn: ({ rowId, body }: { rowId: number; body: UpdateFormRowRequest }) =>
      formRowsApi.update(id, selectedSheetId!, rowId, body),
    onSuccess: () => {
      message.success('Đã cập nhật hàng')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'rows'] })
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'rows', 'tree'] })
      setRowModalOpen(false)
      setEditingRowId(null)
      rowForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteRowMutation = useMutation({
    mutationFn: (rowId: number) =>
      formRowsApi.delete(id, selectedSheetId!, rowId),
    onSuccess: () => {
      message.success('Đã xóa hàng')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'rows'] })
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'rows', 'tree'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const createDataSourceMutation = useMutation({
    mutationFn: (body: CreateDataSourceRequest) => dataSourcesApi.create(body),
    onSuccess: () => {
      message.success('Đã thêm nguồn dữ liệu')
      queryClient.invalidateQueries({ queryKey: ['data-sources'] })
      setDataSourceModalOpen(false)
      dataSourceForm.resetFields()
      setEditingDataSourceId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateDataSourceMutation = useMutation({
    mutationFn: ({ id: dsId, body }: { id: number; body: UpdateDataSourceRequest }) =>
      dataSourcesApi.update(dsId, body),
    onSuccess: () => {
      message.success('Đã cập nhật nguồn dữ liệu')
      queryClient.invalidateQueries({ queryKey: ['data-sources'] })
      setDataSourceModalOpen(false)
      setEditingDataSourceId(null)
      dataSourceForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteDataSourceMutation = useMutation({
    mutationFn: (dsId: number) => dataSourcesApi.delete(dsId),
    onSuccess: () => {
      message.success('Đã xóa nguồn dữ liệu')
      queryClient.invalidateQueries({ queryKey: ['data-sources'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const createFilterMutation = useMutation({
    mutationFn: (body: CreateFilterDefinitionRequest) => filterDefinitionsApi.create(body),
    onSuccess: () => {
      message.success('Đã thêm bộ lọc')
      queryClient.invalidateQueries({ queryKey: ['filter-definitions'] })
      setFilterModalOpen(false)
      filterForm.resetFields()
      setFilterConditions([])
      setEditingFilterId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateFilterMutation = useMutation({
    mutationFn: ({ id: filterId, body }: { id: number; body: UpdateFilterDefinitionRequest }) =>
      filterDefinitionsApi.update(filterId, body),
    onSuccess: () => {
      message.success('Đã cập nhật bộ lọc')
      queryClient.invalidateQueries({ queryKey: ['filter-definitions'] })
      setFilterModalOpen(false)
      setEditingFilterId(null)
      filterForm.resetFields()
      setFilterConditions([])
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteFilterMutation = useMutation({
    mutationFn: (filterId: number) => filterDefinitionsApi.delete(filterId),
    onSuccess: () => {
      message.success('Đã xóa bộ lọc')
      queryClient.invalidateQueries({ queryKey: ['filter-definitions'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const createOccurrenceMutation = useMutation({
    mutationFn: (body: CreateFormPlaceholderOccurrenceRequest) =>
      formPlaceholderOccurrencesApi.create(id, selectedSheetId!, body),
    onSuccess: () => {
      message.success('Đã thêm vị trí placeholder')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-occurrences'] })
      setOccurrenceModalOpen(false)
      occurrenceForm.resetFields()
      setEditingOccurrenceId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateOccurrenceMutation = useMutation({
    mutationFn: ({
      occurrenceId,
      body,
    }: { occurrenceId: number; body: UpdateFormPlaceholderOccurrenceRequest }) =>
      formPlaceholderOccurrencesApi.update(id, selectedSheetId!, occurrenceId, body),
    onSuccess: () => {
      message.success('Đã cập nhật vị trí placeholder')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-occurrences'] })
      setOccurrenceModalOpen(false)
      setEditingOccurrenceId(null)
      occurrenceForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteOccurrenceMutation = useMutation({
    mutationFn: (occurrenceId: number) =>
      formPlaceholderOccurrencesApi.delete(id, selectedSheetId!, occurrenceId),
    onSuccess: () => {
      message.success('Đã xóa vị trí placeholder')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-occurrences'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const createColumnRegionMutation = useMutation({
    mutationFn: (body: CreateFormDynamicColumnRegionRequest) =>
      formDynamicColumnRegionsApi.create(id, selectedSheetId!, body),
    onSuccess: () => {
      message.success('Đã thêm vùng cột động')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'dynamic-column-regions'] })
      setColumnRegionModalOpen(false)
      columnRegionForm.resetFields()
      setEditingColumnRegionId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateColumnRegionMutation = useMutation({
    mutationFn: ({ regionId, body }: { regionId: number; body: UpdateFormDynamicColumnRegionRequest }) =>
      formDynamicColumnRegionsApi.update(id, selectedSheetId!, regionId, body),
    onSuccess: () => {
      message.success('Đã cập nhật vùng cột động')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'dynamic-column-regions'] })
      setColumnRegionModalOpen(false)
      setEditingColumnRegionId(null)
      columnRegionForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteColumnRegionMutation = useMutation({
    mutationFn: (regionId: number) =>
      formDynamicColumnRegionsApi.delete(id, selectedSheetId!, regionId),
    onSuccess: () => {
      message.success('Đã xóa vùng cột động')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'dynamic-column-regions'] })
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-column-occurrences'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const createColumnOccurrenceMutation = useMutation({
    mutationFn: (body: CreateFormPlaceholderColumnOccurrenceRequest) =>
      formPlaceholderColumnOccurrencesApi.create(id, selectedSheetId!, body),
    onSuccess: () => {
      message.success('Đã thêm vị trí placeholder cột')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-column-occurrences'] })
      setColumnOccurrenceModalOpen(false)
      columnOccurrenceForm.resetFields()
      setEditingColumnOccurrenceId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateColumnOccurrenceMutation = useMutation({
    mutationFn: ({
      occurrenceId,
      body,
    }: { occurrenceId: number; body: UpdateFormPlaceholderColumnOccurrenceRequest }) =>
      formPlaceholderColumnOccurrencesApi.update(id, selectedSheetId!, occurrenceId, body),
    onSuccess: () => {
      message.success('Đã cập nhật vị trí placeholder cột')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-column-occurrences'] })
      setColumnOccurrenceModalOpen(false)
      setEditingColumnOccurrenceId(null)
      columnOccurrenceForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteColumnOccurrenceMutation = useMutation({
    mutationFn: (occurrenceId: number) =>
      formPlaceholderColumnOccurrencesApi.delete(id, selectedSheetId!, occurrenceId),
    onSuccess: () => {
      message.success('Đã xóa vị trí placeholder cột')
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'sheets', selectedSheetId, 'placeholder-column-occurrences'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const uploadTemplateMutation = useMutation({
    mutationFn: (file: File) => formsApi.uploadTemplate(id, file),
    onSuccess: () => {
      message.success('Đã upload template. Trang nhập liệu sẽ dùng template này làm mẫu.')
      queryClient.invalidateQueries({ queryKey: ['form', id] })
      queryClient.invalidateQueries({ queryKey: ['forms', id] })
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'template-display'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Upload thất bại'),
  })

  useEffect(() => {
    if (!sheetModalOpen) setEditingSheetId(null)
  }, [sheetModalOpen])
  useEffect(() => {
    if (!columnModalOpen) setEditingColumnId(null)
  }, [columnModalOpen])
  useEffect(() => {
    if (!regionModalOpen) setEditingRegionId(null)
  }, [regionModalOpen])
  useEffect(() => {
    if (!rowModalOpen) setEditingRowId(null)
  }, [rowModalOpen])
  useEffect(() => {
    if (!dataSourceModalOpen) setEditingDataSourceId(null)
  }, [dataSourceModalOpen])
  useEffect(() => {
    if (!filterModalOpen) {
      setEditingFilterId(null)
      setFilterConditions([])
    }
  }, [filterModalOpen])
  useEffect(() => {
    if (!occurrenceModalOpen) setEditingOccurrenceId(null)
  }, [occurrenceModalOpen])

  const openCreateRegion = () => {
    regionForm.setFieldsValue({
      excelRowStart: 1,
      excelRowEnd: undefined,
      excelColName: 'A',
      excelColValue: 'B',
      maxRows: 10,
      indicatorExpandDepth: 0,
      indicatorCatalogId: undefined,
      displayOrder: dynamicRegions.length,
    })
    setRegionModalOpen(true)
  }

  const openEditRegion = (record: FormDynamicRegionDto) => {
    setEditingRegionId(record.id)
    regionForm.setFieldsValue({
      excelRowStart: record.excelRowStart,
      excelRowEnd: record.excelRowEnd ?? undefined,
      excelColName: record.excelColName,
      excelColValue: record.excelColValue,
      maxRows: record.maxRows,
      indicatorExpandDepth: record.indicatorExpandDepth,
      indicatorCatalogId: record.indicatorCatalogId ?? undefined,
      displayOrder: record.displayOrder,
    })
    setRegionModalOpen(true)
  }

  const handleRegionSubmit = async () => {
    const values = await regionForm.validateFields()
    const base = {
      excelRowStart: values.excelRowStart,
      excelRowEnd: values.excelRowEnd ?? undefined,
      excelColName: values.excelColName,
      excelColValue: values.excelColValue,
      maxRows: values.maxRows ?? 10,
      indicatorExpandDepth: values.indicatorExpandDepth ?? 0,
      indicatorCatalogId: values.indicatorCatalogId ?? undefined,
      displayOrder: values.displayOrder ?? dynamicRegions.length,
    }
    if (editingRegionId != null) {
      updateRegionMutation.mutate({
        regionId: editingRegionId,
        body: { ...base, maxRows: base.maxRows ?? 10, indicatorExpandDepth: base.indicatorExpandDepth ?? 0, displayOrder: base.displayOrder ?? 0 },
      })
    } else {
      createRegionMutation.mutate(base)
    }
  }

  const openCreateSheet = () => {
    sheetForm.setFieldsValue({
      sheetIndex: sheets.length,
      sheetName: '',
      displayName: '',
      description: '',
      isDataSheet: true,
      isVisible: true,
      displayOrder: sheets.length,
      dataStartRow: undefined,
    })
    setSheetModalOpen(true)
  }

  const openEditSheet = (record: FormSheetDto) => {
    setEditingSheetId(record.id)
    sheetForm.setFieldsValue({
      sheetIndex: record.sheetIndex,
      sheetName: record.sheetName,
      displayName: record.displayName ?? '',
      description: record.description ?? '',
      isDataSheet: record.isDataSheet,
      isVisible: record.isVisible,
      displayOrder: record.displayOrder,
      dataStartRow: record.dataStartRow ?? undefined,
    })
    setSheetModalOpen(true)
  }

  const handleSheetSubmit = async () => {
    const values = await sheetForm.validateFields()
    const body = {
      ...values,
      displayName: values.displayName || undefined,
      description: values.description || undefined,
      dataStartRow: values.dataStartRow ?? undefined,
    }
    if (editingSheetId != null)
      updateSheetMutation.mutate({ sheetId: editingSheetId, body })
    else createSheetMutation.mutate(body)
  }

  const openCreateColumn = () => {
    setColumnCreateMode('from-catalog')
    setSelectedCatalogIdForColumn(null)
    setSelectedIndicatorIdForColumn(null)
    columnForm.setFieldsValue({
      parentId: undefined,
      indicatorId: specialIndicatorId ?? undefined,
      columnCode: '',
      columnName: '',
      columnGroupName: '',
      columnGroupLevel2: '',
      columnGroupLevel3: '',
      columnGroupLevel4: '',
      excelColumn: 'A',
      dataType: 'Text',
      isRequired: false,
      isEditable: true,
      isHidden: false,
      displayOrder: columns.length,
    })
    setColumnModalOpen(true)
  }

  const switchToManualColumnForm = () => {
    setColumnCreateMode('manual')
    columnForm.setFieldsValue({
      parentId: undefined,
      indicatorId: specialIndicatorId ?? undefined,
      columnCode: '',
      columnName: '',
      columnGroupName: '',
      columnGroupLevel2: '',
      columnGroupLevel3: '',
      columnGroupLevel4: '',
      excelColumn: 'A',
      dataType: 'Text',
      isRequired: false,
      isEditable: true,
      isHidden: false,
      displayOrder: columns.length,
    })
  }

  const switchToFromCatalogColumnForm = () => {
    setColumnCreateMode('from-catalog')
    setSelectedIndicatorIdForColumn(null)
  }

  const openEditColumn = (record: FormColumnDto) => {
    setEditingColumnId(record.id)
    columnForm.setFieldsValue({
      parentId: record.parentId ?? undefined,
      indicatorId: record.indicatorId,
      columnCode: record.columnCode,
      columnName: record.columnName,
      columnGroupName: record.columnGroupName ?? '',
      columnGroupLevel2: record.columnGroupLevel2 ?? '',
      columnGroupLevel3: record.columnGroupLevel3 ?? '',
      columnGroupLevel4: record.columnGroupLevel4 ?? '',
      excelColumn: record.excelColumn,
      dataType: record.dataType,
      isRequired: record.isRequired,
      isEditable: record.isEditable,
      isHidden: record.isHidden,
      defaultValue: record.defaultValue ?? '',
      formula: record.formula ?? '',
      validationRule: record.validationRule ?? '',
      validationMessage: record.validationMessage ?? '',
      displayOrder: record.displayOrder,
      width: record.width ?? undefined,
      format: record.format ?? '',
    })
    setColumnModalOpen(true)
  }

  const openCreateRow = () => {
    rowForm.setFieldsValue({
      rowCode: '',
      rowName: '',
      excelRowStart: 1,
      excelRowEnd: undefined,
      rowType: 'Data',
      isRepeating: false,
      displayOrder: rows.length,
      parentId: undefined,
      formDynamicRegionId: undefined,
    })
    setRowModalOpen(true)
  }

  const openEditRow = (record: FormRowDto) => {
    setEditingRowId(record.id)
    rowForm.setFieldsValue({
      rowCode: record.rowCode ?? '',
      rowName: record.rowName ?? '',
      excelRowStart: record.excelRowStart,
      excelRowEnd: record.excelRowEnd ?? undefined,
      rowType: record.rowType,
      isRepeating: record.isRepeating,
      displayOrder: record.displayOrder,
      parentId: record.parentId ?? undefined,
      formDynamicRegionId: record.formDynamicRegionId ?? undefined,
      height: record.height ?? undefined,
    })
    setRowModalOpen(true)
  }

  const handleRowSubmit = async () => {
    const values = await rowForm.validateFields()
    const body: CreateFormRowRequest = {
      rowCode: values.rowCode || undefined,
      rowName: values.rowName || undefined,
      excelRowStart: values.excelRowStart,
      excelRowEnd: values.excelRowEnd ?? undefined,
      rowType: values.rowType ?? 'Data',
      isRepeating: values.isRepeating ?? false,
      displayOrder: values.displayOrder ?? 0,
      parentId: values.parentId ?? undefined,
      formDynamicRegionId: values.formDynamicRegionId ?? undefined,
      height: values.height ?? undefined,
    }
    if (editingRowId != null) {
      updateRowMutation.mutate({ rowId: editingRowId, body })
    } else {
      createRowMutation.mutate(body)
    }
  }

  const handleColumnSubmit = async () => {
    const values = await columnForm.validateFields()
    const body: CreateFormColumnRequest = {
      ...values,
      parentId: values.parentId ?? undefined,
      columnGroupName: values.columnGroupName || undefined,
      columnGroupLevel2: values.columnGroupLevel2 || undefined,
      columnGroupLevel3: values.columnGroupLevel3 || undefined,
      columnGroupLevel4: values.columnGroupLevel4 || undefined,
      defaultValue: values.defaultValue || undefined,
      formula: values.formula || undefined,
      validationRule: values.validationRule || undefined,
      validationMessage: values.validationMessage || undefined,
      format: values.format || undefined,
    }
    // Phase 2b: API bắt buộc indicatorId
    if (editingColumnId != null) {
      body.indicatorId = values.indicatorId ?? (columns as FormColumnDto[]).find(c => c.id === editingColumnId)?.indicatorId ?? 0
    } else {
      body.indicatorId = values.indicatorId ?? specialIndicatorId ?? null
    }
    if (body.indicatorId == null || body.indicatorId === 0) {
      message.warning('Vui lòng chọn chỉ tiêu từ danh mục hoặc đợi tải chỉ tiêu đặc biệt (Tạo cột mới).')
      return
    }
    if (editingColumnId != null)
      updateColumnMutation.mutate({ columnId: editingColumnId, body })
    else createColumnMutation.mutate(body)
  }

  const handleBindingSubmit = async () => {
    const values = await bindingForm.validateFields().catch(() => null)
    if (!values) return
    saveBindingMutation.mutate({
      ...values,
      sourceTable: values.sourceTable || undefined,
      sourceColumn: values.sourceColumn || undefined,
      sourceCondition: values.sourceCondition || undefined,
      apiEndpoint: values.apiEndpoint || undefined,
      formula: values.formula || undefined,
      defaultValue: values.defaultValue || undefined,
      transformExpression: values.transformExpression || undefined,
    })
  }

  const handleMappingSubmit = async () => {
    const values = await mappingForm.validateFields()
    saveMappingMutation.mutate({
      targetColumnName: values.targetColumnName,
      targetColumnIndex: values.targetColumnIndex ?? 0,
      aggregateFunction: values.aggregateFunction || undefined,
    })
  }

  const openCreateDataSource = () => {
    dataSourceForm.setFieldsValue({
      code: '',
      name: '',
      sourceType: 'Table',
      sourceRef: '',
      indicatorCatalogId: undefined,
      displayColumn: '',
      valueColumn: '',
      isActive: true,
    })
    setDataSourceModalOpen(true)
  }

  const openEditDataSource = (record: DataSourceDto) => {
    setEditingDataSourceId(record.id)
    dataSourceForm.setFieldsValue({
      code: record.code,
      name: record.name,
      sourceType: record.sourceType,
      sourceRef: record.sourceRef ?? '',
      indicatorCatalogId: record.indicatorCatalogId ?? undefined,
      displayColumn: record.displayColumn ?? '',
      valueColumn: record.valueColumn ?? '',
      isActive: record.isActive,
    })
    setDataSourceModalOpen(true)
  }

  const handleDataSourceSubmit = async () => {
    const values = await dataSourceForm.validateFields()
    if (editingDataSourceId != null) {
      updateDataSourceMutation.mutate({
        id: editingDataSourceId,
        body: {
          name: values.name,
          sourceType: values.sourceType ?? 'Table',
          sourceRef: values.sourceRef || undefined,
          indicatorCatalogId: values.indicatorCatalogId ?? undefined,
          displayColumn: values.displayColumn || undefined,
          valueColumn: values.valueColumn || undefined,
          isActive: values.isActive ?? true,
        },
      })
    } else {
      createDataSourceMutation.mutate({
        code: values.code,
        name: values.name,
        sourceType: values.sourceType ?? 'Table',
        sourceRef: values.sourceRef || undefined,
        indicatorCatalogId: values.indicatorCatalogId ?? undefined,
        displayColumn: values.displayColumn || undefined,
        valueColumn: values.valueColumn || undefined,
        isActive: values.isActive ?? true,
      })
    }
  }

  const openCreateFilter = () => {
    filterForm.setFieldsValue({
      code: '',
      name: '',
      logicalOperator: 'AND',
      dataSourceId: undefined,
    })
    setFilterConditions([])
    setFilterModalOpen(true)
  }

  const openEditFilter = (record: FilterDefinitionDto) => {
    setEditingFilterId(record.id)
    filterForm.setFieldsValue({
      code: record.code,
      name: record.name,
      logicalOperator: record.logicalOperator,
      dataSourceId: record.dataSourceId ?? undefined,
    })
    setFilterConditions(
      (record.conditions ?? []).map((c) => ({
        id: c.id,
        conditionOrder: c.conditionOrder,
        field: c.field,
        operator: c.operator,
        valueType: c.valueType ?? 'Literal',
        value: c.value ?? '',
        value2: c.value2 ?? '',
        dataType: c.dataType ?? undefined,
      }))
    )
    setFilterModalOpen(true)
  }

  const handleFilterSubmit = async () => {
    const values = await filterForm.validateFields()
    if (editingFilterId != null) {
      const conditions: UpdateFilterDefinitionRequest['conditions'] = filterConditions.map((c, i) => ({
        id: c.id ?? 0,
        conditionOrder: c.conditionOrder ?? i,
        field: c.field,
        operator: c.operator,
        valueType: c.valueType ?? 'Literal',
        value: c.value || undefined,
        value2: c.value2 || undefined,
        dataType: c.dataType ?? undefined,
      }))
      updateFilterMutation.mutate({
        id: editingFilterId,
        body: {
          name: values.name,
          logicalOperator: values.logicalOperator ?? 'AND',
          dataSourceId: values.dataSourceId ?? undefined,
          conditions,
        },
      })
    } else {
      createFilterMutation.mutate({
        code: values.code,
        name: values.name,
        logicalOperator: values.logicalOperator ?? 'AND',
        dataSourceId: values.dataSourceId ?? undefined,
        conditions: filterConditions.map((c, i) => ({
          conditionOrder: c.conditionOrder ?? i,
          field: c.field,
          operator: c.operator,
          valueType: c.valueType ?? 'Literal',
          value: c.value || undefined,
          value2: c.value2 || undefined,
          dataType: c.dataType ?? undefined,
        })),
      })
    }
  }

  const openCreateOccurrence = () => {
    occurrenceForm.setFieldsValue({
      formDynamicRegionId: undefined,
      excelRowStart: 1,
      filterDefinitionId: undefined,
      dataSourceId: undefined,
      displayOrder: placeholderOccurrences.length,
      maxRows: undefined,
    })
    setOccurrenceModalOpen(true)
  }

  const openEditOccurrence = (record: FormPlaceholderOccurrenceDto) => {
    setEditingOccurrenceId(record.id)
    occurrenceForm.setFieldsValue({
      formDynamicRegionId: record.formDynamicRegionId,
      excelRowStart: record.excelRowStart,
      filterDefinitionId: record.filterDefinitionId ?? undefined,
      dataSourceId: record.dataSourceId ?? undefined,
      displayOrder: record.displayOrder,
      maxRows: record.maxRows ?? undefined,
    })
    setOccurrenceModalOpen(true)
  }

  const handleOccurrenceSubmit = async () => {
    const values = await occurrenceForm.validateFields()
    const body: CreateFormPlaceholderOccurrenceRequest = {
      formDynamicRegionId: values.formDynamicRegionId,
      excelRowStart: values.excelRowStart,
      filterDefinitionId: values.filterDefinitionId ?? undefined,
      dataSourceId: values.dataSourceId ?? undefined,
      displayOrder: values.displayOrder ?? 0,
      maxRows: values.maxRows ?? undefined,
    }
    if (editingOccurrenceId != null) {
      updateOccurrenceMutation.mutate({ occurrenceId: editingOccurrenceId, body })
    } else {
      createOccurrenceMutation.mutate(body)
    }
  }

  const COLUMN_SOURCE_TYPES = [
    { value: 'ByReportingPeriod', label: 'Theo kỳ báo cáo' },
    { value: 'ByCatalog', label: 'Theo danh mục' },
    { value: 'ByDataSource', label: 'Theo nguồn dữ liệu' },
    { value: 'Fixed', label: 'Cố định (danh sách)' },
  ]

  const openCreateColumnRegion = () => {
    columnRegionForm.setFieldsValue({
      code: '',
      name: '',
      columnSourceType: 'ByReportingPeriod',
      columnSourceRef: undefined,
      labelColumn: undefined,
      displayOrder: dynamicColumnRegions.length,
      isActive: true,
    })
    setColumnRegionModalOpen(true)
  }

  const openEditColumnRegion = (record: FormDynamicColumnRegionDto) => {
    setEditingColumnRegionId(record.id)
    columnRegionForm.setFieldsValue({
      code: record.code,
      name: record.name,
      columnSourceType: record.columnSourceType,
      columnSourceRef: record.columnSourceRef ?? undefined,
      labelColumn: record.labelColumn ?? undefined,
      displayOrder: record.displayOrder,
      isActive: record.isActive,
    })
    setColumnRegionModalOpen(true)
  }

  const handleColumnRegionSubmit = async () => {
    const values = await columnRegionForm.validateFields()
    const body: CreateFormDynamicColumnRegionRequest = {
      code: values.code?.trim() ?? '',
      name: values.name?.trim() ?? '',
      columnSourceType: values.columnSourceType ?? 'ByReportingPeriod',
      columnSourceRef: values.columnSourceRef?.trim() || undefined,
      labelColumn: values.labelColumn?.trim() || undefined,
      displayOrder: values.displayOrder ?? 0,
      isActive: values.isActive ?? true,
    }
    if (editingColumnRegionId != null) {
      updateColumnRegionMutation.mutate({ regionId: editingColumnRegionId, body })
    } else {
      createColumnRegionMutation.mutate(body)
    }
  }

  const openCreateColumnOccurrence = () => {
    columnOccurrenceForm.setFieldsValue({
      formDynamicColumnRegionId: undefined,
      excelColStart: 1,
      filterDefinitionId: undefined,
      displayOrder: placeholderColumnOccurrences.length,
      maxColumns: undefined,
    })
    setColumnOccurrenceModalOpen(true)
  }

  const openEditColumnOccurrence = (record: FormPlaceholderColumnOccurrenceDto) => {
    setEditingColumnOccurrenceId(record.id)
    columnOccurrenceForm.setFieldsValue({
      formDynamicColumnRegionId: record.formDynamicColumnRegionId,
      excelColStart: record.excelColStart,
      filterDefinitionId: record.filterDefinitionId ?? undefined,
      displayOrder: record.displayOrder,
      maxColumns: record.maxColumns ?? undefined,
    })
    setColumnOccurrenceModalOpen(true)
  }

  const handleColumnOccurrenceSubmit = async () => {
    const values = await columnOccurrenceForm.validateFields()
    const body: CreateFormPlaceholderColumnOccurrenceRequest = {
      formDynamicColumnRegionId: values.formDynamicColumnRegionId,
      excelColStart: values.excelColStart,
      filterDefinitionId: values.filterDefinitionId ?? undefined,
      displayOrder: values.displayOrder ?? 0,
      maxColumns: values.maxColumns ?? undefined,
    }
    if (editingColumnOccurrenceId != null) {
      updateColumnOccurrenceMutation.mutate({ occurrenceId: editingColumnOccurrenceId, body })
    } else {
      createColumnOccurrenceMutation.mutate(body)
    }
  }

  if (!Number.isInteger(id) || formLoading) {
    return (
      <Card>
        <Text type="secondary">Đang tải...</Text>
      </Card>
    )
  }
  if (!form) {
    return (
      <Card>
        <Text type="danger">Không tìm thấy biểu mẫu.</Text>
        <Button type="link" onClick={() => navigate('/forms')}>
          Quay lại danh sách
        </Button>
      </Card>
    )
  }

  const sheetColumns = [
    { title: 'STT', dataIndex: 'sheetIndex', key: 'sheetIndex', width: 60 },
    { title: 'Tên sheet', dataIndex: 'sheetName', key: 'sheetName' },
    { title: 'Tên hiển thị', dataIndex: 'displayName', key: 'displayName', ellipsis: true },
    { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 80 },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: FormSheetDto) => (
        <TableActions
          align="right"
          items={[
            { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditSheet(record) },
            {
              key: 'columns',
              label: 'Cột',
              icon: <UnorderedListOutlined />,
              onClick: () => {
                setSelectedSheetId(record.id)
                setSelectedColumnId(null)
              },
            },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: { title: 'Xóa sheet?', okText: 'Xóa', cancelText: 'Hủy' },
              onClick: () => deleteSheetMutation.mutate(record.id),
            },
          ]}
        />
      ),
    },
  ]

  const columnColumns = [
    { title: 'Mã cột', dataIndex: 'columnCode', key: 'columnCode', width: 100 },
    { title: 'Tên cột', dataIndex: 'columnName', key: 'columnName' },
    { title: 'Cột Excel', dataIndex: 'excelColumn', key: 'excelColumn', width: 90 },
    { title: 'Kiểu', dataIndex: 'dataType', key: 'dataType', width: 90 },
    { title: 'Công thức', dataIndex: 'formula', key: 'formula', ellipsis: true },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: FormColumnDto) => (
        <TableActions
          align="right"
          items={[
            { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditColumn(record) },
            {
              key: 'filter',
              label: 'Bộ lọc / Ánh xạ',
              icon: <FilterOutlined />,
              onClick: () => setSelectedColumnId(record.id),
            },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: { title: 'Xóa cột?', okText: 'Xóa', cancelText: 'Hủy' },
              onClick: () => deleteColumnMutation.mutate(record.id),
            },
          ]}
        />
      ),
    },
  ]

  return (
    <>
      <Breadcrumb
        style={{ marginBottom: 16 }}
        items={[
          { title: <Link to="/forms">Biểu mẫu</Link> },
          { title: form.name },
          { title: 'Cấu hình (hàng, cột, bộ lọc, công thức)' },
        ]}
      />
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Cấu hình: {form.name}
      </Typography.Title>
      <Space style={{ marginBottom: 16 }} wrap>
        <input
          ref={fileInputRef}
          type="file"
          accept=".xlsx"
          style={{ display: 'none' }}
          onChange={(e) => {
            const file = e.target.files?.[0]
            if (file) {
              uploadTemplateMutation.mutate(file)
              e.target.value = ''
            }
          }}
        />
        <Button
          icon={<UploadOutlined />}
          onClick={() => fileInputRef.current?.click()}
          loading={uploadTemplateMutation.isPending}
        >
          Upload template Excel
        </Button>
        {form.hasTemplateDisplay && (
          <Text type="secondary">Đã có template (dùng làm mẫu nhập liệu)</Text>
        )}
      </Space>

      <Card title="P8 – Nguồn dữ liệu" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreateDataSource}>
            Thêm nguồn dữ liệu
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          dataSource={dataSources}
          pagination={false}
          bordered
          columns={[
            { title: 'Mã', dataIndex: 'code', key: 'code', width: 120 },
            { title: 'Tên', dataIndex: 'name', key: 'name' },
            { title: 'Loại', dataIndex: 'sourceType', key: 'sourceType', width: 90 },
            { title: 'Nguồn (bảng/view)', dataIndex: 'sourceRef', key: 'sourceRef', ellipsis: true, render: (v: string | null) => v ?? '–' },
            { title: 'Cột hiển thị', dataIndex: 'displayColumn', key: 'displayColumn', width: 100, render: (v: string | null) => v ?? '–' },
            { title: 'Cột giá trị', dataIndex: 'valueColumn', key: 'valueColumn', width: 100, render: (v: string | null) => v ?? '–' },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: DataSourceDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditDataSource(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa nguồn dữ liệu?', okText: 'Xóa', cancelText: 'Hủy' },
                      onClick: () => deleteDataSourceMutation.mutate(record.id),
                    },
                  ]}
                />
              ),
            },
          ]}
        />
      </Card>

      <Card title="P8 – Bộ lọc" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreateFilter}>
            Thêm bộ lọc
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          dataSource={filterDefinitions}
          pagination={false}
          bordered
          columns={[
            { title: 'Mã', dataIndex: 'code', key: 'code', width: 120 },
            { title: 'Tên', dataIndex: 'name', key: 'name' },
            { title: 'Logic', dataIndex: 'logicalOperator', key: 'logicalOperator', width: 70 },
            { title: 'Nguồn (ID)', dataIndex: 'dataSourceId', key: 'dataSourceId', width: 90, render: (v: number | null) => v ?? '–' },
            { title: 'Số điều kiện', key: 'conditionsCount', width: 100, render: (_: unknown, r: FilterDefinitionDto) => (r.conditions?.length ?? 0) },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: FilterDefinitionDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditFilter(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa bộ lọc?', okText: 'Xóa', cancelText: 'Hủy' },
                      onClick: () => deleteFilterMutation.mutate(record.id),
                    },
                  ]}
                />
              ),
            },
          ]}
        />
      </Card>

      <Card title="Sheet (Hàng)" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreateSheet}>
            Thêm sheet
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          columns={sheetColumns}
          dataSource={sheets}
          loading={sheetsLoading}
          pagination={false}
          bordered
          onRow={(record) => ({
            onClick: () => {
              setSelectedSheetId(record.id)
              setSelectedColumnId(null)
            },
            style: {
              cursor: 'pointer',
              background: selectedSheetId === record.id ? '#e6f4ff' : undefined,
            },
          })}
        />
      </Card>

      {selectedSheetId != null && (
        <Card title="Cột (dạng cây – theo sheet đã chọn)" style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 12 }}>
            <Button type="primary" icon={<PlusOutlined />} onClick={openCreateColumn}>
              Thêm cột
            </Button>
          </div>
          <Table
            rowKey="key"
            size="small"
            columns={columnColumns}
            dataSource={columnTreeToTableData(columnsTree)}
            loading={columnsLoading || columnsTreeLoading}
            pagination={false}
            bordered
            onRow={(record) => ({
              onClick: () => setSelectedColumnId(record.id),
              style: {
                cursor: 'pointer',
                background: selectedColumnId === record.id ? '#e6f4ff' : undefined,
              },
            })}
          />
        </Card>
      )}

      {selectedSheetId != null && (
        <Card title="Hàng (Form Row – dạng cây)" style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 12 }}>
            <Button type="primary" icon={<PlusOutlined />} onClick={openCreateRow}>
              Thêm hàng
            </Button>
          </div>
          <Table
            rowKey="key"
            size="small"
            loading={rowsTreeLoading}
            dataSource={rowTreeToTableData(rowsTree)}
            pagination={false}
            bordered
            columns={[
              { title: 'Mã hàng', dataIndex: 'rowCode', key: 'rowCode', width: 100, render: (v: string | null) => v ?? '–' },
              { title: 'Tên hàng', dataIndex: 'rowName', key: 'rowName', render: (v: string | null) => v ?? '–' },
              { title: 'Hàng Excel từ', dataIndex: 'excelRowStart', key: 'excelRowStart', width: 100 },
              { title: 'Loại', dataIndex: 'rowType', key: 'rowType', width: 90 },
              { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 80 },
              {
                title: 'Thao tác',
                key: 'actions',
                width: ACTIONS_COLUMN_WIDTH_ICON,
                align: 'right' as const,
                render: (_: unknown, record: FormRowTreeDto) => (
                  <TableActions
                    align="right"
                    items={[
                      { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditRow(record) },
                      {
                        key: 'delete',
                        label: 'Xóa',
                        icon: <DeleteOutlined />,
                        danger: true,
                        confirm: { title: 'Xóa hàng?', okText: 'Xóa', cancelText: 'Hủy' },
                        onClick: () => deleteRowMutation.mutate(record.id),
                      },
                    ]}
                  />
                ),
              },
            ]}
          />
        </Card>
      )}

      {selectedSheetId != null && (
        <Card title="Vùng chỉ tiêu động" style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 12 }}>
            <Button type="primary" icon={<PlusOutlined />} onClick={openCreateRegion}>
              Thêm vùng
            </Button>
          </div>
          <Table
            rowKey="id"
            size="small"
            loading={regionsLoading}
            dataSource={dynamicRegions}
            pagination={false}
            bordered
            columns={[
              { title: 'Hàng bắt đầu', dataIndex: 'excelRowStart', key: 'excelRowStart', width: 100 },
              { title: 'Hàng kết thúc', dataIndex: 'excelRowEnd', key: 'excelRowEnd', width: 100, render: (v: number | null) => v ?? '–' },
              { title: 'Cột tên', dataIndex: 'excelColName', key: 'excelColName', width: 80 },
              { title: 'Cột giá trị', dataIndex: 'excelColValue', key: 'excelColValue', width: 80 },
              { title: 'Số dòng tối đa', dataIndex: 'maxRows', key: 'maxRows', width: 100 },
              { title: 'Độ sâu mở rộng', dataIndex: 'indicatorExpandDepth', key: 'indicatorExpandDepth', width: 100 },
              { title: 'Catalog', dataIndex: 'indicatorCatalogId', key: 'indicatorCatalogId', width: 80, render: (v: number | null) => v ?? '–' },
              { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 70 },
              {
                title: 'Thao tác',
                key: 'actions',
                width: ACTIONS_COLUMN_WIDTH_ICON,
                align: 'right' as const,
                render: (_: unknown, record: FormDynamicRegionDto) => (
                  <TableActions
                    align="right"
                    items={[
                      { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditRegion(record) },
                      {
                        key: 'delete',
                        label: 'Xóa',
                        icon: <DeleteOutlined />,
                        danger: true,
                        confirm: { title: 'Xóa vùng chỉ tiêu động?', okText: 'Xóa', cancelText: 'Hủy' },
                        onClick: () => deleteRegionMutation.mutate(record.id),
                      },
                    ]}
                  />
                ),
              },
            ]}
          />
        </Card>
      )}

      {selectedSheetId != null && (
        <Card title="P8 – Vị trí placeholder (mở rộng N hàng)" style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 12 }}>
            <Button type="primary" icon={<PlusOutlined />} onClick={openCreateOccurrence}>
              Thêm vị trí placeholder
            </Button>
          </div>
          <Table
            rowKey="id"
            size="small"
            loading={occurrencesLoading}
            dataSource={placeholderOccurrences}
            pagination={false}
            bordered
            columns={[
              { title: 'Hàng Excel', dataIndex: 'excelRowStart', key: 'excelRowStart', width: 90 },
              {
                title: 'Vùng chỉ tiêu',
                dataIndex: 'formDynamicRegionId',
                key: 'formDynamicRegionId',
                width: 100,
                render: (v: number) => {
                  const r = dynamicRegions.find((x) => x.id === v)
                  return r ? `Vùng ${r.id} (hàng ${r.excelRowStart})` : v
                },
              },
              {
                title: 'Bộ lọc',
                dataIndex: 'filterDefinitionId',
                key: 'filterDefinitionId',
                width: 100,
                render: (v: number | null) => {
                  if (v == null) return '–'
                  const f = filterDefinitions.find((x) => x.id === v)
                  return f ? f.name : v
                },
              },
              {
                title: 'Nguồn dữ liệu',
                dataIndex: 'dataSourceId',
                key: 'dataSourceId',
                width: 100,
                render: (v: number | null) => {
                  if (v == null) return '–'
                  const d = dataSources.find((x) => x.id === v)
                  return d ? d.name : v
                },
              },
              { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 70 },
              { title: 'Max hàng', dataIndex: 'maxRows', key: 'maxRows', width: 80, render: (v: number | null) => v ?? '–' },
              {
                title: 'Thao tác',
                key: 'actions',
                width: ACTIONS_COLUMN_WIDTH_ICON,
                align: 'right' as const,
                render: (_: unknown, record: FormPlaceholderOccurrenceDto) => (
                  <TableActions
                    align="right"
                    items={[
                      { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditOccurrence(record) },
                      {
                        key: 'delete',
                        label: 'Xóa',
                        icon: <DeleteOutlined />,
                        danger: true,
                        confirm: { title: 'Xóa vị trí placeholder?', okText: 'Xóa', cancelText: 'Hủy' },
                        onClick: () => deleteOccurrenceMutation.mutate(record.id),
                      },
                    ]}
                  />
                ),
              },
            ]}
          />
        </Card>
      )}

      {selectedSheetId != null && (
        <Card title="P8 – Vùng cột động" style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 12 }}>
            <Button type="primary" icon={<PlusOutlined />} onClick={openCreateColumnRegion}>
              Thêm vùng cột động
            </Button>
          </div>
          <Table
            rowKey="id"
            size="small"
            loading={columnRegionsLoading}
            dataSource={dynamicColumnRegions}
            pagination={false}
            bordered
            columns={[
              { title: 'Mã', dataIndex: 'code', key: 'code', width: 120 },
              { title: 'Tên', dataIndex: 'name', key: 'name' },
              { title: 'Nguồn cột', dataIndex: 'columnSourceType', key: 'columnSourceType', width: 140 },
              { title: 'Tham chiếu', dataIndex: 'columnSourceRef', key: 'columnSourceRef', ellipsis: true, render: (v: string | null) => v ?? '–' },
              { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 70 },
              { title: 'Bật', dataIndex: 'isActive', key: 'isActive', width: 60, render: (v: boolean) => (v ? 'Có' : 'Không') },
              {
                title: 'Thao tác',
                key: 'actions',
                width: ACTIONS_COLUMN_WIDTH_ICON,
                align: 'right' as const,
                render: (_: unknown, record: FormDynamicColumnRegionDto) => (
                  <TableActions
                    align="right"
                    items={[
                      { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditColumnRegion(record) },
                      {
                        key: 'delete',
                        label: 'Xóa',
                        icon: <DeleteOutlined />,
                        danger: true,
                        confirm: { title: 'Xóa vùng cột động?', okText: 'Xóa', cancelText: 'Hủy' },
                        onClick: () => deleteColumnRegionMutation.mutate(record.id),
                      },
                    ]}
                  />
                ),
              },
            ]}
          />
        </Card>
      )}

      {selectedSheetId != null && (
        <Card title="P8 – Vị trí placeholder cột (mở rộng N cột)" style={{ marginBottom: 16 }}>
          <div style={{ marginBottom: 12 }}>
            <Button type="primary" icon={<PlusOutlined />} onClick={openCreateColumnOccurrence}>
              Thêm vị trí placeholder cột
            </Button>
          </div>
          <Table
            rowKey="id"
            size="small"
            loading={columnOccurrencesLoading}
            dataSource={placeholderColumnOccurrences}
            pagination={false}
            bordered
            columns={[
              { title: 'Cột Excel', dataIndex: 'excelColStart', key: 'excelColStart', width: 90 },
              {
                title: 'Vùng cột động',
                dataIndex: 'formDynamicColumnRegionId',
                key: 'formDynamicColumnRegionId',
                render: (v: number) => {
                  const r = dynamicColumnRegions.find((x) => x.id === v)
                  return r ? `${r.name} (${r.code})` : v
                },
              },
              {
                title: 'Bộ lọc',
                dataIndex: 'filterDefinitionId',
                key: 'filterDefinitionId',
                width: 100,
                render: (v: number | null) => {
                  if (v == null) return '–'
                  const f = filterDefinitions.find((x) => x.id === v)
                  return f ? f.name : v
                },
              },
              { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 70 },
              { title: 'Max cột', dataIndex: 'maxColumns', key: 'maxColumns', width: 80, render: (v: number | null) => v ?? '–' },
              {
                title: 'Thao tác',
                key: 'actions',
                width: ACTIONS_COLUMN_WIDTH_ICON,
                align: 'right' as const,
                render: (_: unknown, record: FormPlaceholderColumnOccurrenceDto) => (
                  <TableActions
                    align="right"
                    items={[
                      { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditColumnOccurrence(record) },
                      {
                        key: 'delete',
                        label: 'Xóa',
                        icon: <DeleteOutlined />,
                        danger: true,
                        confirm: { title: 'Xóa vị trí placeholder cột?', okText: 'Xóa', cancelText: 'Hủy' },
                        onClick: () => deleteColumnOccurrenceMutation.mutate(record.id),
                      },
                    ]}
                  />
                ),
              },
            ]}
          />
        </Card>
      )}

      {/* ---- FormWorkflowConfig ---- */}
      <Card title="Quy trình phê duyệt" style={{ marginBottom: 16 }}>
        <Space style={{ marginBottom: 12 }}>
          <Select
            style={{ width: 320 }}
            placeholder="Chọn quy trình để gắn"
            options={allWorkflowDefs
              .filter((w) => !workflowConfigs.some((c) => c.workflowDefinitionId === w.id))
              .map((w) => ({ value: w.id, label: `${w.code} – ${w.name} (${w.totalSteps} bước)` }))}
            onSelect={(wfId: number) =>
              createWfConfigMut.mutate({ formDefinitionId: id, workflowDefinitionId: wfId, isActive: true })
            }
          />
        </Space>
        <Table
          rowKey="id"
          size="small"
          bordered
          pagination={false}
          dataSource={workflowConfigs}
          columns={[
            { title: 'Mã quy trình', dataIndex: 'workflowDefinitionCode', key: 'wfCode', width: 160 },
            { title: 'ID quy trình', dataIndex: 'workflowDefinitionId', key: 'wfId', width: 100, align: 'center' as const },
            {
              title: 'Trạng thái',
              dataIndex: 'isActive',
              key: 'isActive',
              width: 100,
              align: 'center' as const,
              render: (v: boolean) => v ? 'Hoạt động' : 'Tắt',
            },
            {
              title: 'Thao tác',
              key: 'actions',
              width: 80,
              align: 'right' as const,
              render: (_: unknown, record: FormWorkflowConfigDto) => (
                <TableActions
                  align="right"
                  items={[
                    {
                      key: 'delete',
                      label: 'Gỡ',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Gỡ quy trình khỏi biểu mẫu?', okText: 'Gỡ', cancelText: 'Hủy' },
                      onClick: () => deleteWfConfigMut.mutate(record.id),
                    },
                  ]}
                />
              ),
            },
          ]}
        />
      </Card>

      {selectedSheetId != null && selectedColumnId != null && (
        <>
          <Card title="Bộ lọc dữ liệu (Data Binding)" style={{ marginBottom: 16 }}>
            <Form form={bindingForm} layout="vertical" style={{ maxWidth: 560 }}>
              <Form.Item name="bindingType" label="Loại nguồn">
                <Select options={BINDING_TYPES} />
              </Form.Item>
              <Form.Item name="defaultValue" label="Giá trị mặc định">
                <Input placeholder="Giá trị tĩnh hoặc mặc định" />
              </Form.Item>
              <Form.Item name="formula" label="Công thức">
                <Input.TextArea rows={2} placeholder="Biểu thức hoặc tham chiếu cột" />
              </Form.Item>
              <Form.Item name="sourceTable" label="Bảng nguồn (Database)">
                <Input placeholder="Tên bảng" />
              </Form.Item>
              <Form.Item name="sourceColumn" label="Cột nguồn">
                <Input placeholder="Tên cột" />
              </Form.Item>
              <Form.Item name="sourceCondition" label="Điều kiện (WHERE)">
                <Input placeholder="VD: Status = 1" />
              </Form.Item>
              <Form.Item name="apiEndpoint" label="URL API">
                <Input placeholder="https://..." />
              </Form.Item>
              <Form.Item name="apiMethod" label="Method">
                <Select
                  options={[
                    { value: 'GET', label: 'GET' },
                    { value: 'POST', label: 'POST' },
                  ]}
                />
              </Form.Item>
              <Form.Item name="apiResponsePath" label="Đường dẫn JSON (kết quả)">
                <Input placeholder="VD: data.items" />
              </Form.Item>
              <Form.Item name="transformExpression" label="Biểu thức chuyển đổi">
                <Input placeholder="Tùy chọn" />
              </Form.Item>
              <Form.Item name="cacheMinutes" label="Cache (phút)">
                <InputNumber min={0} style={{ width: 120 }} />
              </Form.Item>
              <Form.Item name="isActive" valuePropName="checked">
                <Checkbox>Đang bật</Checkbox>
              </Form.Item>
              <Button type="primary" onClick={handleBindingSubmit}>
                Lưu bộ lọc dữ liệu
              </Button>
            </Form>
          </Card>
          <Card title="Ánh xạ cột (Column Mapping)">
            <Form form={mappingForm} layout="vertical" style={{ maxWidth: 400 }}>
              <Form.Item
                name="targetColumnName"
                label="Tên cột đích"
                rules={[{ required: true, message: 'Nhập tên cột đích' }]}
              >
                <Input placeholder="Tên cột khi lưu" />
              </Form.Item>
              <Form.Item name="targetColumnIndex" label="Thứ tự cột đích">
                <InputNumber min={0} style={{ width: 120 }} />
              </Form.Item>
              <Form.Item name="aggregateFunction" label="Hàm tổng hợp">
                <Select
                  allowClear
                  placeholder="Sum, Avg, ..."
                  options={[
                    { value: 'Sum', label: 'Sum' },
                    { value: 'Avg', label: 'Avg' },
                    { value: 'Min', label: 'Min' },
                    { value: 'Max', label: 'Max' },
                    { value: 'Count', label: 'Count' },
                  ]}
                />
              </Form.Item>
              <Button type="primary" onClick={handleMappingSubmit}>
                Lưu ánh xạ cột
              </Button>
            </Form>
          </Card>
        </>
      )}

      <Modal
        title={editingSheetId != null ? 'Sửa sheet' : 'Thêm sheet'}
        open={sheetModalOpen}
        onOk={handleSheetSubmit}
        onCancel={() => setSheetModalOpen(false)}
        okText={editingSheetId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={sheetForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="sheetIndex" label="Chỉ số sheet" rules={[{ required: true }]}>
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="sheetName" label="Tên sheet" rules={[{ required: true }]}>
              <Input placeholder="VD: Sheet1" />
            </Form.Item>
            <Form.Item name="displayName" label="Tên hiển thị">
              <Input placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea rows={2} />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự hiển thị">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item
              name="dataStartRow"
              label="Hàng bắt đầu dữ liệu (template)"
              tooltip="Hàng Excel bắt đầu điền dữ liệu (1-based). VD: 4 = hàng 4 trở đi là dữ liệu, hàng 1–3 là header. Để trống = tự động theo header cột."
            >
              <InputNumber min={1} placeholder="Để trống = tự động" style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isDataSheet" valuePropName="checked">
              <Checkbox>Là sheet dữ liệu</Checkbox>
            </Form.Item>
            <Form.Item name="isVisible" valuePropName="checked">
              <Checkbox>Hiển thị</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>

      <Modal
        title={
          editingColumnId != null
            ? 'Sửa cột'
            : columnCreateMode === 'from-catalog'
              ? 'Thêm cột (chọn từ danh mục chỉ tiêu)'
              : 'Thêm cột (nhập trực tiếp)'
        }
        open={columnModalOpen}
        onOk={
          editingColumnId != null
            ? () => void handleColumnSubmit()
            : columnCreateMode === 'from-catalog'
              ? () => handleCreateColumnFromIndicator()
              : () => void handleColumnSubmit()
        }
        okText={
          editingColumnId != null
            ? 'Cập nhật'
            : columnCreateMode === 'from-catalog'
              ? 'Tạo cột từ chỉ tiêu'
              : 'Tạo'
        }
        cancelText="Hủy"
        onCancel={() => {
          setColumnModalOpen(false)
          setColumnCreateMode('from-catalog')
          setSelectedCatalogIdForColumn(null)
          setSelectedIndicatorIdForColumn(null)
        }}
        width={MODAL_FORM.LARGE}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        styles={{ body: { maxHeight: '70vh', overflow: 'auto' } }}
      >
        <div ref={formContainerRef}>
          {editingColumnId == null && columnCreateMode === 'from-catalog' ? (
            <>
              <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 8 }}>
                Nên chọn từ danh mục để thống nhất giữa các biểu mẫu. Dùng &quot;Tạo cột mới (nhập tay)&quot; cho cột tiêu đề, công thức hoặc đặc biệt.
              </Typography.Text>
              <Form layout="vertical" style={{ marginTop: 16 }}>
                <Form.Item label="Danh mục chỉ tiêu">
                  <Select
                    placeholder="Chọn danh mục chỉ tiêu"
                    allowClear
                    value={selectedCatalogIdForColumn ?? undefined}
                    onChange={(v) => {
                      setSelectedCatalogIdForColumn(v ?? null)
                      setSelectedIndicatorIdForColumn(null)
                    }}
                    options={indicatorCatalogs.map((c: IndicatorCatalogDto) => ({ value: c.id, label: c.name }))}
                    style={{ width: '100%' }}
                  />
                </Form.Item>
                <Form.Item label="Chọn chỉ tiêu">
                  <TreeSelect
                    placeholder="Chọn chỉ tiêu (sau khi chọn danh mục)"
                    allowClear
                    value={selectedIndicatorIdForColumn ?? undefined}
                    onChange={(v) => setSelectedIndicatorIdForColumn(v ?? null)}
                    treeData={indicatorToTreeSelectOptions(indicatorsForColumn)}
                    treeDefaultExpandAll
                    style={{ width: '100%' }}
                    disabled={selectedCatalogIdForColumn == null}
                  />
                </Form.Item>
              </Form>
              <div style={{ marginTop: 16 }}>
                <Button type="link" onClick={switchToManualColumnForm} style={{ padding: 0 }}>
                  Tạo cột mới (nhập trực tiếp)
                </Button>
              </div>
            </>
          ) : (
          <Form form={columnForm} layout="vertical" style={{ marginTop: 16 }}>
            {editingColumnId == null && (
              <div style={{ marginBottom: 12 }}>
                <Button type="link" onClick={switchToFromCatalogColumnForm} style={{ padding: 0 }}>
                  Quay lại chọn từ danh mục
                </Button>
              </div>
            )}
            <Form.Item name="parentId" label="Cột cha (phân cấp)">
              <TreeSelect
                allowClear
                placeholder="Không có (cột gốc)"
                treeData={(() => {
                  const flat = columns as FormColumnDto[]
                  const tree = buildTree(flat, { parentKey: 'parentId' })
                  const excluded = editingColumnId != null ? treeExcludeSelfAndDescendants(tree, editingColumnId) : tree
                  return toTreeSelectOptions(excluded, (n) => `${n.columnCode} - ${n.columnName}`)
                })()}
                treeDefaultExpandAll
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="columnCode" label="Mã cột" rules={[{ required: true }]}>
              <Input placeholder="VD: COL_A" />
            </Form.Item>
            <Form.Item name="columnName" label="Tên cột" rules={[{ required: true }]}>
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="columnGroupName" label="Nhóm header tầng 1">
              <Input placeholder="VD: Thông tin chung (merge header Excel)" />
            </Form.Item>
            <Form.Item name="columnGroupLevel2" label="Nhóm header tầng 2">
              <Input placeholder="Tùy chọn (header nhiều tầng)" />
            </Form.Item>
            <Form.Item name="columnGroupLevel3" label="Nhóm header tầng 3">
              <Input placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="columnGroupLevel4" label="Nhóm header tầng 4">
              <Input placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="excelColumn" label="Cột Excel" rules={[{ required: true }]}>
              <Input placeholder="A, B, C..." />
            </Form.Item>
            <Form.Item name="dataType" label="Kiểu dữ liệu">
              <Select options={DATA_TYPES} />
            </Form.Item>
            <Form.Item name="formula" label="Công thức">
              <Input.TextArea rows={2} placeholder="Công thức Excel hoặc tham chiếu" />
            </Form.Item>
            <Form.Item name="defaultValue" label="Giá trị mặc định">
              <Input />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="validationRule" label="Quy tắc kiểm tra">
              <Input placeholder="Regex hoặc biểu thức" />
            </Form.Item>
            <Form.Item name="validationMessage" label="Thông báo lỗi">
              <Input />
            </Form.Item>
            <Form.Item name="format" label="Định dạng (số, ngày)">
              <Input placeholder="VD: #,##0.00" />
            </Form.Item>
            <Form.Item name="width" label="Độ rộng">
              <InputNumber min={0} style={{ width: 120 }} />
            </Form.Item>
            <Form.Item name="isRequired" valuePropName="checked">
              <Checkbox>Bắt buộc</Checkbox>
            </Form.Item>
            <Form.Item name="isEditable" valuePropName="checked">
              <Checkbox>Có thể sửa</Checkbox>
            </Form.Item>
            <Form.Item name="isHidden" valuePropName="checked">
              <Checkbox>Ẩn</Checkbox>
            </Form.Item>
          </Form>
          )}
        </div>
      </Modal>

      <Modal
        title={editingRegionId != null ? 'Sửa vùng chỉ tiêu động' : 'Thêm vùng chỉ tiêu động'}
        open={regionModalOpen}
        onOk={handleRegionSubmit}
        onCancel={() => setRegionModalOpen(false)}
        okText={editingRegionId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={regionForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="excelRowStart" label="Hàng bắt đầu (Excel)" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: '100%' }} placeholder="1" />
            </Form.Item>
            <Form.Item name="excelRowEnd" label="Hàng kết thúc (Excel)">
              <InputNumber min={1} style={{ width: '100%' }} placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="excelColName" label="Cột chứa tên chỉ tiêu" rules={[{ required: true }]}>
              <Input placeholder="VD: A" />
            </Form.Item>
            <Form.Item name="excelColValue" label="Cột chứa giá trị" rules={[{ required: true }]}>
              <Input placeholder="VD: B" />
            </Form.Item>
            <Form.Item name="maxRows" label="Số dòng tối đa">
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="indicatorExpandDepth" label="Độ sâu mở rộng chỉ tiêu">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="indicatorCatalogId" label="ID danh mục chỉ tiêu (tùy chọn)">
              <InputNumber style={{ width: '100%' }} placeholder="Để trống nếu không dùng catalog" />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự hiển thị">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
          </Form>
        </div>
      </Modal>

      <Modal
        title={editingRowId != null ? 'Sửa hàng' : 'Thêm hàng'}
        open={rowModalOpen}
        onOk={handleRowSubmit}
        onCancel={() => setRowModalOpen(false)}
        okText={editingRowId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={rowForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="parentId" label="Hàng cha (phân cấp)">
              <TreeSelect
                allowClear
                placeholder="Không có (hàng gốc)"
                treeData={(() => {
                  const tree = buildTree(rows, { parentKey: 'parentId' })
                  const excluded = editingRowId != null ? treeExcludeSelfAndDescendants(tree, editingRowId) : tree
                  return toTreeSelectOptions(excluded, (n) => `${n.rowCode ?? n.id} - ${n.rowName ?? ''}`.trim() || `Hàng ${n.id}`)
                })()}
                treeDefaultExpandAll
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="rowCode" label="Mã hàng">
              <Input placeholder="VD: R1" />
            </Form.Item>
            <Form.Item name="rowName" label="Tên hàng">
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="excelRowStart" label="Hàng Excel bắt đầu" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="excelRowEnd" label="Hàng Excel kết thúc">
              <InputNumber min={1} style={{ width: '100%' }} placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="rowType" label="Loại hàng">
              <Select options={ROW_TYPES} />
            </Form.Item>
            <Form.Item name="formDynamicRegionId" label="Vùng chỉ tiêu động (tùy chọn)">
              <Select
                allowClear
                placeholder="Không thuộc vùng"
                options={dynamicRegions.map((r) => ({ value: r.id, label: `Vùng ${r.id} (hàng ${r.excelRowStart})` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isRepeating" valuePropName="checked">
              <Checkbox>Lặp (có thể thêm nhiều dòng)</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>

      <Modal
        title={editingDataSourceId != null ? 'Sửa nguồn dữ liệu' : 'Thêm nguồn dữ liệu'}
        open={dataSourceModalOpen}
        onOk={handleDataSourceSubmit}
        onCancel={() => setDataSourceModalOpen(false)}
        okText={editingDataSourceId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={dataSourceForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã" rules={[{ required: true }]}>
              <Input placeholder="VD: PROJECT_LIST" disabled={editingDataSourceId != null} />
            </Form.Item>
            <Form.Item name="name" label="Tên" rules={[{ required: true }]}>
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="sourceType" label="Loại nguồn">
              <Select
                options={[
                  { value: 'Table', label: 'Table' },
                  { value: 'View', label: 'View' },
                  { value: 'Catalog', label: 'Catalog' },
                  { value: 'API', label: 'API' },
                ]}
              />
            </Form.Item>
            <Form.Item name="sourceRef" label="Bảng/View (tên)">
              <Input placeholder="VD: BCDT_Project" />
            </Form.Item>
            <Form.Item name="indicatorCatalogId" label="ID danh mục chỉ tiêu (Catalog)">
              <InputNumber style={{ width: '100%' }} placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="displayColumn" label="Cột hiển thị (tên chỉ tiêu)">
              <Input placeholder="VD: Name, ProjectName" />
            </Form.Item>
            <Form.Item name="valueColumn" label="Cột giá trị">
              <Input placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked">
              <Checkbox>Đang bật</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>

      <Modal
        title={editingFilterId != null ? 'Sửa bộ lọc' : 'Thêm bộ lọc'}
        open={filterModalOpen}
        onOk={handleFilterSubmit}
        onCancel={() => setFilterModalOpen(false)}
        okText={editingFilterId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.LARGE}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        styles={{ body: { maxHeight: '70vh', overflow: 'auto' } }}
      >
        <div ref={formContainerRef}>
          <Form form={filterForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã" rules={[{ required: true }]}>
              <Input placeholder="VD: DU_AN_NGAY_VB" disabled={editingFilterId != null} />
            </Form.Item>
            <Form.Item name="name" label="Tên" rules={[{ required: true }]}>
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="logicalOperator" label="Logic gộp điều kiện">
              <Select options={[{ value: 'AND', label: 'AND' }, { value: 'OR', label: 'OR' }]} />
            </Form.Item>
            <Form.Item name="dataSourceId" label="Nguồn dữ liệu (tùy chọn)">
              <Select
                allowClear
                placeholder="Chọn nguồn"
                options={dataSources.map((d) => ({ value: d.id, label: `${d.code} – ${d.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Typography.Text strong style={{ display: 'block', marginBottom: 8 }}>Điều kiện</Typography.Text>
            {filterConditions.map((_, idx) => (
              <div key={idx} style={{ display: 'flex', gap: 8, marginBottom: 8, alignItems: 'flex-start', flexWrap: 'wrap' }}>
                <Input
                  placeholder="Trường"
                  value={filterConditions[idx]?.field}
                  onChange={(e) => {
                    const next = [...filterConditions]
                    if (next[idx]) next[idx] = { ...next[idx], field: e.target.value }
                    setFilterConditions(next)
                  }}
                  style={{ width: 120 }}
                />
                <Select
                  placeholder="Toán tử"
                  value={filterConditions[idx]?.operator || undefined}
                  onChange={(v) => {
                    const next = [...filterConditions]
                    if (next[idx]) next[idx] = { ...next[idx], operator: v ?? '' }
                    setFilterConditions(next)
                  }}
                  style={{ width: 100 }}
                  options={[
                    { value: '=', label: '=' },
                    { value: '<>', label: '<>' },
                    { value: '<', label: '<' },
                    { value: '>', label: '>' },
                    { value: '<=', label: '<=' },
                    { value: '>=', label: '>=' },
                    { value: 'LIKE', label: 'LIKE' },
                    { value: 'IN', label: 'IN' },
                  ]}
                />
                <Select
                  placeholder="Loại giá trị"
                  value={filterConditions[idx]?.valueType || 'Literal'}
                  onChange={(v) => {
                    const next = [...filterConditions]
                    if (next[idx]) next[idx] = { ...next[idx], valueType: v ?? 'Literal' }
                    setFilterConditions(next)
                  }}
                  style={{ width: 100 }}
                  options={[
                    { value: 'Literal', label: 'Literal' },
                    { value: 'Parameter', label: 'Parameter' },
                  ]}
                />
                <Input
                  placeholder="Giá trị"
                  value={filterConditions[idx]?.value ?? ''}
                  onChange={(e) => {
                    const next = [...filterConditions]
                    if (next[idx]) next[idx] = { ...next[idx], value: e.target.value }
                    setFilterConditions(next)
                  }}
                  style={{ width: 140 }}
                />
                <Button
                  type="text"
                  danger
                  icon={<DeleteOutlined />}
                  onClick={() => setFilterConditions(filterConditions.filter((_, i) => i !== idx))}
                />
              </div>
            ))}
            <Button
              type="dashed"
              icon={<PlusOutlined />}
              onClick={() =>
                setFilterConditions([
                  ...filterConditions,
                  {
                    conditionOrder: filterConditions.length,
                    field: '',
                    operator: '=',
                    valueType: 'Literal',
                    value: '',
                  },
                ])
              }
            >
              Thêm điều kiện
            </Button>
          </Form>
        </div>
      </Modal>

      <Modal
        title={editingOccurrenceId != null ? 'Sửa vị trí placeholder' : 'Thêm vị trí placeholder'}
        open={occurrenceModalOpen}
        onOk={handleOccurrenceSubmit}
        onCancel={() => setOccurrenceModalOpen(false)}
        okText={editingOccurrenceId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={occurrenceForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="formDynamicRegionId" label="Vùng chỉ tiêu động" rules={[{ required: true }]}>
              <Select
                placeholder="Chọn vùng"
                options={dynamicRegions.map((r) => ({
                  value: r.id,
                  label: `Vùng ${r.id} (hàng ${r.excelRowStart}, cột ${r.excelColName}/${r.excelColValue})`,
                }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="excelRowStart" label="Hàng Excel bắt đầu" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="filterDefinitionId" label="Bộ lọc (tùy chọn)">
              <Select
                allowClear
                placeholder="Không lọc"
                options={filterDefinitions.map((f) => ({ value: f.id, label: `${f.code} – ${f.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="dataSourceId" label="Nguồn dữ liệu (tùy chọn)">
              <Select
                allowClear
                placeholder="Dùng nguồn từ vùng"
                options={dataSources.map((d) => ({ value: d.id, label: `${d.code} – ${d.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="maxRows" label="Số dòng tối đa (tùy chọn)">
              <InputNumber min={0} style={{ width: '100%' }} placeholder="Để trống = không giới hạn" />
            </Form.Item>
          </Form>
        </div>
      </Modal>

      <Modal
        title={editingColumnRegionId != null ? 'Sửa vùng cột động' : 'Thêm vùng cột động'}
        open={columnRegionModalOpen}
        onOk={handleColumnRegionSubmit}
        onCancel={() => { setColumnRegionModalOpen(false); setEditingColumnRegionId(null) }}
        okText={editingColumnRegionId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={columnRegionForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã" rules={[{ required: true }]}>
              <Input placeholder="VD: COL_BY_PERIOD" disabled={editingColumnRegionId != null} />
            </Form.Item>
            <Form.Item name="name" label="Tên" rules={[{ required: true }]}>
              <Input placeholder="VD: Cột theo tháng trong kỳ" />
            </Form.Item>
            <Form.Item name="columnSourceType" label="Nguồn cột" rules={[{ required: true }]}>
              <Select options={COLUMN_SOURCE_TYPES} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="columnSourceRef" label="Tham chiếu (ID danh mục/nguồn hoặc danh sách cố định)">
              <Input placeholder="VD: 1 (catalog id), hoặc A,B,C (Fixed)" />
            </Form.Item>
            <Form.Item name="labelColumn" label="Cột nhãn (tên hiển thị)">
              <Input placeholder="VD: Name, MonthName" />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked">
              <Checkbox>Đang bật</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>

      <Modal
        title={editingColumnOccurrenceId != null ? 'Sửa vị trí placeholder cột' : 'Thêm vị trí placeholder cột'}
        open={columnOccurrenceModalOpen}
        onOk={handleColumnOccurrenceSubmit}
        onCancel={() => { setColumnOccurrenceModalOpen(false); setEditingColumnOccurrenceId(null) }}
        okText={editingColumnOccurrenceId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={columnOccurrenceForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="formDynamicColumnRegionId" label="Vùng cột động" rules={[{ required: true }]}>
              <Select
                placeholder="Chọn vùng cột động"
                options={dynamicColumnRegions.map((r) => ({ value: r.id, label: `${r.code} – ${r.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="excelColStart" label="Cột Excel bắt đầu (1-based)" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="filterDefinitionId" label="Bộ lọc (tùy chọn)">
              <Select
                allowClear
                placeholder="Không lọc"
                options={filterDefinitions.map((f) => ({ value: f.id, label: `${f.code} – ${f.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="maxColumns" label="Số cột tối đa (tùy chọn)">
              <InputNumber min={0} style={{ width: '100%' }} placeholder="Để trống = không giới hạn" />
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
