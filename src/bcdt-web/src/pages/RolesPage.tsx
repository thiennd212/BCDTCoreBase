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
  Row,
  Col,
  Tag,
  Drawer,
  Collapse,
  Spin,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, SafetyOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { rolesApi } from '../api/rolesApi'
import { permissionsApi } from '../api/permissionsApi'
import type { RoleDto, CreateRoleRequest, UpdateRoleRequest } from '../types/role.types'
import type { PermissionDto } from '../types/permission.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text, Title } = Typography
const { TextArea } = Input

type RoleFormValues = CreateRoleRequest

const defaultForm: CreateRoleRequest = {
  code: '',
  name: '',
  description: '',
  isActive: true,
}

/** Nhóm permissions theo module */
function groupPermissionsByModule(permissions: PermissionDto[]): Record<string, PermissionDto[]> {
  const groups: Record<string, PermissionDto[]> = {}
  for (const p of permissions) {
    const module = p.module || 'Khác'
    if (!groups[module]) groups[module] = []
    groups[module].push(p)
  }
  return groups
}

export function RolesPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<RoleFormValues>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [editingIsSystem, setEditingIsSystem] = useState(false)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  // Permission assignment state
  const [permDrawerOpen, setPermDrawerOpen] = useState(false)
  const [permRoleId, setPermRoleId] = useState<number | null>(null)
  const [permRoleName, setPermRoleName] = useState<string>('')
  const [selectedPermIds, setSelectedPermIds] = useState<number[]>([])

  const { data: roles = [], isLoading, error } = useQuery({
    queryKey: ['roles'],
    queryFn: () => rolesApi.getList({ includeInactive: true }),
  })

  const { data: allPermissions = [], isLoading: permissionsLoading } = useQuery({
    queryKey: ['permissions'],
    queryFn: () => permissionsApi.getAll(),
    enabled: permDrawerOpen,
  })

  const { data: rolePermissions = [], isLoading: rolePermissionsLoading } = useQuery({
    queryKey: ['rolePermissions', permRoleId],
    queryFn: () => (permRoleId ? rolesApi.getPermissions(permRoleId) : Promise.resolve([])),
    enabled: permDrawerOpen && permRoleId !== null,
  })

  // Khi load xong permissions của role, set vào state
  useEffect(() => {
    if (permDrawerOpen && !rolePermissionsLoading && rolePermissions) {
      setSelectedPermIds(rolePermissions)
    }
  }, [permDrawerOpen, rolePermissionsLoading, rolePermissions])

  const createMutation = useMutation({
    mutationFn: rolesApi.create,
    onSuccess: () => {
      message.success('Tạo vai trò thành công')
      queryClient.invalidateQueries({ queryKey: ['roles'] })
      setModalOpen(false)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo vai trò thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateRoleRequest }) => rolesApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật vai trò thành công')
      queryClient.invalidateQueries({ queryKey: ['roles'] })
      setModalOpen(false)
      setEditingId(null)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: rolesApi.delete,
    onSuccess: () => {
      message.success('Đã xóa vai trò')
      queryClient.invalidateQueries({ queryKey: ['roles'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  const setPermissionsMutation = useMutation({
    mutationFn: ({ roleId, permissionIds }: { roleId: number; permissionIds: number[] }) =>
      rolesApi.setPermissions(roleId, permissionIds),
    onSuccess: () => {
      message.success('Cập nhật quyền thành công')
      queryClient.invalidateQueries({ queryKey: ['rolePermissions', permRoleId] })
      setPermDrawerOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật quyền thất bại'),
  })

  useEffect(() => {
    if (!modalOpen) {
      setEditingId(null)
      setEditingIsSystem(false)
    }
  }, [modalOpen])

  const openCreate = () => {
    form.setFieldsValue({ ...defaultForm })
    setEditingId(null)
    setEditingIsSystem(false)
    setModalOpen(true)
  }

  const openEdit = (record: RoleDto) => {
    setEditingId(record.id)
    setEditingIsSystem(record.isSystem)
    form.setFieldsValue({
      code: record.code,
      name: record.name,
      description: record.description ?? '',
      isActive: record.isActive,
    })
    setModalOpen(true)
  }

  const openPermissionDrawer = (record: RoleDto) => {
    setPermRoleId(record.id)
    setPermRoleName(record.name)
    setSelectedPermIds([])
    setPermDrawerOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingId !== null) {
      const body: UpdateRoleRequest = {
        name: values.name,
        description: values.description || undefined,
        isActive: values.isActive,
      }
      updateMutation.mutate({ id: editingId, body })
    } else {
      const body: CreateRoleRequest = {
        code: values.code,
        name: values.name,
        description: values.description || undefined,
        isActive: values.isActive,
      }
      createMutation.mutate(body)
    }
  }

  const handleSavePermissions = () => {
    if (permRoleId !== null) {
      setPermissionsMutation.mutate({ roleId: permRoleId, permissionIds: selectedPermIds })
    }
  }

  const handlePermissionChange = (permId: number, checked: boolean) => {
    setSelectedPermIds((prev) =>
      checked ? [...prev, permId] : prev.filter((id) => id !== permId)
    )
  }

  const handleModuleSelectAll = (modulePerms: PermissionDto[], checked: boolean) => {
    const modulePermIds = modulePerms.map((p) => p.id)
    setSelectedPermIds((prev) => {
      if (checked) {
        // Add all from this module
        const newIds = modulePermIds.filter((id) => !prev.includes(id))
        return [...prev, ...newIds]
      } else {
        // Remove all from this module
        return prev.filter((id) => !modulePermIds.includes(id))
      }
    })
  }

  const groupedPermissions = useMemo(() => groupPermissionsByModule(allPermissions), [allPermissions])

  const headerCellNowrap = { style: { whiteSpace: 'nowrap' as const } }
  const columns = [
    { title: 'Mã', dataIndex: 'code', key: 'code', width: 140, ellipsis: true, onHeaderCell: () => headerCellNowrap },
    { title: 'Tên', dataIndex: 'name', key: 'name', ellipsis: true, minWidth: 160, onHeaderCell: () => headerCellNowrap },
    { title: 'Mô tả', dataIndex: 'description', key: 'description', ellipsis: true, minWidth: 180, onHeaderCell: () => headerCellNowrap },
    {
      title: 'Hệ thống',
      dataIndex: 'isSystem',
      key: 'isSystem',
      width: 100,
      align: 'center' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (v: boolean) => (
        <Tag color={v ? 'blue' : 'default'}>{v ? 'Có' : 'Không'}</Tag>
      ),
    },
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
      width: ACTIONS_COLUMN_WIDTH_ICON + 35, // Extra space for permission button
      align: 'right' as const,
      onHeaderCell: () => headerCellNowrap,
      render: (_: unknown, record: RoleDto) => (
        <TableActions
          align="right"
          items={[
            {
              key: 'permissions',
              label: 'Phân quyền',
              icon: <SafetyOutlined />,
              onClick: () => openPermissionDrawer(record),
            },
            {
              key: 'edit',
              label: 'Sửa',
              icon: <EditOutlined />,
              onClick: () => openEdit(record),
            },
            ...(record.isSystem
              ? []
              : [
                  {
                    key: 'delete',
                    label: 'Xóa',
                    icon: <DeleteOutlined />,
                    danger: true,
                    confirm: {
                      title: 'Xóa vai trò?',
                      description: 'Bạn có chắc muốn xóa vai trò này?',
                      okText: 'Xóa',
                      cancelText: 'Hủy',
                    },
                    onClick: () => deleteMutation.mutate(record.id),
                  },
                ]),
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
        Quản lý vai trò
      </Title>
      <Card>
        <Space style={{ marginBottom: 16 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm vai trò
          </Button>
        </Space>
        <Table<RoleDto>
          rowKey="id"
          bordered
          columns={columns}
          dataSource={roles}
          loading={isLoading}
          pagination={{
            pageSize: 20,
            showSizeChanger: true,
            showTotal: (t) => `Tổng ${t} bản ghi`,
            pageSizeOptions: ['10', '20', '50'],
          }}
          scroll={{ x: 700 }}
        />
      </Card>

      {/* Modal tạo/sửa vai trò */}
      <Modal
        title={editingId ? 'Sửa vai trò' : 'Thêm vai trò'}
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
              label="Mã vai trò"
              rules={[
                { required: true, message: 'Nhập mã vai trò' },
                { pattern: /^[A-Z0-9_]+$/, message: 'Mã chỉ gồm chữ in hoa, số, gạch dưới' },
              ]}
            >
              <Input placeholder="VD: REPORT_ADMIN" disabled={!!editingId} />
            </Form.Item>
            <Form.Item
              name="name"
              label="Tên vai trò"
              rules={[{ required: true, message: 'Nhập tên vai trò' }]}
            >
              <Input placeholder="Tên vai trò" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <TextArea rows={3} placeholder="Mô tả vai trò" />
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked" initialValue={true}>
              <Checkbox disabled={editingIsSystem}>Hoạt động</Checkbox>
            </Form.Item>
            {editingIsSystem && (
              <Text type="secondary" style={{ fontSize: 12 }}>
                Vai trò hệ thống không thể thay đổi trạng thái hoạt động
              </Text>
            )}
          </Form>
        </div>
      </Modal>

      {/* Drawer phân quyền */}
      <Drawer
        title={`Phân quyền cho vai trò: ${permRoleName}`}
        open={permDrawerOpen}
        onClose={() => setPermDrawerOpen(false)}
        width={520}
        styles={{ body: { paddingTop: 8 } }}
        extra={
          <Space>
            <Button onClick={() => setPermDrawerOpen(false)}>Hủy</Button>
            <Button
              type="primary"
              onClick={handleSavePermissions}
              loading={setPermissionsMutation.isPending}
            >
              Lưu
            </Button>
          </Space>
        }
      >
        {permissionsLoading || rolePermissionsLoading ? (
          <div style={{ textAlign: 'center', padding: 40 }}>
            <Spin tip="Đang tải danh sách quyền..." />
          </div>
        ) : allPermissions.length === 0 ? (
          <Text type="secondary">Không có quyền nào trong hệ thống</Text>
        ) : (
          <Collapse
            defaultActiveKey={Object.keys(groupedPermissions)}
            items={Object.entries(groupedPermissions).map(([module, perms]) => {
              const modulePermIds = perms.map((p) => p.id)
              const checkedCount = modulePermIds.filter((id) => selectedPermIds.includes(id)).length
              const allChecked = checkedCount === perms.length
              const indeterminate = checkedCount > 0 && checkedCount < perms.length

              return {
                key: module,
                label: (
                  <Space>
                    <Checkbox
                      checked={allChecked}
                      indeterminate={indeterminate}
                      onChange={(e) => {
                        e.stopPropagation()
                        handleModuleSelectAll(perms, e.target.checked)
                      }}
                      onClick={(e) => e.stopPropagation()}
                    />
                    <Text strong>{module}</Text>
                    <Tag>{checkedCount}/{perms.length}</Tag>
                  </Space>
                ),
                children: (
                  <Row gutter={[8, 8]} style={{ paddingLeft: 24 }}>
                    {perms.map((perm) => (
                      <Col key={perm.id} xs={24} sm={12}>
                        <Checkbox
                          checked={selectedPermIds.includes(perm.id)}
                          onChange={(e) => handlePermissionChange(perm.id, e.target.checked)}
                        >
                          <span title={perm.description || perm.code}>
                            {perm.name}
                          </span>
                        </Checkbox>
                      </Col>
                    ))}
                  </Row>
                ),
              }
            })}
          />
        )}
      </Drawer>
    </>
  )
}
