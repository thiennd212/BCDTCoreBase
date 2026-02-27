/**
 * API client cho Danh mục chỉ tiêu (IndicatorCatalog) và Chỉ tiêu (Indicator).
 * - Danh mục chỉ tiêu: CRUD /api/v1/indicator-catalogs
 * - Chỉ tiêu: CRUD /api/v1/indicator-catalogs/{catalogId}/indicators (hỗ trợ tree)
 */
import axios from 'axios'
import { apiClient } from './apiClient'
import type {
  IndicatorCatalogDto,
  CreateIndicatorCatalogRequest,
  UpdateIndicatorCatalogRequest,
  IndicatorDto,
  CreateIndicatorRequest,
  UpdateIndicatorRequest,
} from '../types/form.types'

// ─── Danh mục chỉ tiêu ─────────────────────────────────────────

export const indicatorCatalogsApi = {
  getList: async (includeInactive = false): Promise<IndicatorCatalogDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: IndicatorCatalogDto[] }>(
      '/api/v1/indicator-catalogs',
      { params: { includeInactive } }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<IndicatorCatalogDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: IndicatorCatalogDto }>(
        `/api/v1/indicator-catalogs/${id}`
      )
      return res.data?.data ?? null
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) return null
      throw err
    }
  },

  create: async (body: CreateIndicatorCatalogRequest): Promise<IndicatorCatalogDto> => {
    const res = await apiClient.post<{ success: boolean; data: IndicatorCatalogDto }>(
      '/api/v1/indicator-catalogs',
      body
    )
    if (!res.data?.data) throw new Error('Tạo danh mục chỉ tiêu thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateIndicatorCatalogRequest): Promise<IndicatorCatalogDto> => {
    const res = await apiClient.put<{ success: boolean; data: IndicatorCatalogDto }>(
      `/api/v1/indicator-catalogs/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật danh mục chỉ tiêu thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/indicator-catalogs/${id}`)
  },
}

// ─── Chỉ tiêu (theo danh mục) ──────────────────────────────────

export const indicatorsApi = {
  getList: async (catalogId: number, tree = false): Promise<IndicatorDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: IndicatorDto[] }>(
      `/api/v1/indicator-catalogs/${catalogId}/indicators`,
      { params: { tree } }
    )
    return res.data?.data ?? []
  },

  getById: async (catalogId: number, id: number): Promise<IndicatorDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: IndicatorDto }>(
        `/api/v1/indicator-catalogs/${catalogId}/indicators/${id}`
      )
      return res.data?.data ?? null
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) return null
      throw err
    }
  },

  create: async (catalogId: number, body: CreateIndicatorRequest): Promise<IndicatorDto> => {
    const res = await apiClient.post<{ success: boolean; data: IndicatorDto }>(
      `/api/v1/indicator-catalogs/${catalogId}/indicators`,
      body
    )
    if (!res.data?.data) throw new Error('Tạo chỉ tiêu thất bại')
    return res.data.data
  },

  update: async (
    catalogId: number,
    id: number,
    body: UpdateIndicatorRequest
  ): Promise<IndicatorDto> => {
    const res = await apiClient.put<{ success: boolean; data: IndicatorDto }>(
      `/api/v1/indicator-catalogs/${catalogId}/indicators/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật chỉ tiêu thất bại')
    return res.data.data
  },

  delete: async (catalogId: number, id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/indicator-catalogs/${catalogId}/indicators/${id}`)
  },
}

// ─── Chỉ tiêu tra cứu toàn cục (theo Code, Phase 2b: _SPECIAL_GENERIC) ───

export const indicatorsByCodeApi = {
  getByCode: async (code: string): Promise<IndicatorDto | null> => {
    try {
      const res = await apiClient.get<{ success: boolean; data: IndicatorDto }>(
        `/api/v1/indicators/by-code/${encodeURIComponent(code)}`
      )
      return res.data?.data ?? null
    } catch (err: unknown) {
      if (axios.isAxiosError(err) && err.response?.status === 404) return null
      throw err
    }
  },
}
