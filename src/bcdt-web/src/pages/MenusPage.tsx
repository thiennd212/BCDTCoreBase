import { useState, useEffect, useRef, useMemo } from 'react'
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
import {
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  DashboardOutlined,
  TeamOutlined,
  UserOutlined,
  FileTextOutlined,
  SettingOutlined,
  SafetyCertificateOutlined,
  KeyOutlined,
  MenuOutlined,
  CalendarOutlined,
  BellOutlined,
  FolderOutlined,
  BarChartOutlined,
  FormOutlined,
  UnorderedListOutlined,
  ApartmentOutlined,
  AppstoreOutlined,
  BookOutlined,
  ClockCircleOutlined,
  NodeIndexOutlined,
} from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { menusApi } from '../api/menusApi'
import { permissionsApi } from '../api/permissionsApi'
import type { MenuDto, CreateMenuRequest, UpdateMenuRequest } from '../types/menu.types'
import type { PermissionDto } from '../types/permission.types'
import { buildTree, treeExcludeSelfAndDescendants } from '../utils/treeUtils'
import type { TreeNode } from '../utils/treeUtils'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text, Title } = Typography

type MenuFormValues = CreateMenuRequest

const defaultForm: CreateMenuRequest = {
  code: '',
  name: '',
  parentId: null,
  url: '',
  icon: '',
  displayOrder: 0,
  isVisible: true,
  requiredPermission: null,
}

// Icon map for rendering
const ICON_MAP: Record<string, React.ReactNode> = {
  DashboardOutlined: <DashboardOutlined />,
  TeamOutlined: <TeamOutlined />,
  UserOutlined: <UserOutlined />,
  FileTextOutlined: <FileTextOutlined />,
  SettingOutlined: <SettingOutlined />,
  SafetyCertificateOutlined: <SafetyCertificateOutlined />,
  KeyOutlined: <KeyOutlined />,
  MenuOutlined: <MenuOutlined />,
  CalendarOutlined: <CalendarOutlined />,
  BellOutlined: <BellOutlined />,
  FolderOutlined: <FolderOutlined />,
  BarChartOutlined: <BarChartOutlined />,
  FormOutlined: <FormOutlined />,
  UnorderedListOutlined: <UnorderedListOutlined />,
  ApartmentOutlined: <ApartmentOutlined />,
  AppstoreOutlined: <AppstoreOutlined />,
  BookOutlined: <BookOutlined />,
  ClockCircleOutlined: <ClockCircleOutlined />,
  NodeIndexOutlined: <NodeIndexOutlined />,
}

// Common Ant Design icons for menu
const ICON_OPTIONS = Object.entries(ICON_MAP).map(([value, icon]) => ({
  label: <Space>{icon} {value.replace('Outlined', '')}</Space>,
  value,
}))

/** Chuyển TreeNode<MenuDto> sang định dạng Ant Design TreeSelect */
function toTreeSelectData(nodes: TreeNode<MenuDto>[]): { value: number; title: string; children?: ReturnType<typeof toTreeSelectData> }[] {
  return nodes.map((n) => ({
    value: n.id,
    title: n.name,
    children: n.children?.length ? toTreeSelectData(n.children) : undefined,
  }))
}

