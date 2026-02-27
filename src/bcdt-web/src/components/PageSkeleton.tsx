import { Card, Skeleton } from 'antd'

interface Props {
  rows?: number
  /** Hiện skeleton title (mặc định: true) */
  title?: boolean
  /** Tiêu đề card (optional) */
  cardTitle?: string
}

/** Skeleton chuẩn cho trang đang tải dữ liệu (thay thế loading indicator trắng trơn). */
export function PageSkeleton({ rows = 5, title = true, cardTitle }: Props) {
  return (
    <Card title={cardTitle} style={{ marginTop: 8 }}>
      {title && (
        <Skeleton.Input active style={{ width: 240, marginBottom: 20, display: 'block' }} />
      )}
      <Skeleton active paragraph={{ rows }} />
    </Card>
  )
}

/** Skeleton nhỏ cho widget/card trong dashboard. */
export function CardSkeleton({ rows = 3 }: { rows?: number }) {
  return <Skeleton active paragraph={{ rows }} />
}
