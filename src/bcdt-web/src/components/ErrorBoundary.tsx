import React from 'react'
import { Button, Result } from 'antd'

interface Props {
  children: React.ReactNode
}

interface State {
  hasError: boolean
  error?: Error
}

export class ErrorBoundary extends React.Component<Props, State> {
  constructor(props: Props) {
    super(props)
    this.state = { hasError: false }
  }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error) {
    console.error('[ErrorBoundary]', error)
  }

  render() {
    if (this.state.hasError) {
      return (
        <div style={{ padding: 40 }}>
          <Result
            status="500"
            title="Đã xảy ra lỗi"
            subTitle={this.state.error?.message || 'Ứng dụng gặp sự cố không mong muốn. Vui lòng tải lại trang.'}
            extra={
              <Button
                type="primary"
                onClick={() => {
                  this.setState({ hasError: false })
                  window.location.reload()
                }}
              >
                Tải lại trang
              </Button>
            }
          />
        </div>
      )
    }
    return this.props.children
  }
}
