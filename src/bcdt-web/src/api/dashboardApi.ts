import { apiClient } from './apiClient'
import type { DashboardAdminStatsDto, DashboardUserTasksDto } from '../types/dashboard.types'

export const dashboardApi = {
  getAdminStats: async (periodId?: number | null): Promise<DashboardAdminStatsDto> => {
    const res = await apiClient.get<{ success: boolean; data: DashboardAdminStatsDto }>(
      '/api/v1/dashboard/admin/stats',
      { params: periodId != null ? { periodId } : undefined }
    )
    if (!res.data?.data) throw new Error('Lấy thống kê thất bại')
    return res.data.data
  },

  getUserTasks: async (): Promise<DashboardUserTasksDto> => {
    const res = await apiClient.get<{ success: boolean; data: DashboardUserTasksDto }>(
      '/api/v1/dashboard/user/tasks'
    )
    if (!res.data?.data) throw new Error('Lấy nhiệm vụ thất bại')
    return res.data.data
  },
}
