import { useState, useEffect, useRef } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, Table, Typography, Button, Space, Modal, Form, Input, Select, Checkbox, message, Row, Col, Divider, Tag } from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { usersApi } from '../api/usersApi'
import { organizationsApi } from '../api/organizationsApi'
import type { UserDto, CreateUserRequest, UpdateUserRequest, UserRoleOrgInputDto } from '../types/user.types'
import { ROLES } from '../constants/roles'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text } = Typography

type RoleOrgRow = { roleId?: number; organizationId?: number }
type UserFormValues = CreateUserRequest & { newPassword?: string; roleOrgRows?: RoleOrgRow[] }

const defaultCreate: CreateUserRequest & { roleOrgRows?: RoleOrgRow[] } = {
  username: '',
  password: '',
  email: '',
  fullName: '',
  phone: '',
  isActive: true,
  roleIds: [],
  organizationIds: [],
  primaryOrganizationId: undefined,
  roleOrgRows: [{ roleId: undefined, organizationId: undefined }],
}

export function UsersPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<UserFormValues>()
  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: users = [], isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: () => usersApi.getList({ includeInactive: true }),
  })

  const { data: organizations = [] } = useQuery({
    queryKey: ['organizations'],
    queryFn: () => organizationsApi.getList({ includeInactive: true }),
  })

  const createMutation = useMutation({
    mutationFn: usersApi.create,
    onSuccess: () => {
      message.success('Tạo người dùng thành công')
      queryClient.invalidateQueries({ queryKey: ['users'] })
      setModalOpen(false)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo người dùng thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateUserRequest }) => usersApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật người dùng thành công')
      queryClient.invalidateQueries({ queryKey: ['users'] })
      setModalOpen(false)
      setEditingId(null)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: usersApi.delete,
    onSuccess: () => {
      message.success('Đã xóa người dùng')
      queryClient.invalidateQueries({ queryKey: ['users'] })
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

  const openEdit = async (record: UserDto) => {
    setEditingId(record.id)
    setModalOpen(true)
    const full = await usersApi.getById(record.id)
    const user = full ?? record
    const roleOrgRows: RoleOrgRow[] =
      user.roleOrgAssignments?.length
        ? user.roleOrgAssignments.map((a) => ({ roleId: a.roleId, organizationId: a.organizationId }))
        : user.roleIds.map((roleId) => ({ roleId, organizationId: undefined }))
    form.setFieldsValue({
      username: user.username,
      password: '',
      email: user.email,
      fullName: user.fullName,
      phone: user.phone ?? '',
      isActive: user.isActive,
      roleIds: user.roleIds,
      organizationIds: user.organizationIds,
      primaryOrganizationId: user.primaryOrganizationId ?? undefined,
      newPassword: '',
      roleOrgRows: roleOrgRows.length ? roleOrgRows : [{ roleId: undefined, organizationId: undefined }],
    })
  }

  const buildRoleOrgAssignments = (rows?: RoleOrgRow[]): UserRoleOrgInputDto[] => {
    const list = rows ?? form.getFieldValue('roleOrgRows') ?? []
    return list.filter((r: RoleOrgRow) => r?.roleId).map((r: RoleOrgRow) => ({ roleId: r.roleId!, organizationId: r.organizationId }))
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    const roleOrgAssignments = buildRoleOrgAssignments(values.roleOrgRows)
    if (editingId !== null) {
      const body: UpdateUserRequest = {
        email: values.email,
        fullName: values.fullName,
        phone: values.phone || undefined,
        isActive: values.isActive,
        newPassword: values.newPassword || undefined,
        roleIds: [], organizationIds: [],
        primaryOrganizationId: values.primaryOrganizationId ?? undefined,
        roleOrgAssignments: roleOrgAssignments.length > 0 ? roleOrgAssignments : undefined,
      }
      updateMutation.mutate({ id: editingId, body })
    } else {
      const body: CreateUserRequest = {
        username: values.username,
        password: values.password,
        email: values.email,
        fullName: values.fullName,
        phone: values.phone || undefined,
        isActive: values.isActive,
        roleIds: [], organizationIds: [],
        primaryOrganizationId: values.primaryOrganizationId ?? undefined,
        roleOrgAssignments: roleOrgAssignments.length > 0 ? roleOrgAssignments : undefined,
      }
      createMutation.mutate(body)
    }
  }

  const headerCellNowrap = { style: { whiteSpace: 'nowrap' as const } }
  const columns = [
    { title: 'Tên đăng nhập', dataIndex: 'username', key: 'username', width: 130, ellipsis: true, onHeaderCell: () => headerCellNowrap },
    { title: 'Họ tên', dataIndex: 'fullName', key: 'fullName', ellipsis: true, minWidth: 140, onHeaderCell: () => headerCellNowrap },
    { title: 'Email', dataIndex: 'email', key: 'email', ellipsis: true, minWidth: 180, onHeaderCell: () => headerCellNowrap },
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
      render: (_: unknown, record: UserDto) => (
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
                title: 'Xóa người dùng?',
                description: 'Bạn có chắc muốn xóa người dùng này?',
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

  const orgOptions = organizations.map((o) => ({ value: o.id, label: `${o.code} - ${o.name}` }))
  const roleOptions = ROLES.map((r) => ({ value: r.id, label: `${r.code} - ${r.name}` }))

  return (
    <>
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Quản lý người dùng
      </Typography.Title>
      <Card>
        <Space style={{ marginBottom: 16 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm người dùng
          </Button>
        </Space>
        <Table<UserDto>
          rowKey="id"
          bordered
          columns={columns}
          dataSource={users}
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

      <Modal
        title={editingId ? 'Sửa người dùng' : 'Thêm người dùng'}
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
          <Typography.Text type="secondary" strong style={{ display: 'block', marginBottom: 12 }}>
            Tài khoản
          </Typography.Text>
          <Row gutter={16}>
            <Col xs={24} sm={12}>
              <Form.Item
                name="username"
                label="Tên đăng nhập"
                rules={[{ required: true, message: 'Nhập tên đăng nhập' }]}
              >
                <Input placeholder="Tên đăng nhập" disabled={!!editingId} />
              </Form.Item>
            </Col>
            {!editingId && (
              <Col xs={24} sm={12}>
                <Form.Item
                  name="password"
                  label="Mật khẩu"
                  rules={[{ required: true, message: 'Nhập mật khẩu' }, { min: 6, message: 'Tối thiểu 6 ký tự' }]}
                >
                  <Input.Password placeholder="Mật khẩu" />
                </Form.Item>
              </Col>
            )}
            {editingId && (
              <Col xs={24} sm={12}>
                <Form.Item name="newPassword" label="Đổi mật khẩu (để trống nếu không đổi)">
                  <Input.Password placeholder="Mật khẩu mới" />
                </Form.Item>
              </Col>
            )}
          </Row>

          <Divider style={{ margin: '16px 0' }} />
          <Typography.Text type="secondary" strong style={{ display: 'block', marginBottom: 12 }}>
            Thông tin cá nhân
          </Typography.Text>
          <Row gutter={16}>
            <Col xs={24} sm={12}>
              <Form.Item name="fullName" label="Họ tên" rules={[{ required: true, message: 'Nhập họ tên' }]}>
                <Input placeholder="Họ tên" />
              </Form.Item>
            </Col>
            <Col xs={24} sm={12}>
              <Form.Item name="email" label="Email" rules={[{ required: true, message: 'Nhập email' }, { type: 'email' }]}>
                <Input type="email" placeholder="Email" />
              </Form.Item>
            </Col>
          </Row>
          <Form.Item name="phone" label="Số điện thoại">
            <Input placeholder="Số điện thoại" />
          </Form.Item>

          <Divider style={{ margin: '16px 0' }} />
          <Typography.Text type="secondary" strong style={{ display: 'block', marginBottom: 12 }}>
            Gán vai trò theo đơn vị
          </Typography.Text>
          <Form.List name="roleOrgRows">
            {(fields, { add, remove }) => (
              <>
                {fields.map(({ key, name, ...rest }) => (
                  <Row key={key} gutter={8} align="middle" style={{ marginBottom: 8 }}>
                    <Col flex="1 1 200px">
                      <Form.Item {...rest} name={[name, 'roleId']} rules={[{ required: true, message: 'Chọn vai trò' }]} style={{ marginBottom: 0 }}>
                        <Select options={roleOptions} placeholder="Vai trò" allowClear />
                      </Form.Item>
                    </Col>
                    <Col flex="1 1 200px">
                      <Form.Item {...rest} name={[name, 'organizationId']} style={{ marginBottom: 0 }}>
                        <Select options={orgOptions} placeholder="Đơn vị (tùy chọn)" allowClear />
                      </Form.Item>
                    </Col>
                    <Col>
                      <Button type="text" danger icon={<DeleteOutlined />} onClick={() => remove(name)} aria-label="Xóa dòng" />
                    </Col>
                  </Row>
                ))}
                <Button type="dashed" onClick={() => add({ roleId: undefined, organizationId: undefined })} block icon={<PlusOutlined />} style={{ marginBottom: 12 }}>
                  Thêm vai trò – đơn vị
                </Button>
              </>
            )}
          </Form.List>
          <Form.Item name="primaryOrganizationId" label="Đơn vị chính">
            <Select allowClear placeholder="Chọn đơn vị chính (phải thuộc danh sách trên)" options={orgOptions} />
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
