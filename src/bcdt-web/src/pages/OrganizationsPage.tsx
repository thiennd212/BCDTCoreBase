import { useState, useEffect, useRef, useMemo } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, Table, Typography, Button, Space, Modal, Form, Input, Select, TreeSelect, Checkbox, message, Row, Col, Divider, Tag, Tree, Empty } from 'antd'
import type { DataNode } from 'antd/es/tree'
import { PlusOutlined, EditOutlined, DeleteOutlined, BankOutlined, ApartmentOutlined, TeamOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { organizationsApi } from '../api/organizationsApi'
import type { OrganizationDto, CreateOrganizationRequest } from '../types/organization.types'
import { ORGANIZATION_TYPES } from '../constants/organizationTypes'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'
import { buildTree, treeExcludeSelfAndDescendants } from '../utils/treeUtils'
import type { TreeNode } from '../utils/treeUtils'

const { Text } = Typography

const TREE_LEFT_WIDTH = 360

function organizationSort(a: OrganizationDto, b: OrganizationDto): number {
  return (a.displayOrder - b.displayOrder) || a.code.localeCompare(b.code)
}

type TreeSelectNode = { value: number; title: string; key: number; children?: TreeSelectNode[] }

function toTreeSelectData(nodes: TreeNode<OrganizationDto>[]): TreeSelectNode[] {
  return nodes.map((n) => ({
    value: n.id,
    title: `${n.code} - ${n.name}`,
    key: n.id,
    children: n.children?.length ? toTreeSelectData(n.children) : undefined,
  }))
}

function getOrgTypeIcon(code?: string) {
  switch (code) {
    case 'MINISTRY':
      return <BankOutlined style={{ color: '#1668dc', marginRight: 8 }} />
    case 'PROVINCE':
      return <ApartmentOutlined style={{ color: '#059669', marginRight: 8 }} />
    case 'LEVEL3':
    case 'LEVEL4':
    case 'LEVEL5':
    default:
      return <TeamOutlined style={{ color: '#6b7280', marginRight: 8 }} />
  }
}

function toAntTreeData(nodes: TreeNode<OrganizationDto>[]): DataNode[] {
  return nodes.map((n) => ({
    key: String(n.id),
    title: (
      <span className="org-tree-node-title">
        {getOrgTypeIcon(n.organizationTypeCode)}
        <span className="org-tree-node-label">{n.code} - {n.name}</span>
      </span>
    ),
    children: n.children?.length ? toAntTreeData(n.children) : undefined,
  }))
}

/** Thu thập key của các node từ gốc đến cấp maxDepth (0 = chỉ gốc, 1 = gốc + con, 2 = gốc + con + cháu). */
function getExpandedKeysToDepth(nodes: TreeNode<OrganizationDto>[], maxDepth: number): string[] {
  const keys: string[] = []
  const walk = (list: TreeNode<OrganizationDto>[], depth: number) => {
    if (depth > maxDepth) return
    for (const n of list) {
      keys.push(String(n.id))
      if (n.children?.length) walk(n.children, depth + 1)
    }
  }
  walk(nodes, 0)
  return keys
}

/** Lấy danh sách đơn vị con trực tiếp (flat) của node trong cây. */
function getDirectChildren(tree: TreeNode<OrganizationDto>[], parentId: number | null): OrganizationDto[] {
  if (parentId == null) {
    return tree.map((n) => ({ ...n, children: undefined })) as OrganizationDto[]
  }
  const find = (nodes: TreeNode<OrganizationDto>[], id: number): TreeNode<OrganizationDto> | null => {
    for (const node of nodes) {
      if (node.id === id) return node
      const inChild = node.children ? find(node.children, id) : null
      if (inChild) return inChild
    }
    return null
  }
  const parent = find(tree, parentId)
  const children = parent?.children ?? []
  return children.map((n) => ({ ...n, children: undefined })) as OrganizationDto[]
}

const defaultForm: CreateOrganizationRequest = {
  code: '',
  name: '',
  shortName: '',
  organizationTypeId: 1,
  parentId: undefined,
  address: '',
  phone: '',
  email: '',
  taxCode: '',
  isActive: true,
  displayOrder: 0,
}

export function OrganizationsPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<CreateOrganizationRequest>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [selectedTreeKey, setSelectedTreeKey] = useState<string | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data = [], isLoading, error } = useQuery({
    queryKey: ['organizations', { all: true }],
    queryFn: () => organizationsApi.getList({ all: true, includeInactive: true }),
  })

  const treeData = useMemo(
    () => buildTree(data, { sortBy: organizationSort }),
    [data]
  )

  const antTreeData = useMemo(() => toAntTreeData(treeData), [treeData])

  const defaultExpandedKeysToLevel2 = useMemo(
    () => getExpandedKeysToDepth(treeData, 1),
    [treeData]
  )

  const selectedParentId = selectedTreeKey ? Number(selectedTreeKey) : null
  const tableDataSource = useMemo(
    () => getDirectChildren(treeData, selectedParentId),
    [treeData, selectedParentId]
  )

  const parentTreeOptions = useMemo(() => {
    const tree = buildTree(data, { sortBy: organizationSort })
    const filtered = editingId != null ? treeExcludeSelfAndDescendants(tree, editingId) : tree
    return toTreeSelectData(filtered)
  }, [data, editingId])

  const createMutation = useMutation({
    mutationFn: organizationsApi.create,
    onSuccess: () => {
      message.success('Tạo đơn vị thành công')
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      setModalOpen(false)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo đơn vị thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: CreateOrganizationRequest }) =>
      organizationsApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật đơn vị thành công')
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
      setModalOpen(false)
      setEditingId(null)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: organizationsApi.delete,
    onSuccess: () => {
      message.success('Đã xóa đơn vị')
      queryClient.invalidateQueries({ queryKey: ['organizations'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  // Khi mở modal thêm mới, mặc định chọn đơn vị cha = node đang chọn trên cây trái
  useEffect(() => {
    if (modalOpen && editingId == null && selectedTreeKey != null) {
      form.setFieldValue('parentId', Number(selectedTreeKey))
    }
  }, [modalOpen, editingId, selectedTreeKey, form])

  const openCreate = () => {
    const nextDisplayOrder =
      data.length === 0
        ? 0
        : Math.max(0, ...data.map((o) => o.displayOrder ?? 0)) + 1
    const parentId = selectedTreeKey ? Number(selectedTreeKey) : undefined
    form.setFieldsValue({ ...defaultForm, displayOrder: nextDisplayOrder, parentId })
    setEditingId(null)
    setModalOpen(true)
  }

  const openEdit = (record: OrganizationDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      code: record.code,
      name: record.name,
      shortName: record.shortName ?? '',
      organizationTypeId: record.organizationTypeId,
      parentId: record.parentId ?? undefined,
      address: record.address ?? '',
      phone: record.phone ?? '',
      email: record.email ?? '',
      taxCode: record.taxCode ?? '',
      isActive: record.isActive,
      displayOrder: record.displayOrder,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    const body: CreateOrganizationRequest = {
      ...values,
      shortName: values.shortName || undefined,
      parentId: values.parentId ?? undefined,
      address: values.address || undefined,
      phone: values.phone || undefined,
      email: values.email || undefined,
      taxCode: values.taxCode || undefined,
    }
    if (editingId !== null) {
      updateMutation.mutate({ id: editingId, body })
    } else {
      createMutation.mutate(body)
    }
  }

  const headerCellNowrap = { style: { whiteSpace: 'nowrap' as const } }
  const columns = [
    { title: 'Mã', dataIndex: 'code', key: 'code', width: 88, ellipsis: true, onHeaderCell: () => headerCellNowrap },
    { title: 'Tên', dataIndex: 'name', key: 'name', ellipsis: true, minWidth: 160, onHeaderCell: () => headerCellNowrap },
    { title: 'Loại', dataIndex: 'organizationTypeCode', key: 'organizationTypeCode', width: 110, ellipsis: true, onHeaderCell: () => headerCellNowrap },
    { title: 'Cấp', dataIndex: 'level', key: 'level', width: 72, align: 'center' as const, onHeaderCell: () => headerCellNowrap },
    {
      title: 'Hoạt động',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 108,
      align: 'center' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (v: boolean) => (
        <Tag color={v ? 'success' : 'default'}>{v ? 'Có' : 'Không'}</Tag>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (_: unknown, record: OrganizationDto) => (
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
                title: 'Xóa đơn vị?',
                description: 'Bạn có chắc muốn xóa đơn vị này?',
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
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Quản lý đơn vị
      </Typography.Title>
      <Card>
        <Row gutter={16} wrap={false}>
          <Col flex={`0 0 ${TREE_LEFT_WIDTH}px`}>
            <div className="org-tree-wrap">
              <Typography.Text type="secondary" strong style={{ display: 'block', marginBottom: 10 }}>
                Cây đơn vị
              </Typography.Text>
              <Tree
                className="org-tree"
                showLine
                blockNode
                treeData={antTreeData}
                selectedKeys={selectedTreeKey ? [selectedTreeKey] : []}
                onSelect={(keys) => setSelectedTreeKey(keys.length ? (keys[0] as string) : null)}
                defaultExpandedKeys={defaultExpandedKeysToLevel2}
                style={{ background: 'transparent' }}
              />
            </div>
          </Col>
          <Col flex="1" style={{ minWidth: 0 }}>
            <Space style={{ marginBottom: 16 }} wrap>
              <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
                Thêm đơn vị
              </Button>
              <Text type="secondary">
                {selectedTreeKey == null
                  ? `Tổng ${data.length} bản ghi (đơn vị gốc)`
                  : `${tableDataSource.length} đơn vị con`}
              </Text>
            </Space>
            {tableDataSource.length === 0 && !isLoading ? (
              <Empty
                description={selectedTreeKey ? 'Không có đơn vị con' : 'Chọn một đơn vị bên trái để xem đơn vị con'}
                style={{ padding: 24 }}
              />
            ) : (
              <Table<OrganizationDto>
                rowKey="id"
                bordered
                columns={columns}
                dataSource={tableDataSource}
                loading={isLoading}
                pagination={false}
                scroll={{ x: 700 }}
              />
            )}
          </Col>
        </Row>
      </Card>

      <Modal
        title={editingId ? 'Sửa đơn vị' : 'Thêm đơn vị'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        confirmLoading={createMutation.isPending || updateMutation.isPending}
        destroyOnHidden={false}
        okText={editingId ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.LARGE}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
      >
        <div ref={formContainerRef}>
        <Form form={form} layout="vertical" preserve={false}>
          <Typography.Text type="secondary" strong style={{ display: 'block', marginBottom: 12 }}>
            Thông tin cơ bản
          </Typography.Text>
          <Row gutter={16}>
            <Col xs={24} sm={12}>
              <Form.Item name="code" label="Mã" rules={[{ required: true, message: 'Nhập mã đơn vị' }]}>
                <Input placeholder="Mã" />
              </Form.Item>
            </Col>
            <Col xs={24} sm={12}>
              <Form.Item name="name" label="Tên" rules={[{ required: true, message: 'Nhập tên đơn vị' }]}>
                <Input placeholder="Tên đơn vị" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col xs={24} sm={12}>
              <Form.Item name="shortName" label="Tên viết tắt">
                <Input placeholder="Tên viết tắt" />
              </Form.Item>
            </Col>
            <Col xs={24} sm={12}>
              <Form.Item name="organizationTypeId" label="Loại đơn vị" rules={[{ required: true }]}>
                <Select
                  options={ORGANIZATION_TYPES.map((t) => ({ value: t.id, label: `${t.code} - ${t.name}` }))}
                  placeholder="Chọn loại"
                />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="parentId" label="Đơn vị cha">
            <TreeSelect
              allowClear
              placeholder="Không có (gốc)"
              treeData={parentTreeOptions}
              showSearch
              filterTreeNode={(input, node) =>
                (node.title ?? '').toString().toLowerCase().includes(input.toLowerCase())
              }
              treeDefaultExpandAll={false}
              style={{ width: '100%' }}
            />
          </Form.Item>

          <Divider style={{ margin: '16px 0' }} />
          <Typography.Text type="secondary" strong style={{ display: 'block', marginBottom: 12 }}>
            Liên hệ
          </Typography.Text>
          <Form.Item name="address" label="Địa chỉ">
            <Input placeholder="Địa chỉ" />
          </Form.Item>
          <Row gutter={16}>
            <Col xs={24} sm={12}>
              <Form.Item name="phone" label="Số điện thoại">
                <Input placeholder="Số điện thoại" />
              </Form.Item>
            </Col>
            <Col xs={24} sm={12}>
              <Form.Item name="email" label="Email">
                <Input type="email" placeholder="Email" />
              </Form.Item>
            </Col>
          </Row>
          <Row gutter={16}>
            <Col xs={24} sm={12}>
              <Form.Item name="taxCode" label="Mã số thuế">
                <Input placeholder="Mã số thuế" />
              </Form.Item>
            </Col>
            <Col xs={24} sm={12}>
              <Form.Item name="displayOrder" label="Thứ tự hiển thị">
                <Input type="number" min={0} />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="isActive" valuePropName="checked" initialValue={true}>
            <Checkbox>Hoạt động</Checkbox>
          </Form.Item>
        </Form>
        </div>
      </Modal>
    </>
  )
}
