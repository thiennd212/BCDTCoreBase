import { useState, useEffect, useRef } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, Table, Typography, Button, Space, Modal, Form, Input, Select, message, Checkbox } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { reportingPeriodsApi } from '../api/reportingPeriodsApi'
import { reportingFrequenciesApi } from '../api/reportingFrequenciesApi'
import type { ReportingPeriodDto, CreateReportingPeriodRequest } from '../types/reportingPeriod.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text } = Typography

const defaultCreate: CreateReportingPeriodRequest = {
  reportingFrequencyId: 0,
  periodCode: '',
  periodName: '',
  year: new Date().getFullYear(),
  startDate: '',
  endDate: '',
  deadline: '',
  status: 'Open',
  isCurrent: false,
}

export function ReportingPeriodsPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<CreateReportingPeriodRequest & { id?: number }>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: periods = [], isLoading, error } = useQuery({
    queryKey: ['reporting-periods'],
    queryFn: () => reportingPeriodsApi.getList(),
  })

  const { data: frequencies = [] } = useQuery({
    queryKey: ['reporting-frequencies'],
    queryFn: () => reportingFrequenciesApi.getList({ includeInactive: false }),
  })

  const createMutation = useMutation({
    mutationFn: reportingPeriodsApi.create,
    onSuccess: () => {
      message.success('Tạo kỳ báo cáo thành công')
      queryClient.invalidateQueries({ queryKey: ['reporting-periods'] })
      setModalOpen(false)
      form.setFieldsValue(defaultCreate)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo kỳ báo cáo thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: { status?: string; isCurrent?: boolean; isLocked?: boolean } }) =>
      reportingPeriodsApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật kỳ báo cáo thành công')
      queryClient.invalidateQueries({ queryKey: ['reporting-periods'] })
      setModalOpen(false)
      setEditingId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: reportingPeriodsApi.delete,
    onSuccess: () => {
      message.success('Đã xóa kỳ báo cáo')
      queryClient.invalidateQueries({ queryKey: ['reporting-periods'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const openCreate = () => {
    form.setFieldsValue({
      ...defaultCreate,
      reportingFrequencyId: frequencies[0]?.id ?? 0,
    })
    setEditingId(null)
    setModalOpen(true)
  }

  const openEdit = (record: ReportingPeriodDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      id: record.id,
      reportingFrequencyId: record.reportingFrequencyId,
      periodCode: record.periodCode,
      periodName: record.periodName,
      year: record.year,
      startDate: record.startDate,
      endDate: record.endDate,
      deadline: record.deadline ?? '',
      status: record.status,
      isCurrent: record.isCurrent,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingId !== null) {
      updateMutation.mutate({
        id: editingId,
        body: { status: values.status, isCurrent: values.isCurrent },
      })
    } else {
      createMutation.mutate({
        reportingFrequencyId: values.reportingFrequencyId,
        periodCode: values.periodCode,
        periodName: values.periodName,
        year: values.year,
        startDate: values.startDate,
        endDate: values.endDate,
        deadline: values.deadline || undefined,
        status: values.status ?? 'Open',
        isCurrent: values.isCurrent ?? false,
      })
    }
  }

  const columns = [
    { title: 'Mã kỳ', dataIndex: 'periodCode', key: 'periodCode', width: 120, ellipsis: true },
    { title: 'Tên kỳ', dataIndex: 'periodName', key: 'periodName', ellipsis: true },
    { title: 'Năm', dataIndex: 'year', key: 'year', width: 80 },
    { title: 'Từ ngày', dataIndex: 'startDate', key: 'startDate', width: 110 },
    { title: 'Đến ngày', dataIndex: 'endDate', key: 'endDate', width: 110 },
    { title: 'Hạn nộp', dataIndex: 'deadline', key: 'deadline', width: 110 },
    { title: 'Trạng thái', dataIndex: 'status', key: 'status', width: 100 },
    {
      title: 'Hiện tại',
      dataIndex: 'isCurrent',
      key: 'isCurrent',
      width: 90,
      render: (v: boolean) => (v ? 'Có' : '—'),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: ReportingPeriodDto) => (
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
                title: 'Xóa kỳ báo cáo?',
                description: 'Chỉ xóa được khi chưa có báo cáo nào thuộc kỳ này.',
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

  if (error) {
    return (
      <Card>
        <Text type="danger">Lỗi: {(error as Error).message}</Text>
      </Card>
    )
  }

  const frequencyOptions = frequencies.map((f) => ({ value: f.id, label: `${f.code} - ${f.name}` }))

  return (
    <>
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Kỳ báo cáo
      </Typography.Title>
      <Card>
        <Space style={{ marginBottom: 16 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm kỳ
          </Button>
        </Space>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={periods}
          loading={isLoading}
          pagination={{ pageSize: 10, showSizeChanger: true }}
          bordered
        />
      </Card>

      <Modal
        title={editingId !== null ? 'Sửa kỳ báo cáo' : 'Thêm kỳ báo cáo'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText={editingId !== null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        styles={{ body: { maxHeight: '70vh', overflow: 'auto' } }}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="reportingFrequencyId" label="Chu kỳ" rules={[{ required: true }]}>
              <Select options={frequencyOptions} placeholder="Chọn chu kỳ" disabled={editingId !== null} />
            </Form.Item>
            <Form.Item name="periodCode" label="Mã kỳ" rules={[{ required: true }]}>
              <Input placeholder="VD: 2026-01" disabled={editingId !== null} />
            </Form.Item>
            <Form.Item name="periodName" label="Tên kỳ" rules={[{ required: true }]}>
              <Input placeholder="VD: Tháng 01/2026" />
            </Form.Item>
            <Form.Item name="year" label="Năm" rules={[{ required: true }]}>
              <Input type="number" />
            </Form.Item>
            <Form.Item name="startDate" label="Từ ngày" rules={[{ required: true }]}>
              <Input type="date" />
            </Form.Item>
            <Form.Item name="endDate" label="Đến ngày" rules={[{ required: true }]}>
              <Input type="date" />
            </Form.Item>
            <Form.Item name="deadline" label="Hạn nộp">
              <Input type="date" />
            </Form.Item>
            <Form.Item name="status" label="Trạng thái">
              <Select
                options={[
                  { value: 'Open', label: 'Mở' },
                  { value: 'Closed', label: 'Đóng' },
                  { value: 'Archived', label: 'Lưu trữ' },
                ]}
              />
            </Form.Item>
            <Form.Item name="isCurrent" valuePropName="checked" label="Kỳ hiện tại">
              <Checkbox />
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
