import { useState } from 'react'
import { Card, Typography, Form, Input, Button, message, Descriptions, Avatar, Space } from 'antd'
import { UserOutlined, SaveOutlined } from '@ant-design/icons'
import { useMutation } from '@tanstack/react-query'
import { useAuth } from '../context/AuthContext'
import { getApiErrorMessage } from '../api/apiClient'
import { authApi } from '../api/authApi'

const { Title, Text } = Typography

interface ChangePasswordValues {
  currentPassword: string
  newPassword: string
  confirmPassword: string
}

export function ProfilePage() {
  const { user } = useAuth()
  const [passwordForm] = Form.useForm<ChangePasswordValues>()
  const [isChangingPassword, setIsChangingPassword] = useState(false)

  const changePasswordMutation = useMutation({
    mutationFn: async (values: ChangePasswordValues) => {
      await authApi.changePassword(values.currentPassword, values.newPassword)
    },
    onSuccess: () => {
      message.success('Đổi mật khẩu thành công')
      passwordForm.resetFields()
      setIsChangingPassword(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Đổi mật khẩu thất bại'),
  })

  const handleChangePassword = async () => {
    const values = await passwordForm.validateFields()
    changePasswordMutation.mutate(values)
  }

  return (
    <>
      <Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Thông tin tài khoản
      </Title>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        {/* User Info Card */}
        <Card>
          <Space size="large" align="start">
            <Avatar size={80} icon={<UserOutlined />} style={{ backgroundColor: 'var(--ant-color-primary)' }} />
            <div>
              <Title level={4} style={{ margin: 0 }}>{user?.fullName || user?.username}</Title>
              <Text type="secondary">{user?.email}</Text>
              <Descriptions column={1} style={{ marginTop: 16 }} size="small">
                <Descriptions.Item label="Tên đăng nhập">{user?.username}</Descriptions.Item>
                <Descriptions.Item label="Email">{user?.email || '-'}</Descriptions.Item>
                <Descriptions.Item label="Trạng thái">
                  <Text type={user?.isActive ? 'success' : 'danger'}>
                    {user?.isActive ? 'Đang hoạt động' : 'Ngừng hoạt động'}
                  </Text>
                </Descriptions.Item>
              </Descriptions>
            </div>
          </Space>
        </Card>

        {/* Change Password Card */}
        <Card 
          title="Đổi mật khẩu" 
          extra={
            !isChangingPassword && (
              <Button type="link" onClick={() => setIsChangingPassword(true)}>
                Đổi mật khẩu
              </Button>
            )
          }
        >
          {isChangingPassword ? (
            <Form form={passwordForm} layout="vertical" style={{ maxWidth: 400 }}>
              <Form.Item
                name="currentPassword"
                label="Mật khẩu hiện tại"
                rules={[{ required: true, message: 'Nhập mật khẩu hiện tại' }]}
              >
                <Input.Password placeholder="Mật khẩu hiện tại" />
              </Form.Item>
              <Form.Item
                name="newPassword"
                label="Mật khẩu mới"
                rules={[
                  { required: true, message: 'Nhập mật khẩu mới' },
                  { min: 6, message: 'Mật khẩu tối thiểu 6 ký tự' },
                ]}
              >
                <Input.Password placeholder="Mật khẩu mới" />
              </Form.Item>
              <Form.Item
                name="confirmPassword"
                label="Xác nhận mật khẩu mới"
                dependencies={['newPassword']}
                rules={[
                  { required: true, message: 'Xác nhận mật khẩu mới' },
                  ({ getFieldValue }) => ({
                    validator(_, value) {
                      if (!value || getFieldValue('newPassword') === value) {
                        return Promise.resolve()
                      }
                      return Promise.reject(new Error('Mật khẩu xác nhận không khớp'))
                    },
                  }),
                ]}
              >
                <Input.Password placeholder="Xác nhận mật khẩu mới" />
              </Form.Item>
              <Form.Item>
                <Space>
                  <Button 
                    type="primary" 
                    icon={<SaveOutlined />}
                    onClick={handleChangePassword}
                    loading={changePasswordMutation.isPending}
                  >
                    Lưu
                  </Button>
                  <Button onClick={() => {
                    setIsChangingPassword(false)
                    passwordForm.resetFields()
                  }}>
                    Hủy
                  </Button>
                </Space>
              </Form.Item>
            </Form>
          ) : (
            <Text type="secondary">Nhấn "Đổi mật khẩu" để thay đổi mật khẩu của bạn.</Text>
          )}
        </Card>
      </div>
    </>
  )
}