export function MenusPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<MenuFormValues>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: flatMenus = [], isLoading, error } = useQuery({
    queryKey: ['menus', { all: true }],
    queryFn: () => menusApi.getAll({ all: true }),
  })

  const { data: permissions = [] } = useQuery({
    queryKey: ['permissions-all'],
    queryFn: () => permissionsApi.getAll(),
  })

  const treeData = useMemo(
    () =>
      buildTree(flatMenus, {
        sortBy: (a, b) => (a.displayOrder - b.displayOrder) || (a.name || '').localeCompare(b.name || ''),
      }),
    [flatMenus]
  )

  const parentTreeData = useMemo(
    () => (editingId != null ? treeExcludeSelfAndDescendants(treeData, editingId) : treeData),
    [treeData, editingId]
  )

  const treeSelectData = useMemo(() => toTreeSelectData(parentTreeData), [parentTreeData])

  const defaultExpandRowKeys = useMemo(() => treeData.map((n) => n.id), [treeData])

  const createMutation = useMutation({
    mutationFn: menusApi.create,
    onSuccess: () => {
      message.success('Tạo menu thành công')
      queryClient.invalidateQueries({ queryKey: ['menus'] })
      setModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo menu thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateMenuRequest }) => menusApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật menu thành công')
      queryClient.invalidateQueries({ queryKey: ['menus'] })
      setModalOpen(false)
      setEditingId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: menusApi.delete,
    onSuccess: () => {
      message.success('Đã xóa menu')
      queryClient.invalidateQueries({ queryKey: ['menus'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  useEffect(() => {
    if (!modalOpen) {
      setEditingId(null)
    }
  }, [modalOpen])

  const openCreate = () => {
    const nextOrder =
      flatMenus.length > 0 ? Math.max(0, ...flatMenus.map((m) => m.displayOrder)) + 1 : 0
    form.setFieldsValue({ ...defaultForm, displayOrder: nextOrder })
    setEditingId(null)
    setModalOpen(true)
  }

  const openEdit = (record: MenuDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      code: record.code,
      name: record.name,
      parentId: record.parentId ?? null,
      url: record.url ?? '',
      icon: record.icon ?? '',
      displayOrder: record.displayOrder,
      isVisible: record.isVisible,
      requiredPermission: record.requiredPermission ?? null,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingId !== null) {
      const body: UpdateMenuRequest = {
        name: values.name,
        parentId: values.parentId || null,
        url: values.url || null,
        icon: values.icon || null,
        displayOrder: values.displayOrder,
        isVisible: values.isVisible,
        requiredPermission: values.requiredPermission || null,
      }
      updateMutation.mutate({ id: editingId, body })
    } else {
      const body: CreateMenuRequest = {
        code: values.code,
        name: values.name,
        parentId: values.parentId || null,
        url: values.url || null,
        icon: values.icon || null,
        displayOrder: values.displayOrder,
        isVisible: values.isVisible,
        requiredPermission: values.requiredPermission || null,
      }
      createMutation.mutate(body)
    }
  }

  const headerCellNowrap = { style: { whiteSpace: 'nowrap' as const } }
  const columns = [
    {
      title: 'Tên menu',
      dataIndex: 'name',
      key: 'name',
      minWidth: 180,
      onHeaderCell: () => headerCellNowrap,
    },
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 180,
      ellipsis: { showTitle: true },
      onHeaderCell: () => headerCellNowrap,
    },
    {
      title: 'URL',
      dataIndex: 'url',
      key: 'url',
      width: 150,
      ellipsis: true,
      onHeaderCell: () => headerCellNowrap,
      render: (v: string | null) => v || <Text type="secondary">-</Text>,
    },
    {
      title: 'Icon',
      dataIndex: 'icon',
      key: 'icon',
      width: 70,
      align: 'center' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (v: string | null) => v && ICON_MAP[v] ? <span title={v} style={{ fontSize: 18 }}>{ICON_MAP[v]}</span> : <Text type="secondary">-</Text>,
    },
    {
      title: 'Thứ tự',
      dataIndex: 'displayOrder',
      key: 'displayOrder',
      width: 80,
      align: 'center' as const,
      onHeaderCell: () => headerCellNowrap,
    },
    {
      title: 'Hiển thị',
      dataIndex: 'isVisible',
      key: 'isVisible',
      width: 100,
      align: 'center' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (v: boolean) => (
        <Tag color={v ? 'success' : 'default'}>{v ? 'Có' : 'Không'}</Tag>
      ),
    },
    {
      title: 'Quyền yêu cầu',
      dataIndex: 'requiredPermission',
      key: 'requiredPermission',
      width: 130,
      ellipsis: true,
      onHeaderCell: () => headerCellNowrap,
      render: (v: string | null) => v ? <Tag color="blue" style={{ maxWidth: 110 }} title={v}>{v}</Tag> : <Text type="secondary">-</Text>,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (_: unknown, record: MenuDto) => (
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
                title: 'Xóa menu?',
                description: 'Không thể xóa nếu menu có menu con hoặc đang được gán cho vai trò.',
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
        Quản lý menu
      </Title>
      <Card>
        <Space style={{ marginBottom: 16 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm menu
          </Button>
          <Text type="secondary">Tổng: {flatMenus.length} menu</Text>
        </Space>
        <Table<TreeNode<MenuDto>>
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
          scroll={{ x: 900 }}
        />
      </Card>

      {/* Modal tạo/sửa menu */}
      <Modal
        title={editingId ? 'Sửa menu' : 'Thêm menu'}
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
            <Form.Item
              name="code"
              label="Mã menu"
              rules={[
                { required: true, message: 'Nhập mã menu' },
                { pattern: /^[A-Z0-9_]+$/, message: 'Mã chỉ gồm chữ in hoa, số, gạch dưới' },
              ]}
            >
              <Input placeholder="VD: MENU_DASHBOARD" disabled={!!editingId} />
            </Form.Item>
            <Form.Item
              name="name"
              label="Tên menu"
              rules={[{ required: true, message: 'Nhập tên menu' }]}
            >
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="parentId" label="Menu cha">
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
            <Form.Item name="url" label="URL">
              <Input placeholder="/dashboard" />
            </Form.Item>
            <Form.Item name="icon" label="Icon">
              <Select
                placeholder="Chọn icon"
                allowClear
                showSearch
                options={ICON_OPTIONS}
              />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự hiển thị" initialValue={0}>
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="requiredPermission" label="Quyền yêu cầu">
              <Select
                placeholder="Chọn quyền cần thiết để xem menu"
                allowClear
                showSearch
                options={permissions.map((p: PermissionDto) => ({
                  label: `${p.name} (${p.code})`,
                  value: p.code,
                }))}
              />
            </Form.Item>
            <Form.Item name="isVisible" valuePropName="checked" initialValue={true}>
              <Checkbox>Hiển thị trong menu</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
