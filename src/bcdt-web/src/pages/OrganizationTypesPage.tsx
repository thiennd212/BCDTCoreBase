import { useState, useRef, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card,
  Table,
  Typography,
  Button,
  Modal,
  Form,
  Input,
  InputNumber,
  Select,
  Checkbox,
  message,
  Tag,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { organizationTypesApi } from '../api/organizationTypesApi'
import type {
  OrganizationTypeDto,
  CreateOrganizationTypeRequest,
  UpdateOrganizationTypeRequest,
} from '../types/organization.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const defaultCreate: CreateOrganizationTypeRequest = {
  code: '',
  name: '',
  level: 1,
  parentTypeId: undefined,
  description: '',
  isActive: true,
}

export function OrganizationTypesPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<CreateOrganizationTypeRequest>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: types = [], isLoading } = useQuery({
    queryKey: ['organization-types'],
    queryFn: () => organizationTypesApi.getList({ includeInactive: true }),
  })

  const createMutation = useMutation({
    mutationFn: organizationTypesApi.create,
    onSuccess: () => {
      message.success('Tạo loại đơn vị thành công')
      queryClient.invalidateQueries({ queryKey: ['organization-types'] })
      setModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateOrganizationTypeRequest }) =>
      organizationTypesApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật loại đơn vị thành công')
      queryClient.invalidateQueries({ queryKey: ['organization-types'] })
      setModalOpen(false)
      setEditingId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: organizationTypesApi.delete,
    onSuccess: () => {
      message.success('Đã xóa loại đơn vị')
      queryClient.invalidateQueries({ queryKey: ['organization-types'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const openCreate = () => {
    form.setFieldsValue({ ...defaultCreate })
    setEditingId(null)
    setModalOpen(true)
  }

  const openEdit = (record: OrganizationTypeDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      code: record.code,
      name: record.name,
      level: record.level,
      parentTypeId: record.parentTypeId ?? undefined,
      description: record.description ?? '',
      isActive: record.isActive,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingId !== null) {
      const body: UpdateOrganizationTypeRequest = {
        name: values.name,
        level: values.level,
        parentTypeId: values.parentTypeId ?? undefined,
        description: values.description || undefined,
        isActive: values.isActive ?? true,
      }
      updateMutation.mutate({ id: editingId, body })
    } else {
      createMutation.mutate({
        code: values.code,
        name: values.name,
        level: values.level,
        parentTypeId: values.parentTypeId ?? undefined,
        description: values.description || undefined,
        isActive: values.isActive ?? true,
      })
    }
  }

  const parentOptions = types
    .filter((t) => editingId === null || t.id !== editingId)
    .map((t) => ({ value: t.id, label: `${t.code} - ${t.name} (Cấp ${t.level})` }))

  const columns = [
    { title: 'Mã', dataIndex: 'code', key: 'code', width: 100 },
    { title: 'Tên loại đơn vị', dataIndex: 'name', key: 'name', ellipsis: true },
    { title: 'Cấp', dataIndex: 'level', key: 'level', width: 70, align: 'center' as const },
    {
      title: 'Loại cha',
      dataIndex: 'parentTypeId',
      key: 'parentTypeId',
      width: 160,
      render: (v: number | null) => {
        if (!v) return '-'
        const parent = types.find((t) => t.id === v)
        return parent ? parent.name : v
      },
    },
    {
      title: 'Số đơn vị',
      dataIndex: 'organizationCount',
      key: 'organizationCount',
      width: 100,
      align: 'center' as const,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 100,
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? 'Hoạt động' : 'Tắt'}</Tag>,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: OrganizationTypeDto) => (
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
                title: 'Xóa loại đơn vị',
                description: 'Bạn có chắc muốn xóa loại đơn vị này?',
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
        Loại đơn vị
      </Typography.Title>
      <Card>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={openCreate}
          style={{ marginBottom: 16 }}
        >
          Thêm loại đơn vị
        </Button>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={types}
          loading={isLoading}
          pagination={{ pageSize: 10, showSizeChanger: true }}
          bordered
          size="middle"
        />
      </Card>

      <Modal
        title={editingId !== null ? 'Sửa loại đơn vị' : 'Thêm loại đơn vị'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText={editingId !== null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.SMALL}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        confirmLoading={createMutation.isPending || updateMutation.isPending}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã" rules={[{ required: true, message: 'Nhập mã' }]}>
              <Input placeholder="VD: BO" disabled={editingId !== null} />
            </Form.Item>
            <Form.Item name="name" label="Tên loại đơn vị" rules={[{ required: true, message: 'Nhập tên' }]}>
              <Input placeholder="VD: Bộ" />
            </Form.Item>
            <Form.Item name="level" label="Cấp" rules={[{ required: true, message: 'Nhập cấp' }]}>
              <InputNumber min={1} max={5} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="parentTypeId" label="Loại cha">
              <Select allowClear placeholder="Chọn loại cha (nếu có)" options={parentOptions} />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea rows={2} placeholder="Mô tả (tùy chọn)" />
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
