import { useState } from 'react'
import { useNavigate, useLocation } from 'react-router-dom'
import { Form, Input, Button, Card, Typography } from 'antd'
import { AppstoreOutlined } from '@ant-design/icons'
import { useAuth } from '../context/AuthContext'

const { Title, Text } = Typography

export function LoginPage() {
  const [error, setError] = useState('')
  const [loading, setLoading] = useState(false)
  const { login, isAuthenticated } = useAuth()
  const navigate = useNavigate()
  const location = useLocation()
  const from = (location.state as { from?: { pathname: string } })?.from?.pathname || '/organizations'

  if (isAuthenticated) {
    navigate(from, { replace: true })
    return null
  }

  const handleSubmit = async (values: { username: string; password: string }) => {
    setError('')
    setLoading(true)
    try {
      await login(values.username, values.password)
      navigate(from, { replace: true })
    } catch (err: unknown) {
      setError(err instanceof Error ? err.message : 'Đăng nhập thất bại')
    } finally {
      setLoading(false)
    }
  }

  return (
    <div className="login-wrap">
      <div className="login-card-wrap">
        <Card className="login-card">
          <div className="login-brand">
            <AppstoreOutlined className="login-brand-icon" />
            <Title level={2} style={{ margin: 0 }}>
              BCDT
            </Title>
            <Text type="secondary">Hệ thống báo cáo</Text>
          </div>
          <Form
            name="login"
            onFinish={handleSubmit}
            layout="vertical"
            autoComplete="off"
            size="large"
          >
            <Form.Item
              label="Tên đăng nhập"
              name="username"
              rules={[{ required: true, message: 'Nhập tên đăng nhập' }]}
            >
              <Input placeholder="Tên đăng nhập" disabled={loading} />
            </Form.Item>
            <Form.Item
              label="Mật khẩu"
              name="password"
              rules={[{ required: true, message: 'Nhập mật khẩu' }]}
            >
              <Input.Password placeholder="Mật khẩu" disabled={loading} />
            </Form.Item>
            {error && (
              <div className="login-error">
                <Text type="danger">{error}</Text>
              </div>
            )}
            <Form.Item style={{ marginBottom: 0 }}>
              <Button type="primary" htmlType="submit" loading={loading} block size="large">
                Đăng nhập
              </Button>
            </Form.Item>
          </Form>
        </Card>
      </div>
    </div>
  )
}
