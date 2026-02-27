import { apiClient } from './apiClient'
import type { MenuDto, CreateMenuRequest, UpdateMenuRequest } from '../types/menu.types'

export const menusApi = {
  /** Lấy danh sách menu (tree hoặc flat). roleId: chỉ menu được gán cho vai trò đó. */
  getAll: async (params?: { all?: boolean; roleId?: number }): Promise<MenuDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: MenuDto[] }>('/api/v1/menus', { params })
    return res.data?.data ?? []
  },

  /** Lấy chi tiết menu theo Id */
  getById: async (id: number): Promise<MenuDto | null> => {
    const res = await apiClient.get<{ success: boolean; data: MenuDto }>(`/api/v1/menus/${id}`)
    return res.data?.data ?? null
  },

  /** Tạo menu mới */
  create: async (body: CreateMenuRequest): Promise<MenuDto> => {
    const res = await apiClient.post<{ success: boolean; data: MenuDto }>('/api/v1/menus', body)
    return res.data.data
  },

  /** Cập nhật menu */
  update: async (id: number, body: UpdateMenuRequest): Promise<MenuDto> => {
    const res = await apiClient.put<{ success: boolean; data: MenuDto }>(`/api/v1/menus/${id}`, body)
    return res.data.data
  },

  /** Xóa menu */
  delete: async (id: number): Promise<void> => {
    await apiClient.delete(`/api/v1/menus/${id}`)
  },
}
