import { apiClient } from './apiClient'
import type { NotificationDto } from '../types/notification.types'

export const notificationsApi = {
  getList: async (params?: { unreadOnly?: boolean }): Promise<NotificationDto[]> => {
    const res = await apiClient.get<{ success: boolean; data: NotificationDto[] }>(
      '/api/v1/notifications',
      { params }
    )
    return res.data?.data ?? []
  },

  getUnreadCount: async (): Promise<number> => {
    const res = await apiClient.get<{ success: boolean; data: number }>(
      '/api/v1/notifications/unread-count'
    )
    return res.data?.data ?? 0
  },

  markRead: async (id: number): Promise<void> => {
    await apiClient.patch(`/api/v1/notifications/${id}/read`)
  },

  markAllRead: async (): Promise<void> => {
    await apiClient.patch('/api/v1/notifications/read-all')
  },

  dismiss: async (id: number): Promise<void> => {
    await apiClient.patch(`/api/v1/notifications/${id}/dismiss`)
  },
}
