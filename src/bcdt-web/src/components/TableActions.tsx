import React from 'react'
import { Button, Space, Tooltip, Popconfirm } from 'antd'

export interface TableActionItem {
  key: string
  label: string
  icon?: React.ReactNode
  onClick: () => void
  danger?: boolean
  /** Nếu có, bọc nút bằng Popconfirm trước khi gọi onClick. */
  confirm?: {
    title: string
    description?: string
    okText?: string
    cancelText?: string
  }
}

export interface TableActionsProps {
  items: TableActionItem[]
  /** Căn nhóm nút (mặc định 'right' cho cột thao tác). */
  align?: 'left' | 'center' | 'right'
}

/**
 * Nhóm thao tác cho cột "Thao tác" trong bảng: icon + tooltip, có thể kèm Popconfirm.
 * Dùng chuẩn 1 (icon + tooltip) để cột gọn, không tràn chữ.
 */
export function TableActions({ items, align = 'right' }: TableActionsProps) {
  const justifyContent = align === 'right' ? 'flex-end' : align === 'center' ? 'center' : 'flex-start'

  return (
    <Space
      size="small"
      wrap={false}
      style={{
        justifyContent,
        flexWrap: 'nowrap',
        width: align === 'right' ? '100%' : undefined,
        display: 'flex',
      }}
    >
      {items.map((item) => {
        const btn = (
          <Button
            type="link"
            size="small"
            danger={item.danger}
            icon={item.icon}
            onClick={item.confirm ? undefined : item.onClick}
          >
            {item.icon ? null : item.label}
          </Button>
        )

        if (item.confirm) {
          return (
            <Popconfirm
              key={item.key}
              title={item.confirm.title}
              description={item.confirm.description}
              onConfirm={item.onClick}
              okText={item.confirm.okText ?? 'Xóa'}
              cancelText={item.confirm.cancelText ?? 'Hủy'}
            >
              <Tooltip title={item.label}>
                <span>{btn}</span>
              </Tooltip>
            </Popconfirm>
          )
        }

        return (
          <Tooltip key={item.key} title={item.label}>
            {btn}
          </Tooltip>
        )
      })}
    </Space>
  )
}
