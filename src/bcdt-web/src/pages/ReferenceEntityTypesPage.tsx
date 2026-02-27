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
  Checkbox,
  message,
  Tag,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { referenceEntityTypesApi } from '../api/referenceEntityTypesApi'
import type {
  ReferenceEntityTypeDto,
  CreateReferenceEntityTypeRequest,
  UpdateReferenceEntityTypeRequest,
} from '../types/referenceEntity.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const defaultCreate: CreateReferenceEntityTypeRequest = {
  code: '',
  name: '',
  description: '',
  isActive: true,
}

export function ReferenceEntityTypesPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<CreateReferenceEntityTypeRequest>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: types = [], isLoading } = useQuery({
    queryKey: ['reference-entity-types'],
    queryFn: () => referenceEntityTypesApi.getList({ includeInactive: true }),
  })

  const createMutation = useMutation({
    mutationFn: referenceEntityTypesApi.create,
    onSuccess: () => {
      message.success('Tạo loại thực thể thành công')
      queryClient.invalidateQueries({ queryKey: ['reference-entity-types'] })
      setModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateReferenceEntityTypeRequest }) =>
      referenceEntityTypesApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật loại thực thể thành công')
      queryClient.invalidateQueries({ queryKey: ['reference-entity-types'] })
      setModalOpen(false)
      setEditingId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: referenceEntityTypesApi.delete,
    onSuccess: () => {
      message.success('Đã xóa loại thực thể')
      queryClient.invalidateQueries({ queryKey: ['reference-entity-types'] })
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

  const openEdit = (record: ReferenceEntityTypeDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      code: record.code,
      name: record.name,
      description: record.description ?? '',
      isActive: record.isActive,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const fields = editingId !== null ? ['name', 'description', 'isActive'] : undefined
    const values = await form.validateFields(fields)
    if (editingId !== null) {
      const body: UpdateReferenceEntityTypeRequest = {
        name: values.name,
        description: values.description || undefined,
        isActive: values.isActive ?? true,
      }
      await updateMutation.mutateAsync({ id: editingId, body })
    } else {
      await createMutation.mutateAsync({
        code: values.code,
        name: values.name,
        description: values.description || undefined,
        isActive: values.isActive ?? true,
      })
    }
  }

  const columns = [
    { title: 'Mã', dataIndex: 'code', key: 'code', width: 140 },
    { title: 'Tên', dataIndex: 'name', key: 'name', ellipsis: true },
    { title: 'Mô tả', dataIndex: 'description', key: 'description', ellipsis: true, render: (v: string | null) => v ?? '-' },
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
      render: (_: unknown, record: ReferenceEntityTypeDto) => (
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
                title: 'Xóa loại thực thể?',
                description: 'Chỉ xóa được khi chưa có bản ghi tham chiếu thuộc loại này.',
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
        Loại thực thể tham chiếu
      </Typography.Title>
      <Card>
        <Button
          type="primary"
          icon={<PlusOutlined />}
          onClick={openCreate}
          style={{ marginBottom: 16 }}
        >
          Thêm loại
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
        title={editingId !== null ? 'Sửa loại thực thể' : 'Thêm loại thực thể'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText={editingId !== null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.SMALL}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        confirmLoading={createMutation.isPending || updateMutation.isPending}
        styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" preserve={false}>
            <Form.Item name="code" label="Mã" rules={[{ required: true, message: 'Nhập mã' }]}>
              <Input placeholder="VD: LOAI_01" disabled={editingId !== null} />
            </Form.Item>
            <Form.Item name="name" label="Tên" rules={[{ required: true, message: 'Nhập tên' }]}>
              <Input placeholder="Tên loại thực thể" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea rows={2} placeholder="Mô tả (tùy chọn)" />
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked" initialValue={true}>
              <Checkbox>Đang hoạt động</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
