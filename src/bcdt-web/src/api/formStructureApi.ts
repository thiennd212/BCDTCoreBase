import axios from 'axios'
import { apiClient } from './apiClient'
import type {
  FormSheetDto,
  CreateFormSheetRequest,
  UpdateFormSheetRequest,
  FormColumnDto,
  FormColumnTreeDto,
  CreateFormColumnRequest,
  UpdateFormColumnRequest,
  FormDataBindingDto,
  CreateFormDataBindingRequest,
  UpdateFormDataBindingRequest,
  FormColumnMappingDto,
  CreateFormColumnMappingRequest,
  UpdateFormColumnMappingRequest,
  FormDynamicRegionDto,
  CreateFormDynamicRegionRequest,
  UpdateFormDynamicRegionRequest,
  FormRowDto,
  FormRowTreeDto,
  CreateFormRowRequest,
  UpdateFormRowRequest,
  FormRowFormulaScopeDto,
  CreateFormRowFormulaScopeRequest,
  FormCellFormulaDto,
  CreateFormCellFormulaRequest,
} from '../types/form.types'

/** Sheet: hàng (sheet) trong biểu mẫu */
export const formSheetsApi = {
  getList: async (formId: number): Promise<FormSheetDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormSheetDto[] }>(
      `/api/v1/forms/${formId}/sheets`
    )
    return res.data?.data ?? []
  },

  getById: async (formId: number, sheetId: number): Promise<FormSheetDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: FormSheetDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}`
    )
    return res.data?.data ?? null
  },

  create: async (formId: number, body: CreateFormSheetRequest): Promise<FormSheetDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormSheetDto }>(
      `/api/v1/forms/${formId}/sheets`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo sheet thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    body: UpdateFormSheetRequest
  ): Promise<FormSheetDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormSheetDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật sheet thất bại')
    return res.data.data
  },

  delete: async (formId: number, sheetId: number): Promise<void> => {
    await apiClient.delete(`/api/v1/forms/${formId}/sheets/${sheetId}`)
  },
}

/** Column: cột trong một sheet */
export const formColumnsApi = {
  getList: async (formId: number, sheetId: number, tree = false): Promise<FormColumnDto[] | FormColumnTreeDto[]> => {
    const url = tree
      ? `/api/v1/forms/${formId}/sheets/${sheetId}/columns?tree=true`
      : `/api/v1/forms/${formId}/sheets/${sheetId}/columns`
    const res = await apiClient.get<{ success: boolean; data: FormColumnDto[] | FormColumnTreeDto[] }>(url)
    return res.data?.data ?? []
  },

  getListTree: async (formId: number, sheetId: number): Promise<FormColumnTreeDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormColumnTreeDto[] }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns?tree=true`
    )
    return res.data?.data ?? []
  },

  getById: async (
    formId: number,
    sheetId: number,
    columnId: number
  ): Promise<FormColumnDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: FormColumnDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}`
    )
    return res.data?.data ?? null
  },

  create: async (
    formId: number,
    sheetId: number,
    body: CreateFormColumnRequest
  ): Promise<FormColumnDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormColumnDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo cột thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    columnId: number,
    body: UpdateFormColumnRequest
  ): Promise<FormColumnDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormColumnDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật cột thất bại')
    return res.data.data
  },

  delete: async (formId: number, sheetId: number, columnId: number): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}`
    )
  },
}

/** Form Row (B12 P2a – hàng trong sheet, phân cấp) */
export const formRowsApi = {
  getList: async (formId: number, sheetId: number): Promise<FormRowDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormRowDto[] }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/rows`
    )
    return res.data?.data ?? []
  },

  getListTree: async (formId: number, sheetId: number): Promise<FormRowTreeDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormRowTreeDto[] }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/rows?tree=true`
    )
    return res.data?.data ?? []
  },

  getById: async (formId: number, sheetId: number, rowId: number): Promise<FormRowDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: FormRowDto }>(
        `/api/v1/forms/${formId}/sheets/${sheetId}/rows/${rowId}`
      )
      return res.data?.data ?? null
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) return null
      throw err
    }
  },

  create: async (
    formId: number,
    sheetId: number,
    body: CreateFormRowRequest
  ): Promise<FormRowDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormRowDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/rows`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo hàng thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    rowId: number,
    body: UpdateFormRowRequest
  ): Promise<FormRowDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormRowDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/rows/${rowId}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật hàng thất bại')
    return res.data.data
  },

  delete: async (formId: number, sheetId: number, rowId: number): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/rows/${rowId}`
    )
  },
}

