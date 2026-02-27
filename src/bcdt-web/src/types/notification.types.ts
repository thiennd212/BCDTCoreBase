export interface NotificationDto {
  id: number
  userId: number
  type: string
  title: string
  message: string
  priority: string
  entityType?: string
  entityId?: string
  actionUrl?: string
  channels: string
  isRead: boolean
  readAt?: string
  createdAt: string
  expiresAt?: string
}
