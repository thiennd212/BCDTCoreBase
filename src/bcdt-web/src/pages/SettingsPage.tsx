import { Card, Typography, Form, Switch, Select, Space, Button, message } from 'antd'
import { SaveOutlined } from '@ant-design/icons'

const { Title, Text } = Typography

export function SettingsPage() {
  const [form] = Form.useForm()

  const handleSave = () => {
    message.success('Đã lưu cài đặt')
  }

  return (
    <>
      <Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Cài đặt
      </Title>

      <div style={{ display: 'flex', flexDirection: 'column', gap: 16 }}>
        {/* Display Settings */}
        <Card title="Hiển thị">
          <Form form={form} layout="vertical">
            <Form.Item 
              name="language" 
              label="Ngôn ngữ"
              initialValue="vi"
            >
              <Select
                options={[
                  { label: 'Tiếng Việt', value: 'vi' },
                  { label: 'English', value: 'en' },
                ]}
                style={{ width: 200 }}
              />
            </Form.Item>

            <Form.Item 
              name="pageSize" 
              label="Số dòng mỗi trang"
              initialValue={20}
            >
              <Select
                options={[
                  { label: '10 dòng', value: 10 },
                  { label: '20 dòng', value: 20 },
                  { label: '50 dòng', value: 50 },
                  { label: '100 dòng', value: 100 },
                ]}
                style={{ width: 200 }}
              />
            </Form.Item>
          </Form>
        </Card>

        {/* Notification Settings */}
        <Card title="Thông báo">
          <Form layout="vertical">
            <Form.Item 
              name="emailNotification" 
              valuePropName="checked"
              initialValue={true}
            >
              <Space>
                <Switch defaultChecked />
                <div>
                  <Text>Thông báo qua email</Text>
                  <br />
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    Nhận thông báo về báo cáo, phê duyệt qua email
                  </Text>
                </div>
              </Space>
            </Form.Item>

            <Form.Item 
              name="browserNotification" 
              valuePropName="checked"
              initialValue={true}
            >
              <Space>
                <Switch defaultChecked />
                <div>
                  <Text>Thông báo trên trình duyệt</Text>
                  <br />
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    Hiển thị thông báo trên trình duyệt khi có cập nhật
                  </Text>
                </div>
              </Space>
            </Form.Item>

            <Form.Item 
              name="reminderNotification" 
              valuePropName="checked"
              initialValue={true}
            >
              <Space>
                <Switch defaultChecked />
                <div>
                  <Text>Nhắc nhở hạn nộp</Text>
                  <br />
                  <Text type="secondary" style={{ fontSize: 12 }}>
                    Nhận thông báo nhắc nhở trước hạn nộp báo cáo
                  </Text>
                </div>
              </Space>
            </Form.Item>
          </Form>
        </Card>

        {/* Save Button */}
        <div>
          <Button type="primary" icon={<SaveOutlined />} onClick={handleSave}>
            Lưu cài đặt
          </Button>
        </div>
      </div>
    </>
  )
}
