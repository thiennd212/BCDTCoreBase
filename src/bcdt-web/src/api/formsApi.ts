import { apiClient } from './apiClient'
import type {
  FormDefinitionDto,
  FormVersionDto,
  CreateFormDefinitionRequest,
  UpdateFormDefinitionRequest,
} from '../types/form.types'

export const formsApi = {
  getList: async (params?: { includeInactive?: boolean; status?: string; formType?: string }): Promise<FormDefinitionDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormDefinitionDto[] }>(
      '/api/v1/forms',
      { params }
    )
    return res.data?.data ?? []
  },

  getById: async (id: number): Promise<FormDefinitionDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: FormDefinitionDto }>(
      `/api/v1/forms/${id}`
    )
    return res.data?.data ?? null
  },

  getVersions: async (id: number): Promise<FormVersionDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: FormVersionDto[] }>(
      `/api/v1/forms/${id}/versions`
    )
    return res.data?.data ?? []
  },

  create: async (body: CreateFormDefinitionRequest): Promise<FormDefinitionDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormDefinitionDto }>(
      '/api/v1/forms',
      body
    )
    if (!res.data?.data) throw new Error('Tạo biểu mẫu thất bại')
    return res.data.data
  },

  update: async (id: number, body: UpdateFormDefinitionRequest): Promise<FormDefinitionDto> => {
    const res = await apiClient.put<{ success: boolean; data: FormDefinitionDto }>(
      `/api/v1/forms/${id}`,
      body
    )
    if (!res.data?.data) throw new Error('Cập nhật biểu mẫu thất bại')
    return res.data.data
  },

  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/forms/${id}`)
  },

  /** Tải file template Excel (.xlsx) của biểu mẫu. */
  downloadTemplate: async (formId: number, fileName?: string): Promise<void> => {
    const res = await apiClient.get(`/api/v1/forms/${formId}/template`, {
      responseType: 'blob',
    })
    const blob = new Blob([res.data as BlobPart], {
      type: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    })
    const url = window.URL.createObjectURL(blob)
    const a = document.createElement('a')
    a.href = url
    a.download = fileName || `form_${formId}_template.xlsx`
    document.body.appendChild(a)
    a.click()
    window.URL.revokeObjectURL(url)
    document.body.removeChild(a)
  },

  /** Lấy template display (JSON Fortune-sheet) để dùng làm base hiển thị nhập liệu. Trả về null nếu 204. */
  getTemplateDisplay: async (formId: number): Promise<unknown | null> => {
    const res = await apiClient.get<string>(`/api/v1/forms/${formId}/template-display`, {
      validateStatus: (s) => s === 200 || s === 204,
    })
    if (res.status === 204 || res.data == null || res.data === '') return null
    const raw = typeof res.data === 'string' ? res.data : JSON.stringify(res.data)
    return JSON.parse(raw) as unknown
  },

  /** Tạo biểu mẫu từ file template Excel (trích xuất sheet, cột, format từ template). */
  createFromTemplate: async (
    file: File,
    name: string,
    code?: string
  ): Promise<FormDefinitionDto> => {
    const formData = new FormData()
    formData.append('file', file)
    formData.append('name', name)
    if (code?.trim()) formData.append('code', code.trim())
    const res = await apiClient.post<{ success: boolean; data: FormDefinitionDto }>(
      '/api/v1/forms/from-template',
      formData,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    )
    if (!res.data?.data) throw new Error('Tạo biểu mẫu từ template thất bại')
    return res.data.data
  },

  /** Nhân bản biểu mẫu: tạo bản sao hoàn chỉnh (versions, sheets, columns, rows) với code và tên mới. */
  clone: async (id: number, body: { newCode: string; newName: string }): Promise<FormDefinitionDto> => {
    const res = await apiClient.post<{ success: boolean; data: FormDefinitionDto }>(
      `/api/v1/forms/${id}/clone`,
      body
    )
    if (!res.data?.data) throw new Error('Nhân bản biểu mẫu thất bại')
    return res.data.data
  },

  /** Upload file Excel template. */
  uploadTemplate: async (formId: number, file: File): Promise<{ formId: number; fileName: string; hasDisplay: boolean }> => {
    const formData = new FormData()
    formData.append('file', file)
    const res = await apiClient.post<{ success: boolean; data: { formId: number; fileName: string; hasDisplay: boolean } }>(
      `/api/v1/forms/${formId}/template`,
      formData,
      { headers: { 'Content-Type': 'multipart/form-data' } }
    )
    if (!res.data?.data) throw new Error('Upload template thất bại')
    return res.data.data
  },
}
