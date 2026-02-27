import { useState, useRef, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card,
  Table,
  Typography,
  Button,
  Space,
  Modal,
  Form,
  Input,
  InputNumber,
  Checkbox,
  message,
  Tag,
  TreeSelect,
  Select,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { referenceEntityTypesApi } from '../api/referenceEntityTypesApi'
import { referenceEntitiesApi } from '../api/referenceEntitiesApi'
import type {
  ReferenceEntityDto,
  CreateReferenceEntityRequest,
  UpdateReferenceEntityRequest,
} from '../types/referenceEntity.types'
import { buildTree, treeExcludeSelfAndDescendants } from '../utils/treeUtils'
import type { TreeNode } from '../utils/treeUtils'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text, Title } = Typography

type FormValues = CreateReferenceEntityRequest

function toTreeSelectData(
  nodes: TreeNode<ReferenceEntityDto>[]
): { value: number; title: string; children?: ReturnType<typeof toTreeSelectData> }[] {
  return nodes.map((n) => ({
    value: n.id,
    title: `${n.code} - ${n.name}`,
    children: n.children?.length ? toTreeSelectData(n.children) : undefined,
  }))
}

export function ReferenceEntitiesPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<FormValues>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [selectedEntityTypeId, setSelectedEntityTypeId] = useState<number | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: entityTypes = [] } = useQuery({
    queryKey: ['reference-entity-types'],
    queryFn: () => referenceEntityTypesApi.getList({ includeInactive: true }),
  })

  const { data: flatList = [], isLoading, error } = useQuery({
    queryKey: ['reference-entities', selectedEntityTypeId ?? 0, { all: true }],
    queryFn: () =>
      referenceEntitiesApi.getList({
        entityTypeId: selectedEntityTypeId ?? undefined,
        all: true,
        includeInactive: true,
      }),
    enabled: selectedEntityTypeId != null,
  })

  const treeData = useMemo(
    () =>
      buildTree(flatList, {
        sortBy: (a, b) =>
          (a.displayOrder - b.displayOrder) || (a.code || '').localeCompare(b.code || ''),
      }),
    [flatList]
  )

  const parentTreeData = useMemo(
    () =>
      editingId != null ? treeExcludeSelfAndDescendants(treeData, editingId) : treeData,
    [treeData, editingId]
  )

  const treeSelectData = useMemo(() => toTreeSelectData(parentTreeData), [parentTreeData])
  const defaultExpandRowKeys = useMemo(() => treeData.map((n) => n.id), [treeData])

  const createMutation = useMutation({
    mutationFn: referenceEntitiesApi.create,
    onSuccess: () => {
      message.success('Tạo thành công')
      queryClient.invalidateQueries({ queryKey: ['reference-entities'] })
      setModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateReferenceEntityRequest }) =>
      referenceEntitiesApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật thành công')
      queryClient.invalidateQueries({ queryKey: ['reference-entities'] })
      setModalOpen(false)
      setEditingId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: referenceEntitiesApi.delete,
    onSuccess: () => {
      message.success('Đã xóa')
      queryClient.invalidateQueries({ queryKey: ['reference-entities'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  const openCreate = () => {
    if (selectedEntityTypeId == null) {
      message.warning('Chọn loại thực thể trước')
      return
    }
    const nextOrder =
      flatList.length > 0 ? Math.max(0, ...flatList.map((m) => m.displayOrder)) + 1 : 0
    form.setFieldsValue({
      entityTypeId: selectedEntityTypeId,
      code: '',
      name: '',
      parentId: null,
      organizationId: null,
      displayOrder: nextOrder,
      isActive: true,
      validFrom: undefined,
      validTo: undefined,
    })
    setEditingId(null)
    setModalOpen(true)
  }

  const openEdit = (record: ReferenceEntityDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      entityTypeId: record.entityTypeId,
      code: record.code,
      name: record.name,
      parentId: record.parentId ?? null,
      organizationId: record.organizationId ?? null,
      displayOrder: record.displayOrder,
      isActive: record.isActive,
      validFrom: record.validFrom ?? undefined,
      validTo: record.validTo ?? undefined,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingId !== null) {
      updateMutation.mutate({
        id: editingId,
        body: {
          name: values.name,
          parentId: values.parentId || null,
          organizationId: values.organizationId ?? null,
          displayOrder: values.displayOrder,
          isActive: values.isActive,
          validFrom: values.validFrom || undefined,
          validTo: values.validTo || undefined,
        },
      })
    } else {
      createMutation.mutate({
        entityTypeId: values.entityTypeId,
        code: values.code,
        name: values.name,
        parentId: values.parentId || null,
        organizationId: values.organizationId ?? null,
        displayOrder: values.displayOrder,
        isActive: values.isActive,
        validFrom: values.validFrom || undefined,
        validTo: values.validTo || undefined,
      })
    }
  }

  const headerCellNowrap = () => ({ style: { whiteSpace: 'nowrap' as const } })
  const columns = [
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 120,
      onHeaderCell: headerCellNowrap,
    },
    {
      title: 'Tên',
      dataIndex: 'name',
      key: 'name',
      minWidth: 180,
      onHeaderCell: headerCellNowrap,
    },
    {
      title: 'Thứ tự',
      dataIndex: 'displayOrder',
      key: 'displayOrder',
      width: 80,
      align: 'center' as const,
      onHeaderCell: headerCellNowrap,
    },
    {
      title: 'Hoạt động',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 100,
      align: 'center' as const,
      onHeaderCell: headerCellNowrap,
      render: (v: boolean) => <Tag color={v ? 'success' : 'default'}>{v ? 'Có' : 'Không'}</Tag>,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      onHeaderCell: headerCellNowrap,
      render: (_: unknown, record: ReferenceEntityDto) => (
        <TableActions
          align="right"
          items={[
            {
              key: 'edit',
              label: 'Sửa',
              icon: <EditOutlined />,
              onClick: () => openEdit(record),
            },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: {
                title: 'Xóa bản ghi?',
                description: 'Không thể xóa nếu còn bản ghi con.',
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

  return (
    <>
      <Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Dữ liệu tham chiếu (phân cấp)
      </Title>
      <Card>
        <Space style={{ marginBottom: 16 }} wrap>
          <Select
            placeholder="Chọn loại thực thể"
            allowClear
            style={{ minWidth: 200 }}
            value={selectedEntityTypeId}
            onChange={setSelectedEntityTypeId}
            options={entityTypes.map((t) => ({ label: `${t.code} - ${t.name}`, value: t.id }))}
          />
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={openCreate}
            disabled={selectedEntityTypeId == null}
          >
            Thêm
          </Button>
          {selectedEntityTypeId != null && (
            <Text type="secondary">Tổng: {flatList.length} bản ghi</Text>
          )}
        </Space>
        {selectedEntityTypeId != null && (
          <Table<TreeNode<ReferenceEntityDto>>
            rowKey="id"
            bordered
            columns={columns}
            dataSource={treeData}
            loading={isLoading}
            pagination={false}
            expandable={{
              childrenColumnName: 'children',
              defaultExpandedRowKeys: defaultExpandRowKeys,
            }}
          />
        )}
        {selectedEntityTypeId == null && (
          <Text type="secondary">Chọn loại thực thể để xem danh sách.</Text>
        )}
      </Card>

      <Modal
        title={editingId ? 'Sửa bản ghi' : 'Thêm bản ghi'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        confirmLoading={createMutation.isPending || updateMutation.isPending}
        destroyOnHidden={false}
        okText={editingId ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" preserve={false}>
            <Form.Item name="entityTypeId" label="Loại thực thể" rules={[{ required: true }]}>
              <Select
                placeholder="Chọn loại"
                options={entityTypes.map((t) => ({ label: `${t.code} - ${t.name}`, value: t.id }))}
                disabled={!!editingId}
              />
            </Form.Item>
            <Form.Item
              name="code"
              label="Mã"
              rules={[{ required: true, message: 'Nhập mã' }]}
            >
              <Input placeholder="Mã (unique trong loại)" disabled={!!editingId} />
            </Form.Item>
            <Form.Item name="name" label="Tên" rules={[{ required: true, message: 'Nhập tên' }]}>
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="parentId" label="Bản ghi cha">
              <TreeSelect
                placeholder="Không có (gốc)"
                allowClear
                showSearch
                treeData={treeSelectData}
                treeDefaultExpandAll={false}
                filterTreeNode={(input, node) =>
                  (node.title ?? '').toString().toLowerCase().includes(input.toLowerCase())
                }
              />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự hiển thị" initialValue={0}>
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked" initialValue={true}>
              <Checkbox>Hoạt động</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
