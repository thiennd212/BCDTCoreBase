import { Result, Button } from 'antd'
import { useNavigate } from 'react-router-dom'

export type ErrorPageType = '404' | '403' | '500' | 'network'

interface Props {
  type?: ErrorPageType
  title?: string
  message?: string
}

const CONFIGS: Record<ErrorPageType, { status: '404' | '403' | '500'; title: string; subTitle: string }> = {
  '404': {
    status: '404',
    title: 'Không tìm thấy',
    subTitle: 'Trang hoặc dữ liệu bạn tìm kiếm không tồn tại.',
  },
  '403': {
    status: '403',
    title: 'Không có quyền truy cập',
    subTitle: 'Bạn không có quyền xem nội dung này.',
  },
  '500': {
    status: '500',
    title: 'Lỗi máy chủ',
    subTitle: 'Hệ thống đang gặp sự cố. Vui lòng thử lại sau.',
  },
  'network': {
    status: '500',
    title: 'Mất kết nối',
    subTitle: 'Không kết nối được đến máy chủ. Kiểm tra kết nối mạng và thử lại.',
  },
}

export function ErrorPage({ type = '500', title, message }: Props) {
  const navigate = useNavigate()
  const config = CONFIGS[type]

  return (
    <Result
      status={config.status}
      title={title ?? config.title}
      subTitle={message ?? config.subTitle}
      extra={[
        <Button key="back" onClick={() => navigate(-1)}>
          Quay lại
        </Button>,
        <Button key="home" type="primary" onClick={() => navigate('/dashboard')}>
          Trang chủ
        </Button>,
      ]}
    />
  )
}

/** Hiển thị lỗi query inline (thay thế Text type="danger" trong các trang). */
export function QueryErrorDisplay({ error }: { error: unknown }) {
  const err = error as { status?: number; message?: string } | null
  if (!err) return null

  if (err.status === 404) return <ErrorPage type="404" />
  if (err.status === 403) return <ErrorPage type="403" />
  if (err.status !== undefined && err.status >= 500) return <ErrorPage type="500" />
  if ((err as { code?: string }).code === 'ERR_NETWORK' || err.message === 'Không kết nối được máy chủ.')
    return <ErrorPage type="network" />

  return <ErrorPage type="500" message={err.message} />
}
