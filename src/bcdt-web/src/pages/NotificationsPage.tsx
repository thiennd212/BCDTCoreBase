import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card,
  Typography,
  List,
  Tag,
  Button,
  Space,
  Empty,
  Segmented,
  message,
} from 'antd'
import {
  CheckOutlined,
  CheckCircleOutlined,
  CloseOutlined,
} from '@ant-design/icons'
import { useState } from 'react'
import { notificationsApi } from '../api/notificationsApi'
import type { NotificationDto } from '../types/notification.types'

const priorityColor: Record<string, string> = {
  Low: 'default',
  Normal: 'blue',
  High: 'orange',
  Urgent: 'red',
}

const typeLabel: Record<string, string> = {
  Deadline: 'Hạn nộp',
  Approval: 'Phê duyệt',
  Rejection: 'Từ chối',
  Reminder: 'Nhắc nhở',
  Revision: 'Yêu cầu chỉnh sửa',
  System: 'Hệ thống',
}

export function NotificationsPage() {
  const queryClient = useQueryClient()
  const [filter, setFilter] = useState<'all' | 'unread'>('all')

  const { data: notifications = [], isLoading } = useQuery({
    queryKey: ['notifications', filter],
    queryFn: () => notificationsApi.getList({ unreadOnly: filter === 'unread' }),
  })

  const markReadMutation = useMutation({
    mutationFn: notificationsApi.markRead,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
      queryClient.invalidateQueries({ queryKey: ['notifications-count'] })
    },
  })

  const markAllReadMutation = useMutation({
    mutationFn: notificationsApi.markAllRead,
    onSuccess: () => {
      message.success('Đã đánh dấu tất cả đã đọc')
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
      queryClient.invalidateQueries({ queryKey: ['notifications-count'] })
    },
  })

  const dismissMutation = useMutation({
    mutationFn: notificationsApi.dismiss,
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['notifications'] })
      queryClient.invalidateQueries({ queryKey: ['notifications-count'] })
    },
  })

  const formatDate = (dateStr: string) => {
    const d = new Date(dateStr)
    return d.toLocaleDateString('vi-VN', {
      day: '2-digit',
      month: '2-digit',
      year: 'numeric',
      hour: '2-digit',
      minute: '2-digit',
    })
  }

  return (
    <>
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Thông báo
      </Typography.Title>
      <Card>
        <Space style={{ marginBottom: 16, width: '100%', justifyContent: 'space-between' }} align="center">
          <Segmented
            options={[
              { value: 'all', label: 'Tất cả' },
              { value: 'unread', label: 'Chưa đọc' },
            ]}
            value={filter}
            onChange={(v) => setFilter(v as 'all' | 'unread')}
          />
          <Button
            icon={<CheckCircleOutlined />}
            onClick={() => markAllReadMutation.mutate()}
            loading={markAllReadMutation.isPending}
          >
            Đánh dấu tất cả đã đọc
          </Button>
        </Space>

        {notifications.length === 0 && !isLoading ? (
          <Empty description="Không có thông báo nào" />
        ) : (
          <List
            loading={isLoading}
            itemLayout="horizontal"
            dataSource={notifications}
            renderItem={(item: NotificationDto) => (
              <List.Item
                style={{
                  background: item.isRead ? undefined : '#f0f5ff',
                  padding: '12px 16px',
                  borderRadius: 6,
                  marginBottom: 4,
                }}
                actions={[
                  !item.isRead && (
                    <Button
                      key="read"
                      size="small"
                      type="text"
                      icon={<CheckOutlined />}
                      onClick={() => markReadMutation.mutate(item.id)}
                      title="Đánh dấu đã đọc"
                    />
                  ),
                  <Button
                    key="dismiss"
                    size="small"
                    type="text"
                    danger
                    icon={<CloseOutlined />}
                    onClick={() => dismissMutation.mutate(item.id)}
                    title="Ẩn"
                  />,
                ].filter(Boolean)}
              >
                <List.Item.Meta
                  title={
                    <Space size={8}>
                      <Tag color={priorityColor[item.priority] ?? 'default'}>{item.priority}</Tag>
                      <Tag>{typeLabel[item.type] ?? item.type}</Tag>
                      <Typography.Text strong={!item.isRead}>{item.title}</Typography.Text>
                    </Space>
                  }
                  description={
                    <>
                      <Typography.Paragraph
                        style={{ marginBottom: 4 }}
                        ellipsis={{ rows: 2 }}
                      >
                        {item.message}
                      </Typography.Paragraph>
                      <Typography.Text type="secondary" style={{ fontSize: 12 }}>
                        {formatDate(item.createdAt)}
                      </Typography.Text>
                    </>
                  }
                />
              </List.Item>
            )}
          />
        )}
      </Card>
    </>
  )
}
