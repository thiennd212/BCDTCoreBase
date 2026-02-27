import { useState, useRef } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, Table, Typography, Modal, Form, Input, message, Tag } from 'antd'
import { EditOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { systemConfigApi } from '../api/systemConfigApi'
import type { SystemConfigDto, UpdateSystemConfigRequest } from '../types/systemConfig.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

export function SystemConfigPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<UpdateSystemConfigRequest>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingKey, setEditingKey] = useState<string | null>(null)
  const [editingRecord, setEditingRecord] = useState<SystemConfigDto | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: configs = [], isLoading } = useQuery({
    queryKey: ['system-config'],
    queryFn: () => systemConfigApi.getAll(),
  })

  const updateMutation = useMutation({
    mutationFn: ({ key, body }: { key: string; body: UpdateSystemConfigRequest }) =>
      systemConfigApi.update(key, body),
    onSuccess: () => {
      message.success('Cập nhật cấu hình thành công')
      queryClient.invalidateQueries({ queryKey: ['system-config'] })
      setModalOpen(false)
      setEditingKey(null)
      setEditingRecord(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const openEdit = (record: SystemConfigDto) => {
    setEditingKey(record.configKey)
    setEditingRecord(record)
    form.setFieldsValue({ configValue: record.configValue })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingKey == null) return
    updateMutation.mutate({
      key: editingKey,
      body: { configValue: values.configValue },
    })
  }

  const columns = [
    {
      title: 'Mã cấu hình',
      dataIndex: 'configKey',
      key: 'configKey',
      width: 220,
      ellipsis: true,
      render: (v: string) => <Typography.Text copyable>{v}</Typography.Text>,
    },
    {
      title: 'Giá trị',
      dataIndex: 'configValue',
      key: 'configValue',
      ellipsis: true,
      render: (v: string, r: SystemConfigDto) =>
        r.isEncrypted ? <Tag color="orange">Đã mã hóa</Tag> : (v || '—'),
    },
    {
      title: 'Kiểu dữ liệu',
      dataIndex: 'dataType',
      key: 'dataType',
      width: 100,
      render: (v: string) => <Tag>{v}</Tag>,
    },
    {
      title: 'Mô tả',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
      render: (v: string) => v || '—',
    },
    {
      title: 'Cập nhật lúc',
      dataIndex: 'updatedAt',
      key: 'updatedAt',
      width: 160,
      render: (v: string) => (v ? new Date(v).toLocaleString('vi-VN') : '—'),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      fixed: 'right' as const,
      render: (_: unknown, record: SystemConfigDto) => (
        <TableActions
          align="right"
          items={[
            { key: 'edit', icon: <EditOutlined />, label: 'Sửa', onClick: () => openEdit(record) },
          ]}
        />
      ),
    },
  ]

  return (
    <>
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Cấu hình hệ thống
      </Typography.Title>
      <Card>
        <Typography.Paragraph type="secondary" style={{ marginBottom: 16 }}>
          Xem và chỉnh sửa các tham số cấu hình (chỉ cho phép sửa giá trị).
        </Typography.Paragraph>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={configs}
          loading={isLoading}
          pagination={{ pageSize: 20, showSizeChanger: true, showTotal: (t) => `Tổng ${t} mục` }}
          scroll={{ x: 900 }}
          bordered
          size="middle"
        />
      </Card>

      <Modal
        title="Sửa cấu hình"
        open={modalOpen}
        onCancel={() => { setModalOpen(false); setEditingKey(null); setEditingRecord(null) }}
        onOk={handleSubmit}
        okText="Lưu"
        cancelText="Hủy"
        confirmLoading={updateMutation.isPending}
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnClose
      >
        <div ref={formContainerRef}>
          {editingRecord && (
            <Typography.Paragraph type="secondary" style={{ marginBottom: 16 }}>
              {editingRecord.description || editingRecord.configKey}
            </Typography.Paragraph>
          )}
          <Form form={form} layout="vertical">
            <Form.Item
              name="configValue"
              label="Giá trị"
              rules={[{ required: true, message: 'Nhập giá trị' }]}
            >
              <Input.TextArea rows={3} placeholder="Giá trị cấu hình" />
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
