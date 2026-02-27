import React from 'react'
import { Spin, Flex, Typography } from 'antd'
import { LoadingOutlined } from '@ant-design/icons'

const { Text } = Typography

type PageLoadingProps = {
  /** Text hiển thị dưới spinner. Mặc định: "Đang tải dữ liệu..." */
  tip?: string
  /** Có dùng full viewport (100vh) hay chỉ vùng nội dung. Mặc định: true */
  fullScreen?: boolean
}

const defaultTip = 'Đang tải dữ liệu...'

/**
 * Màn hình loading toàn trang: spinner + text, căn giữa, nền nhẹ.
 * Dùng khi kiểm tra auth, chuyển route, hoặc tải dữ liệu khởi tạo.
 */
export function PageLoading({ tip = defaultTip, fullScreen = true }: PageLoadingProps) {
  const containerStyle: React.CSSProperties = fullScreen
    ? {
        minHeight: '100vh',
        width: '100%',
        background: 'linear-gradient(180deg, #f8fafc 0%, #f1f5f9 100%)',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }
    : {
        minHeight: 280,
        width: '100%',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'center',
      }

  return (
    <Flex style={containerStyle} vertical align="center" gap="middle">
      <Spin
        size="large"
        indicator={<LoadingOutlined style={{ fontSize: 40, color: '#1668dc' }} spin />}
      />
      <Text type="secondary" style={{ fontSize: 15, marginTop: 8 }}>
        {tip}
      </Text>
    </Flex>
  )
}
