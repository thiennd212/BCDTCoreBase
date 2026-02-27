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
  Checkbox,
  message,
  Tag,
  Select,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, FolderOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { permissionsApi } from '../api/permissionsApi'
import type { PermissionDto, CreatePermissionRequest, UpdatePermissionRequest } from '../types/permission.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text, Title } = Typography
const { TextArea } = Input

type PermissionFormValues = CreatePermissionRequest

const defaultForm: CreatePermissionRequest = {
  code: '',
  name: '',
  module: '',
  action: '',
  description: '',
  isActive: true,
}

// Các module và action gợi ý
const MODULES = ['User', 'Role', 'Organization', 'Form', 'Report', 'System', 'Menu']
const ACTIONS = ['View', 'Create', 'Update', 'Delete', 'Manage', 'Export', 'Import']

/** Nút ảo nhóm theo Module (giống menu cha) */
type ModuleRow = {
  key: string
  isModule: true
  name: string
  module: string
  children: PermissionTreeRow[]
}
/** Dòng quyền (leaf) */
type PermissionLeafRow = PermissionDto & { key: number; isModule?: false }
export type PermissionTreeRow = ModuleRow | PermissionLeafRow

function isModuleRow(r: PermissionTreeRow): r is ModuleRow {
  return 'isModule' in r && r.isModule === true
}