/** Data Binding: bộ lọc/nguồn dữ liệu cho cột (Static, Database, Formula, ...) */
export const formDataBindingApi = {
  get: async (
    formId: number,
    sheetId: number,
    columnId: number
  ): Promise<FormDataBindingDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: FormDataBindingDto }>(
        `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}/data-binding`
      )
      return res.data?.data ?? null
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) return null
      throw err
    }
  },

  create: async (
    formId: number,
    sheetId: number,
    columnId: number,
    body: CreateFormDataBindingRequest
  ): Promise<FormDataBindingDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormDataBindingDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}/data-binding`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo data binding thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    columnId: number,
    body: UpdateFormDataBindingRequest
  ): Promise<FormDataBindingDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormDataBindingDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}/data-binding`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật data binding thất bại')
    return res.data.data
  },

  delete: async (
    formId: number,
    sheetId: number,
    columnId: number
  ): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}/data-binding`
    )
  },
}

/** Column Mapping: ánh xạ cột Excel → cột lưu trữ */
export const formColumnMappingApi = {
  get: async (
    formId: number,
    sheetId: number,
    columnId: number
  ): Promise<FormColumnMappingDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: FormColumnMappingDto }>(
        `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}/column-mapping`
      )
      return res.data?.data ?? null
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) return null
      throw err
    }
  },

  create: async (
    formId: number,
    sheetId: number,
    columnId: number,
    body: CreateFormColumnMappingRequest
  ): Promise<FormColumnMappingDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormColumnMappingDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}/column-mapping`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo column mapping thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    columnId: number,
    body: UpdateFormColumnMappingRequest
  ): Promise<FormColumnMappingDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormColumnMappingDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}/column-mapping`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật column mapping thất bại')
    return res.data.data
  },

  delete: async (
    formId: number,
    sheetId: number,
    columnId: number
  ): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/columns/${columnId}/column-mapping`
    )
  },
}

/** FormRowFormulaScope – chọn cột áp dụng row formula */
export const formRowFormulaScopeApi = {
  getList: async (formId: number, sheetId: number, rowId: number): Promise<FormRowFormulaScopeDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormRowFormulaScopeDto[] }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/rows/${rowId}/formula-scope`
    )
    return res.data?.data ?? []
  },

  create: async (
    formId: number,
    sheetId: number,
    rowId: number,
    body: CreateFormRowFormulaScopeRequest
  ): Promise<FormRowFormulaScopeDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormRowFormulaScopeDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/rows/${rowId}/formula-scope`,
      body
    )
    if (!res.data?.data) throw new Error('Thêm scope công thức thất bại')
    return res.data.data
  },

  delete: async (formId: number, sheetId: number, rowId: number, id: number): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/rows/${rowId}/formula-scope/${id}`
    )
  },
}

/** FormCellFormula – override formula/IsEditable cấp cell */
export const formCellFormulaApi = {
  getList: async (formId: number, sheetId: number): Promise<FormCellFormulaDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormCellFormulaDto[] }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/cell-formulas`
    )
    return res.data?.data ?? []
  },

  upsert: async (
    formId: number,
    sheetId: number,
    body: CreateFormCellFormulaRequest
  ): Promise<FormCellFormulaDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormCellFormulaDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/cell-formulas`,
      body
    )
    if (!res.data?.data) throw new Error('Lưu cell formula thất bại')
    return res.data.data
  },

  delete: async (formId: number, sheetId: number, id: number): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/cell-formulas/${id}`
    )
  },
}

/** Dynamic Regions (B12 – vùng chỉ tiêu động) */
export const formDynamicRegionsApi = {
  getList: async (formId: number, sheetId: number): Promise<FormDynamicRegionDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormDynamicRegionDto[] }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-regions`
    )
    return res.data?.data ?? []
  },

  create: async (
    formId: number,
    sheetId: number,
    body: CreateFormDynamicRegionRequest
  ): Promise<FormDynamicRegionDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormDynamicRegionDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-regions`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo vùng chỉ tiêu động thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    regionId: number,
    body: UpdateFormDynamicRegionRequest
  ): Promise<FormDynamicRegionDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormDynamicRegionDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-regions/${regionId}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật vùng chỉ tiêu động thất bại')
    return res.data.data
  },

  delete: async (formId: number, sheetId: number, regionId: number): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-regions/${regionId}`
    )
  },
}
