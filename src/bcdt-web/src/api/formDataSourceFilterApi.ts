/**
 * API client cho tính năng "Lọc động theo trường" trong cấu hình biểu mẫu:
 * - Nguồn dữ liệu (DataSource): bảng/view/catalog cung cấp dữ liệu cho vùng động
 * - Bộ lọc (FilterDefinition): điều kiện lọc theo trường (Field, Operator, Value)
 * - Vị trí placeholder (FormPlaceholderOccurrence): vị trí trên sheet gắn nguồn + bộ lọc → mở rộng N hàng khi build workbook
 *
 * Dùng trong FormConfigPage: card "Nguồn dữ liệu", "Bộ lọc", "Vị trí placeholder".
 */
import axios from 'axios'
import { apiClient } from './apiClient'
import type {
  DataSourceDto,
  CreateDataSourceRequest,
  UpdateDataSourceRequest,
  DataSourceColumnDto,
  FilterDefinitionDto,
  CreateFilterDefinitionRequest,
  UpdateFilterDefinitionRequest,
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

/** Nguồn dữ liệu (bảng/view/catalog) */
export const dataSourcesApi = {
  getList: async (): Promise<DataSourceDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: DataSourceDto[] }>(
      '/api/v1/data-sources'
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<DataSourceDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: DataSourceDto }>(
        `/api/v1/data-sources/${id}`
      )
      return res.data?.data ?? null
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) return null
      throw err
    }
  },

  getColumns: async (id: number): Promise<DataSourceColumnDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: DataSourceColumnDto[] }>(
      `/api/v1/data-sources/${id}/columns`
    )
    return res.data?.data ?? []
  },

  create: async (body: CreateDataSourceRequest): Promise<DataSourceDto> => {
    const res = await apiClient.post<{ success: boolean; data: DataSourceDto }>(
      '/api/v1/data-sources',
      body
    )
    if (!res.data?.data) throw new Error('Tạo nguồn dữ liệu thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateDataSourceRequest): Promise<DataSourceDto> => {
    const res = await apiClient.put<{ success: boolean; data: DataSourceDto }>(
      `/api/v1/data-sources/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật nguồn dữ liệu thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/data-sources/${id}`)
  },
}

/** Định nghĩa bộ lọc (điều kiện theo trường) */
export const filterDefinitionsApi = {
  getList: async (): Promise<FilterDefinitionDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FilterDefinitionDto[] }>(
      '/api/v1/filter-definitions'
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<FilterDefinitionDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: FilterDefinitionDto }>(
        `/api/v1/filter-definitions/${id}`
      )
      return res.data?.data ?? null
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) return null
      throw err
    }
  },

  create: async (body: CreateFilterDefinitionRequest): Promise<FilterDefinitionDto> => {
    const res = await apiClient.post<{ success: boolean; data: FilterDefinitionDto }>(
      '/api/v1/filter-definitions',
      body
    )
    if (!res.data?.data) throw new Error('Tạo bộ lọc thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateFilterDefinitionRequest): Promise<FilterDefinitionDto> => {
    const res = await apiClient.put<{ success: boolean; data: FilterDefinitionDto }>(
      `/api/v1/filter-definitions/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật bộ lọc thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/filter-definitions/${id}`)
  },
}

/** Vị trí placeholder (theo form/sheet – gắn vùng + bộ lọc + nguồn) */
export const formPlaceholderOccurrencesApi = {
  getList: async (formId: number, sheetId: number): Promise<FormPlaceholderOccurrenceDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormPlaceholderOccurrenceDto[] }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-occurrences`
    )
    return res.data?.data ?? []
  },

  getById: async (
    formId: number,
    sheetId: number,
    occurrenceId: number
  ): Promise<FormPlaceholderOccurrenceDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: FormPlaceholderOccurrenceDto }>(
        `/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-occurrences/${occurrenceId}`
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
    body: CreateFormPlaceholderOccurrenceRequest
  ): Promise<FormPlaceholderOccurrenceDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormPlaceholderOccurrenceDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-occurrences`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo vị trí placeholder thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    occurrenceId: number,
    body: UpdateFormPlaceholderOccurrenceRequest
  ): Promise<FormPlaceholderOccurrenceDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormPlaceholderOccurrenceDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-occurrences/${occurrenceId}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật vị trí placeholder thất bại')
    return res.data.data
  },

  delete: async (
    formId: number,
    sheetId: number,
    occurrenceId: number
  ): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-occurrences/${occurrenceId}`
    )
  },
}

/** P8e – Định nghĩa vùng cột động (theo form/sheet) */
export const formDynamicColumnRegionsApi = {
  getList: async (formId: number, sheetId: number): Promise<FormDynamicColumnRegionDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormDynamicColumnRegionDto[] }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-column-regions`
    )
    return res.data?.data ?? []
  },

  getById: async (
    formId: number,
    sheetId: number,
    regionId: number
  ): Promise<FormDynamicColumnRegionDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: FormDynamicColumnRegionDto }>(
        `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-column-regions/${regionId}`
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
    body: CreateFormDynamicColumnRegionRequest
  ): Promise<FormDynamicColumnRegionDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormDynamicColumnRegionDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-column-regions`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo vùng cột động thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    regionId: number,
    body: UpdateFormDynamicColumnRegionRequest
  ): Promise<FormDynamicColumnRegionDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormDynamicColumnRegionDto }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-column-regions/${regionId}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật vùng cột động thất bại')
    return res.data.data
  },

  delete: async (formId: number, sheetId: number, regionId: number): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/dynamic-column-regions/${regionId}`
    )
  },
}

/** P8e – Vị trí placeholder cột (theo form/sheet) */
export const formPlaceholderColumnOccurrencesApi = {
  getList: async (
    formId: number,
    sheetId: number
  ): Promise<FormPlaceholderColumnOccurrenceDto[]> => {
    const res = await apiClient.get<{
      success: boolean
      data: FormPlaceholderColumnOccurrenceDto[]
    }>(`/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-column-occurrences`)
    return res.data?.data ?? []
  },

  create: async (
    formId: number,
    sheetId: number,
    body: CreateFormPlaceholderColumnOccurrenceRequest
  ): Promise<FormPlaceholderColumnOccurrenceDto> => {
    const res = await apiClient.post<{
      success: boolean
      data: FormPlaceholderColumnOccurrenceDto
    }>(`/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-column-occurrences`, body)
    if (!res.data?.data) throw new Error('Tạo vị trí placeholder cột thất bại')
    return res.data.data
  },

  update: async (
    formId: number,
    sheetId: number,
    occurrenceId: number,
    body: UpdateFormPlaceholderColumnOccurrenceRequest
  ): Promise<FormPlaceholderColumnOccurrenceDto> => {
    const res = await apiClient.put<{
      success: boolean
      data: FormPlaceholderColumnOccurrenceDto
    }>(
      `/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-column-occurrences/${occurrenceId}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật vị trí placeholder cột thất bại')
    return res.data.data
  },

  delete: async (
    formId: number,
    sheetId: number,
    occurrenceId: number
  ): Promise<void> => {
    await apiClient.delete(
      `/api/v1/forms/${formId}/sheets/${sheetId}/placeholder-column-occurrences/${occurrenceId}`
    )
  },
}
