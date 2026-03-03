import { Empty, Button } from 'antd'
import { PlusOutlined } from '@ant-design/icons'

interface Props {
  description?: string
  /** Label nút hành động (hiện khi có cả actionLabel + onAction) */
  actionLabel?: string
  onAction?: () => void
  /** Dùng ảnh nhỏ (phù hợp trong card nhỏ). Mặc định: false */
  compact?: boolean
}

/** Empty state chuẩn BCDT – dùng thay thế cho `Empty` rải rác trong các trang. */
export function EmptyState({ description = 'Không có dữ liệu', actionLabel, onAction, compact }: Props) {
  return (
    <Empty
      description={description}
      image={compact ? Empty.PRESENTED_IMAGE_SIMPLE : undefined}
      style={{ padding: compact ? '16px 0' : '32px 0' }}
    >
      {actionLabel && onAction && (
        <Button type="primary" icon={<PlusOutlined />} onClick={onAction}>
          {actionLabel}
        </Button>
      )}
    </Empty>
  )
}