export function PermissionsPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<PermissionFormValues>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [filterModule, setFilterModule] = useState<string | undefined>(undefined)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: permissions = [], isLoading, error } = useQuery({
    queryKey: ['permissions-all'],
    queryFn: () => permissionsApi.getAll(),
  })

  // Lọc theo module
  const filteredPermissions = filterModule
    ? permissions.filter((p) => p.module === filterModule)
    : permissions

  // Cây phân cấp: gốc = Module, con = các quyền (tương tự danh sách menu)
  const treeData = useMemo<PermissionTreeRow[]>(() => {
    const byModule = new Map<string, PermissionDto[]>()
    for (const p of filteredPermissions) {
      const m = p.module || '(Khác)'
      if (!byModule.has(m)) byModule.set(m, [])
      byModule.get(m)!.push(p)
    }
    const moduleOrder = ['Admin', 'Form', 'Submission', 'Workflow', 'Report', 'Auth']
    const sortedModules = Array.from(byModule.keys()).sort(
      (a, b) => {
        const ia = moduleOrder.indexOf(a)
        const ib = moduleOrder.indexOf(b)
        if (ia !== -1 && ib !== -1) return ia - ib
        if (ia !== -1) return -1
        if (ib !== -1) return 1
        return a.localeCompare(b)
      }
    )
    return sortedModules.map((module) => {
      const perms = byModule.get(module)!.slice().sort((a, b) => (a.code || '').localeCompare(b.code || ''))
      return {
        key: `module_${module}`,
        isModule: true as const,
        name: module,
        module,
        children: perms.map((p) => ({ ...p, key: p.id, isModule: false } as PermissionLeafRow)),
      } as ModuleRow
    })
  }, [filteredPermissions])

  const defaultExpandRowKeys = useMemo(() => treeData.map((n) => n.key), [treeData])

  // Lấy danh sách module unique (cho filter dropdown)
  const moduleList = [...new Set(permissions.map((p) => p.module).filter(Boolean))]

  const createMutation = useMutation({
    mutationFn: permissionsApi.create,
    onSuccess: () => {
      message.success('Tạo quyền thành công')
      queryClient.invalidateQueries({ queryKey: ['permissions-all'] })
      queryClient.invalidateQueries({ queryKey: ['permissions'] })
      setModalOpen(false)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo quyền thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdatePermissionRequest }) =>
      permissionsApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật quyền thành công')
      queryClient.invalidateQueries({ queryKey: ['permissions-all'] })
      queryClient.invalidateQueries({ queryKey: ['permissions'] })
      setModalOpen(false)
      setEditingId(null)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: permissionsApi.delete,
    onSuccess: () => {
      message.success('Đã xóa quyền')
      queryClient.invalidateQueries({ queryKey: ['permissions-all'] })
      queryClient.invalidateQueries({ queryKey: ['permissions'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  useEffect(() => {
    if (!modalOpen) {
      setEditingId(null)
    }
  }, [modalOpen])

  const openCreate = () => {
    form.setFieldsValue({ ...defaultForm })
    setEditingId(null)
    setModalOpen(true)
  }

  const openEdit = (record: PermissionDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      code: record.code,
      name: record.name,
      module: record.module,
      action: record.action,
      description: record.description ?? '',
      isActive: record.isActive,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingId !== null) {
      const body: UpdatePermissionRequest = {
        name: values.name,
        module: values.module,
        action: values.action,
        description: values.description || undefined,
        isActive: values.isActive,
      }
      updateMutation.mutate({ id: editingId, body })
    } else {
      const body: CreatePermissionRequest = {
        code: values.code,
        name: values.name,
        module: values.module,
        action: values.action,
        description: values.description || undefined,
        isActive: values.isActive,
      }
      createMutation.mutate(body)
    }
  }

  const headerCellNowrap = { style: { whiteSpace: 'nowrap' as const } }
  const columns = [
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 180,
      ellipsis: true,
      onHeaderCell: () => headerCellNowrap,
      render: (v: string | undefined, record: PermissionTreeRow) =>
        isModuleRow(record) ? (
          <Space><FolderOutlined /><Text strong>{record.name}</Text></Space>
        ) : (
          v
        ),
    },
    {
      title: 'Tên',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
      minWidth: 160,
      onHeaderCell: () => headerCellNowrap,
      render: (v: string | undefined, record: PermissionTreeRow) =>
        isModuleRow(record) ? null : v,
    },
    {
      title: 'Module',
      dataIndex: 'module',
      key: 'module',
      width: 120,
      onHeaderCell: () => headerCellNowrap,
      render: (v: string | undefined, record: PermissionTreeRow) =>
        isModuleRow(record) ? null : (v ? <Tag color="blue">{v}</Tag> : null),
    },
    {
      title: 'Hành động',
      dataIndex: 'action',
      key: 'action',
      width: 100,
      onHeaderCell: () => headerCellNowrap,
      render: (v: string | undefined, record: PermissionTreeRow) =>
        isModuleRow(record) ? null : (v ? <Tag color="geekblue">{v}</Tag> : null),
    },
    {
      title: 'Mô tả',
      dataIndex: 'description',
      key: 'description',
      ellipsis: true,
      minWidth: 180,
      onHeaderCell: () => headerCellNowrap,
      render: (_: unknown, record: PermissionTreeRow) =>
        isModuleRow(record) ? null : (record as PermissionDto).description,
    },
    {
      title: 'Hoạt động',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 108,
      align: 'center' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (v: boolean | undefined, record: PermissionTreeRow) =>
        isModuleRow(record) ? null : (
          <Tag color={v ? 'success' : 'default'}>{v ? 'Có' : 'Không'}</Tag>
        ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (_: unknown, record: PermissionTreeRow) =>
        isModuleRow(record) ? null : (
          <TableActions
            align="right"
            items={[
              {
                key: 'edit',
                label: 'Sửa',
                icon: <EditOutlined />,
                onClick: () => openEdit(record as PermissionDto),
              },
              {
                key: 'delete',
                label: 'Xóa',
                icon: <DeleteOutlined />,
                danger: true,
                confirm: {
                  title: 'Xóa quyền?',
                  description: 'Bạn có chắc muốn xóa quyền này? Không thể xóa nếu quyền đang được gán cho vai trò.',
                  okText: 'Xóa',
                  cancelText: 'Hủy',
                },
                onClick: () => deleteMutation.mutate((record as PermissionDto).id),
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
        Quản lý quyền
      </Title>
      <Card>
        <Space style={{ marginBottom: 16 }} wrap>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm quyền
          </Button>
          <Select
            placeholder="Lọc theo Module"
            allowClear
            style={{ width: 180 }}
            value={filterModule}
            onChange={setFilterModule}
            options={moduleList.map((m) => ({ label: m, value: m }))}
          />
          <Text type="secondary">Tổng: {filteredPermissions.length} quyền</Text>
        </Space>
        <Table<PermissionTreeRow>
          rowKey={(r) => r.key}
          bordered
          columns={columns}
          dataSource={treeData}
          loading={isLoading}
          pagination={false}
          defaultExpandAllRows
          defaultExpandedRowKeys={defaultExpandRowKeys}
          scroll={{ x: 900 }}
        />
      </Card>

      {/* Modal tạo/sửa quyền */}
      <Modal
        title={editingId ? 'Sửa quyền' : 'Thêm quyền'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        confirmLoading={createMutation.isPending || updateMutation.isPending}
        destroyOnHidden={false}
        okText={editingId ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.SMALL}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" preserve={false}>
            <Form.Item
              name="code"
              label="Mã quyền"
              rules={[
                { required: true, message: 'Nhập mã quyền' },
                { pattern: /^[A-Z0-9_]+$/, message: 'Mã chỉ gồm chữ in hoa, số, gạch dưới' },
              ]}
            >
              <Input placeholder="VD: USER_VIEW, FORM_CREATE" disabled={!!editingId} />
            </Form.Item>
            <Form.Item
              name="name"
              label="Tên quyền"
              rules={[{ required: true, message: 'Nhập tên quyền' }]}
            >
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item
              name="module"
              label="Module"
              rules={[{ required: true, message: 'Chọn hoặc nhập module' }]}
            >
              <Select
                placeholder="Chọn hoặc nhập module"
                allowClear
                showSearch
                mode="tags"
                maxCount={1}
                options={MODULES.map((m) => ({ label: m, value: m }))}
              />
            </Form.Item>
            <Form.Item
              name="action"
              label="Hành động"
              rules={[{ required: true, message: 'Chọn hoặc nhập hành động' }]}
            >
              <Select
                placeholder="Chọn hoặc nhập hành động"
                allowClear
                showSearch
                mode="tags"
                maxCount={1}
                options={ACTIONS.map((a) => ({ label: a, value: a }))}
              />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <TextArea rows={2} placeholder="Mô tả quyền" />
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
