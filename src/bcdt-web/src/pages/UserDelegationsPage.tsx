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
  Select,
  DatePicker,
  Tag,
  Space,
  message,
} from 'antd'
import { PlusOutlined, StopOutlined } from '@ant-design/icons'
import dayjs from 'dayjs'
import { getApiErrorMessage } from '../api/apiClient'
import { userDelegationsApi } from '../api/userDelegationsApi'
import { usersApi } from '../api/usersApi'
import type { UserDelegationDto, CreateUserDelegationRequest } from '../types/userDelegation.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const DELEGATION_TYPES = [
  { value: 'Full', label: 'Toàn quyền (Full)' },
  { value: 'Partial', label: 'Một phần (Partial)' },
]

export function UserDelegationsPage() {
  const queryClient = useQueryClient()
  const [form] = Form.useForm<CreateUserDelegationRequest & { validRange: [dayjs.Dayjs, dayjs.Dayjs] }>()
  const [revokeForm] = Form.useForm<{ revokedReason?: string }>()
  const [modalOpen, setModalOpen] = useState(false)
  const [revokeModalOpen, setRevokeModalOpen] = useState(false)
  const [revokingId, setRevokingId] = useState<number | null>(null)
  const [activeOnly, setActiveOnly] = useState(false)
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) form.resetFields()
  }, [modalOpen, form])

  useEffect(() => {
    if (!revokeModalOpen) {
      setRevokingId(null)
      revokeForm.resetFields()
    }
  }, [revokeModalOpen, revokeForm])

  const { data: delegations = [], isLoading } = useQuery({
    queryKey: ['user-delegations', activeOnly],
    queryFn: () => userDelegationsApi.getList({ activeOnly }),
  })

  const { data: users = [] } = useQuery({
    queryKey: ['users'],
    queryFn: () => usersApi.getList(),
  })

  const createMutation = useMutation({
    mutationFn: userDelegationsApi.create,
    onSuccess: () => {
      message.success('Tạo ủy quyền thành công')
      queryClient.invalidateQueries({ queryKey: ['user-delegations'] })
      setModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo ủy quyền thất bại'),
  })

  const revokeMutation = useMutation({
    mutationFn: ({ id, reason }: { id: number; reason?: string }) =>
      userDelegationsApi.revoke(id, { revokedReason: reason }),
    onSuccess: () => {
      message.success('Đã thu hồi ủy quyền')
      queryClient.invalidateQueries({ queryKey: ['user-delegations'] })
      setRevokeModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Thu hồi thất bại'),
  })

  const handleCreate = async () => {
    const values = await form.validateFields()
    const [from, to] = values.validRange
    createMutation.mutate({
      fromUserId: values.fromUserId,
      toUserId: values.toUserId,
      delegationType: values.delegationType,
      permissions: values.delegationType === 'Partial' ? (values.permissions ?? null) : null,
      organizationId: values.organizationId ?? null,
      reason: values.reason ?? null,
      validFrom: from.toISOString(),
      validTo: to.toISOString(),
    })
  }

  const handleRevoke = async () => {
    if (revokingId == null) return
    const values = await revokeForm.validateFields()
    revokeMutation.mutate({ id: revokingId, reason: values.revokedReason })
  }

  const userOptions = users.map((u) => ({ value: u.id, label: `${u.fullName} (${u.username})` }))

  const columns = [
    {
      title: 'Người ủy quyền',
      key: 'fromUser',
      width: 180,
      render: (_: unknown, record: UserDelegationDto) =>
        record.fromUserName ?? users.find((u) => u.id === record.fromUserId)?.fullName ?? record.fromUserId,
    },
    {
      title: 'Người nhận',
      key: 'toUser',
      width: 180,
      render: (_: unknown, record: UserDelegationDto) =>
        record.toUserName ?? users.find((u) => u.id === record.toUserId)?.fullName ?? record.toUserId,
    },
    {
      title: 'Loại',
      dataIndex: 'delegationType',
      key: 'delegationType',
      width: 110,
      render: (v: string) => <Tag color={v === 'Full' ? 'blue' : 'geekblue'}>{v}</Tag>,
    },
    {
      title: 'Hiệu lực từ',
      dataIndex: 'validFrom',
      key: 'validFrom',
      width: 140,
      render: (v: string) => dayjs(v).format('DD/MM/YYYY HH:mm'),
    },
    {
      title: 'Hết hạn',
      dataIndex: 'validTo',
      key: 'validTo',
      width: 140,
      render: (v: string) => dayjs(v).format('DD/MM/YYYY HH:mm'),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 110,
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? 'Đang hiệu lực' : 'Đã thu hồi'}</Tag>,
    },
    {
      title: 'Lý do',
      dataIndex: 'reason',
      key: 'reason',
      ellipsis: true,
      render: (v: string | null) => v ?? '–',
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: UserDelegationDto) =>
        record.isActive ? (
          <TableActions
            align="right"
            items={[
              {
                key: 'revoke',
                label: 'Thu hồi',
                icon: <StopOutlined />,
                danger: true,
                onClick: () => {
                  setRevokingId(record.id)
                  setRevokeModalOpen(true)
                },
              },
            ]}
          />
        ) : null,
    },
  ]

  return (
    <>
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Ủy quyền người dùng
      </Typography.Title>
      <Card>
        <Space style={{ marginBottom: 16 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={() => setModalOpen(true)}>
            Thêm ủy quyền
          </Button>
          <Button
            type={activeOnly ? 'primary' : 'default'}
            onClick={() => setActiveOnly((v) => !v)}
          >
            {activeOnly ? 'Đang lọc: Còn hiệu lực' : 'Tất cả'}
          </Button>
        </Space>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={delegations}
          loading={isLoading}
          pagination={{ pageSize: 20, showSizeChanger: true }}
          bordered
          size="middle"
        />
      </Card>

      {/* Modal tạo ủy quyền */}
      <Modal
        title="Thêm ủy quyền"
        open={modalOpen}
        onOk={handleCreate}
        onCancel={() => setModalOpen(false)}
        okText="Tạo"
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        confirmLoading={createMutation.isPending}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item
              name="fromUserId"
              label="Người ủy quyền"
              rules={[{ required: true, message: 'Chọn người ủy quyền' }]}
            >
              <Select showSearch placeholder="Tìm người dùng" options={userOptions} filterOption={(input, opt) =>
                (opt?.label as string ?? '').toLowerCase().includes(input.toLowerCase())
              } />
            </Form.Item>
            <Form.Item
              name="toUserId"
              label="Người nhận ủy quyền"
              rules={[{ required: true, message: 'Chọn người nhận' }]}
            >
              <Select showSearch placeholder="Tìm người dùng" options={userOptions} filterOption={(input, opt) =>
                (opt?.label as string ?? '').toLowerCase().includes(input.toLowerCase())
              } />
            </Form.Item>
            <Form.Item
              name="delegationType"
              label="Loại ủy quyền"
              rules={[{ required: true }]}
              initialValue="Full"
            >
              <Select options={DELEGATION_TYPES} />
            </Form.Item>
            <Form.Item
              noStyle
              shouldUpdate={(prev, cur) => prev.delegationType !== cur.delegationType}
            >
              {({ getFieldValue }) =>
                getFieldValue('delegationType') === 'Partial' ? (
                  <Form.Item
                    name="permissions"
                    label={'Quyền ủy quyền (JSON array, VD: ["Form.Edit"])'}

                    rules={[{ required: true, message: 'Nhập danh sách quyền' }]}
                  >
                    <Input.TextArea rows={2} placeholder='["Form.Edit","Submission.Submit"]' />
                  </Form.Item>
                ) : null
              }
            </Form.Item>
            <Form.Item
              name="validRange"
              label="Thời gian hiệu lực"
              rules={[{ required: true, message: 'Chọn khoảng thời gian' }]}
            >
              <DatePicker.RangePicker
                showTime
                format="DD/MM/YYYY HH:mm"
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="reason" label="Lý do (tùy chọn)">
              <Input.TextArea rows={2} placeholder="Lý do ủy quyền" />
            </Form.Item>
          </Form>
        </div>
      </Modal>

      {/* Modal thu hồi */}
      <Modal
        title="Thu hồi ủy quyền"
        open={revokeModalOpen}
        onOk={handleRevoke}
        onCancel={() => setRevokeModalOpen(false)}
        okText="Thu hồi"
        okButtonProps={{ danger: true }}
        cancelText="Hủy"
        width={MODAL_FORM.SMALL}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        confirmLoading={revokeMutation.isPending}
      >
        <Form form={revokeForm} layout="vertical" style={{ marginTop: 16 }}>
          <Form.Item name="revokedReason" label="Lý do thu hồi (tùy chọn)">
            <Input.TextArea rows={2} placeholder="Nhập lý do (tùy chọn)" />
          </Form.Item>
        </Form>
      </Modal>
    </>
  )
}
