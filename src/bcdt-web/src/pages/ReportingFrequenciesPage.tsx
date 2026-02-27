import { useState, useRef, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, Table, Typography, Button, Modal, Form, Input, InputNumber, Checkbox, message, Tag } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { reportingFrequenciesApi } from '../api/reportingFrequenciesApi'
import type {
  ReportingFrequencyDto,
  CreateReportingFrequencyRequest,
  UpdateReportingFrequencyRequest,
} from '../types/reportingPeriod.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const defaultCreate: CreateReportingFrequencyRequest = {
  code: '',
  name: '',
  nameEn: '',
  daysInPeriod: 30,
  cronExpression: '',
  description: '',
  displayOrder: 1,
  isActive: true,
}

export function ReportingFrequenciesPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<CreateReportingFrequencyRequest & { id?: number }>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: frequencies = [], isLoading } = useQuery({
    queryKey: ['reporting-frequencies'],
    queryFn: () => reportingFrequenciesApi.getList({ includeInactive: true }),
  })

  const createMutation = useMutation({
    mutationFn: reportingFrequenciesApi.create,
    onSuccess: () => {
      message.success('Tạo chu kỳ thành công')
      queryClient.invalidateQueries({ queryKey: ['reporting-frequencies'] })
      setModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo chu kỳ thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateReportingFrequencyRequest }) =>
      reportingFrequenciesApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật chu kỳ thành công')
      queryClient.invalidateQueries({ queryKey: ['reporting-frequencies'] })
      setModalOpen(false)
      setEditingId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: reportingFrequenciesApi.delete,
    onSuccess: () => {
      message.success('Đã xóa chu kỳ')
      queryClient.invalidateQueries({ queryKey: ['reporting-frequencies'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const openCreate = () => {
    const nextOrder = Math.max(0, ...frequencies.map((f) => f.displayOrder ?? 0)) + 1
    form.setFieldsValue({ ...defaultCreate, displayOrder: nextOrder })
    setEditingId(null)
    setModalOpen(true)
  }

  const openEdit = (record: ReportingFrequencyDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      code: record.code,
      name: record.name,
      nameEn: record.nameEn ?? '',
      daysInPeriod: record.daysInPeriod,
      cronExpression: record.cronExpression ?? '',
      description: record.description ?? '',
      displayOrder: record.displayOrder,
      isActive: record.isActive,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingId !== null) {
      const body: UpdateReportingFrequencyRequest = {
        name: values.name,
        nameEn: values.nameEn || undefined,
        daysInPeriod: values.daysInPeriod,
        cronExpression: values.cronExpression || undefined,
        description: values.description || undefined,
        displayOrder: values.displayOrder,
        isActive: values.isActive ?? true,
      }
      updateMutation.mutate({ id: editingId, body })
    } else {
      createMutation.mutate({
        code: values.code,
        name: values.name,
        nameEn: values.nameEn || undefined,
        daysInPeriod: values.daysInPeriod,
        cronExpression: values.cronExpression || undefined,
        description: values.description || undefined,
        displayOrder: values.displayOrder,
        isActive: values.isActive ?? true,
      })
    }
  }

  const columns = [
    { title: 'Mã', dataIndex: 'code', key: 'code', width: 120, ellipsis: true },
    { title: 'Tên chu kỳ', dataIndex: 'name', key: 'name', ellipsis: true },
    { title: 'Tên (EN)', dataIndex: 'nameEn', key: 'nameEn', width: 120, render: (v: string | undefined) => v || '—' },
    { title: 'Số ngày', dataIndex: 'daysInPeriod', key: 'daysInPeriod', width: 90, align: 'center' as const },
    { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 80, align: 'center' as const },
    {
      title: 'Trạng thái',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 100,
      align: 'center' as const,
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? 'Hoạt động' : 'Tắt'}</Tag>,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: ReportingFrequencyDto) => (
        <TableActions
          align="right"
          items={[
            { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: {
                title: 'Xóa chu kỳ báo cáo?',
                description: 'Chỉ xóa được khi chưa có kỳ báo cáo nào dùng chu kỳ này.',
                okText: 'Xóa',
                cancelText: 'Hủy',
              },
              onClick: () => deleteMutation.mutate(record.id),
            },
          ]}
        />
      ),
    },
  ]

  return (
    <>
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Chu kỳ báo cáo
      </Typography.Title>
      <Card>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreate} style={{ marginBottom: 16 }}>
          Thêm chu kỳ
        </Button>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={frequencies}
          loading={isLoading}
          pagination={{ pageSize: 10, showSizeChanger: true, showTotal: (t) => `Tổng ${t} bản ghi` }}
          bordered
          size="middle"
        />
      </Card>

      <Modal
        title={editingId !== null ? 'Sửa chu kỳ' : 'Thêm chu kỳ'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText={editingId !== null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        confirmLoading={createMutation.isPending || updateMutation.isPending}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã" rules={[{ required: true, message: 'Nhập mã' }]}>
              <Input placeholder="VD: MONTHLY" disabled={editingId !== null} />
            </Form.Item>
            <Form.Item name="name" label="Tên chu kỳ" rules={[{ required: true, message: 'Nhập tên' }]}>
              <Input placeholder="VD: Hàng tháng" />
            </Form.Item>
            <Form.Item name="nameEn" label="Tên tiếng Anh">
              <Input placeholder="VD: Monthly" />
            </Form.Item>
            <Form.Item name="daysInPeriod" label="Số ngày trong kỳ" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="cronExpression" label="Cron Expression">
              <Input placeholder="VD: 0 0 1 * * (tùy chọn)" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea rows={2} placeholder="Mô tả (tùy chọn)" />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự hiển thị" rules={[{ required: true }]}>
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked">
              <Checkbox>Đang hoạt động</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
