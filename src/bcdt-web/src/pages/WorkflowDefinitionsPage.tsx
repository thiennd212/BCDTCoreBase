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
  Checkbox,
  Select,
  message,
  Tag,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, UnorderedListOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { workflowDefinitionsApi, workflowStepsApi } from '../api/workflowDefinitionsApi'
import type {
  WorkflowDefinitionDto,
  CreateWorkflowDefinitionRequest,
  WorkflowStepDto,
  CreateWorkflowStepRequest,
} from '../types/workflow.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

/* ---------- Default values ---------- */

const defaultWfCreate: CreateWorkflowDefinitionRequest = {
  code: '',
  name: '',
  description: '',
  totalSteps: 1,
  isDefault: false,
  isActive: true,
}

const defaultStepCreate: CreateWorkflowStepRequest = {
  stepOrder: 1,
  stepName: '',
  stepDescription: '',
  approverRoleId: null,
  approverUserId: null,
  canReject: true,
  canRequestRevision: true,
  autoApproveAfterDays: null,
  notifyOnPending: true,
  notifyOnApprove: true,
  notifyOnReject: true,
  isActive: true,
}

/* ---------- Roles (static mapping for display) ---------- */
const ROLE_OPTIONS = [
  { value: 1, label: 'SYSTEM_ADMIN' },
  { value: 2, label: 'FORM_ADMIN' },
  { value: 3, label: 'UNIT_ADMIN' },
  { value: 4, label: 'DATA_ENTRY' },
  { value: 5, label: 'VIEWER' },
]

export function WorkflowDefinitionsPage() {
  const queryClient = useQueryClient()

  /* ---- Workflow Definition state ---- */
  const [wfForm] = Form.useForm<CreateWorkflowDefinitionRequest & { id?: number }>()
  const [wfModalOpen, setWfModalOpen] = useState(false)
  const [editingWfId, setEditingWfId] = useState<number | null>(null)
  const wfRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(wfModalOpen, wfRef)
  useScrollPageTopWhenModalOpen(wfModalOpen)

  /* ---- Step state ---- */
  const [stepForm] = Form.useForm<CreateWorkflowStepRequest & { id?: number }>()
  const [stepModalOpen, setStepModalOpen] = useState(false)
  const [editingStepId, setEditingStepId] = useState<number | null>(null)
  const [selectedWfId, setSelectedWfId] = useState<number | null>(null)
  const stepRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(stepModalOpen, stepRef)
  useScrollPageTopWhenModalOpen(stepModalOpen)

  /* ---- Queries ---- */
  const { data: definitions = [], isLoading } = useQuery({
    queryKey: ['workflow-definitions'],
    queryFn: () => workflowDefinitionsApi.getList({ includeInactive: true }),
  })

  const { data: steps = [] } = useQuery({
    queryKey: ['workflow-steps', selectedWfId],
    queryFn: () => (selectedWfId ? workflowStepsApi.getList(selectedWfId) : Promise.resolve([])),
    enabled: !!selectedWfId,
  })

  /* ---- Workflow mutations ---- */
  const createWfMut = useMutation({
    mutationFn: workflowDefinitionsApi.create,
    onSuccess: () => {
      message.success('Tạo quy trình thành công')
      queryClient.invalidateQueries({ queryKey: ['workflow-definitions'] })
      setWfModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo quy trình thất bại'),
  })

  const updateWfMut = useMutation({
    mutationFn: ({ id, body }: { id: number; body: CreateWorkflowDefinitionRequest }) =>
      workflowDefinitionsApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật quy trình thành công')
      queryClient.invalidateQueries({ queryKey: ['workflow-definitions'] })
      setWfModalOpen(false)
      setEditingWfId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteWfMut = useMutation({
    mutationFn: workflowDefinitionsApi.delete,
    onSuccess: () => {
      message.success('Đã xóa quy trình')
      queryClient.invalidateQueries({ queryKey: ['workflow-definitions'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  /* ---- Step mutations ---- */
  const createStepMut = useMutation({
    mutationFn: ({ wfId, body }: { wfId: number; body: CreateWorkflowStepRequest }) =>
      workflowStepsApi.create(wfId, body),
    onSuccess: () => {
      message.success('Tạo bước duyệt thành công')
      queryClient.invalidateQueries({ queryKey: ['workflow-steps', selectedWfId] })
      setStepModalOpen(false)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo bước thất bại'),
  })

  const updateStepMut = useMutation({
    mutationFn: ({ wfId, stepId, body }: { wfId: number; stepId: number; body: CreateWorkflowStepRequest }) =>
      workflowStepsApi.update(wfId, stepId, body),
    onSuccess: () => {
      message.success('Cập nhật bước duyệt thành công')
      queryClient.invalidateQueries({ queryKey: ['workflow-steps', selectedWfId] })
      setStepModalOpen(false)
      setEditingStepId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteStepMut = useMutation({
    mutationFn: ({ wfId, stepId }: { wfId: number; stepId: number }) => workflowStepsApi.delete(wfId, stepId),
    onSuccess: () => {
      message.success('Đã xóa bước duyệt')
      queryClient.invalidateQueries({ queryKey: ['workflow-steps', selectedWfId] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  /* ---- Effects ---- */
  useEffect(() => {
    if (!wfModalOpen) setEditingWfId(null)
  }, [wfModalOpen])

  useEffect(() => {
    if (!stepModalOpen) setEditingStepId(null)
  }, [stepModalOpen])

  /* ---- Workflow handlers ---- */
  const openCreateWf = () => {
    wfForm.setFieldsValue({ ...defaultWfCreate })
    setEditingWfId(null)
    setWfModalOpen(true)
  }

  const openEditWf = (record: WorkflowDefinitionDto) => {
    setEditingWfId(record.id)
    wfForm.setFieldsValue({
      code: record.code,
      name: record.name,
      description: record.description ?? '',
      totalSteps: record.totalSteps,
      isDefault: record.isDefault,
      isActive: record.isActive,
    })
    setWfModalOpen(true)
  }

  const handleSubmitWf = async () => {
    const values = await wfForm.validateFields()
    const body: CreateWorkflowDefinitionRequest = {
      code: values.code,
      name: values.name,
      description: values.description || undefined,
      totalSteps: values.totalSteps,
      isDefault: values.isDefault ?? false,
      isActive: values.isActive ?? true,
    }
    if (editingWfId !== null) {
      updateWfMut.mutate({ id: editingWfId, body })
    } else {
      createWfMut.mutate(body)
    }
  }

  /* ---- Step handlers ---- */
  const openCreateStep = (wfId: number) => {
    setSelectedWfId(wfId)
    const nextOrder = Math.max(0, ...steps.map((s) => s.stepOrder ?? 0)) + 1
    stepForm.setFieldsValue({ ...defaultStepCreate, stepOrder: nextOrder })
    setEditingStepId(null)
    setStepModalOpen(true)
  }

  const openEditStep = (record: WorkflowStepDto) => {
    setSelectedWfId(record.workflowDefinitionId)
    setEditingStepId(record.id)
    stepForm.setFieldsValue({
      stepOrder: record.stepOrder,
      stepName: record.stepName,
      stepDescription: record.stepDescription ?? '',
      approverRoleId: record.approverRoleId,
      approverUserId: record.approverUserId,
      canReject: record.canReject,
      canRequestRevision: record.canRequestRevision,
      autoApproveAfterDays: record.autoApproveAfterDays,
      notifyOnPending: record.notifyOnPending,
      notifyOnApprove: record.notifyOnApprove,
      notifyOnReject: record.notifyOnReject,
      isActive: record.isActive,
    })
    setStepModalOpen(true)
  }

  const handleSubmitStep = async () => {
    if (!selectedWfId) return
    const values = await stepForm.validateFields()
    const body: CreateWorkflowStepRequest = {
      stepOrder: values.stepOrder,
      stepName: values.stepName,
      stepDescription: values.stepDescription || undefined,
      approverRoleId: values.approverRoleId ?? null,
      approverUserId: values.approverUserId ?? null,
      canReject: values.canReject ?? true,
      canRequestRevision: values.canRequestRevision ?? true,
      autoApproveAfterDays: values.autoApproveAfterDays ?? null,
      notifyOnPending: values.notifyOnPending ?? true,
      notifyOnApprove: values.notifyOnApprove ?? true,
      notifyOnReject: values.notifyOnReject ?? true,
      isActive: values.isActive ?? true,
    }
    if (editingStepId !== null) {
      updateStepMut.mutate({ wfId: selectedWfId, stepId: editingStepId, body })
    } else {
      createStepMut.mutate({ wfId: selectedWfId, body })
    }
  }

  /* ---- Workflow columns ---- */
  const wfColumns = [
    { title: 'Mã', dataIndex: 'code', key: 'code', width: 140, ellipsis: true },
    { title: 'Tên quy trình', dataIndex: 'name', key: 'name', ellipsis: true },
    { title: 'Số bước', dataIndex: 'totalSteps', key: 'totalSteps', width: 90, align: 'center' as const },
    {
      title: 'Mặc định',
      dataIndex: 'isDefault',
      key: 'isDefault',
      width: 100,
      align: 'center' as const,
      render: (v: boolean) => (v ? <Tag color="blue">Có</Tag> : '—'),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 100,
      align: 'center' as const,
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? 'Hoạt động' : 'Tắt'}</Tag>,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: WorkflowDefinitionDto) => (
        <TableActions
          align="right"
          items={[
            {
              key: 'steps',
              label: 'Quản lý bước duyệt',
              icon: <UnorderedListOutlined />,
              onClick: () => {
                setSelectedWfId(record.id)
              },
            },
            { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditWf(record) },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: {
                title: 'Xóa quy trình?',
                description: 'Không thể khôi phục sau khi xóa.',
                okText: 'Xóa',
                cancelText: 'Hủy',
              },
              onClick: () => deleteWfMut.mutate(record.id),
            },
          ]}
        />
      ),
    },
  ]

  /* ---- Step columns ---- */
  const stepColumns = [
    { title: 'Thứ tự', dataIndex: 'stepOrder', key: 'stepOrder', width: 80, align: 'center' as const },
    { title: 'Tên bước', dataIndex: 'stepName', key: 'stepName', ellipsis: true },
    {
      title: 'Role duyệt',
      dataIndex: 'approverRoleCode',
      key: 'approverRoleCode',
      width: 140,
      render: (v: string | null) => v || '—',
    },
    {
      title: 'Từ chối',
      dataIndex: 'canReject',
      key: 'canReject',
      width: 80,
      align: 'center' as const,
      render: (v: boolean) => (v ? 'Có' : '—'),
    },
    {
      title: 'Yêu cầu sửa',
      dataIndex: 'canRequestRevision',
      key: 'canRequestRevision',
      width: 100,
      align: 'center' as const,
      render: (v: boolean) => (v ? 'Có' : '—'),
    },
    {
      title: 'Trạng thái',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 100,
      align: 'center' as const,
      render: (v: boolean) => <Tag color={v ? 'green' : 'default'}>{v ? 'Hoạt động' : 'Tắt'}</Tag>,
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: WorkflowStepDto) => (
        <TableActions
          align="right"
          items={[
            { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEditStep(record) },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: {
                title: 'Xóa bước duyệt?',
                okText: 'Xóa',
                cancelText: 'Hủy',
              },
              onClick: () =>
                selectedWfId && deleteStepMut.mutate({ wfId: selectedWfId, stepId: record.id }),
            },
          ]}
        />
      ),
    },
  ]

  const selectedWf = definitions.find((d) => d.id === selectedWfId)

  return (
    <>
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Quy trình phê duyệt
      </Typography.Title>

      {/* ---- Workflow Definitions ---- */}
      <Card>
        <Button type="primary" icon={<PlusOutlined />} onClick={openCreateWf} style={{ marginBottom: 16 }}>
          Thêm quy trình
        </Button>
        <Table
          rowKey="id"
          columns={wfColumns}
          dataSource={definitions}
          loading={isLoading}
          pagination={{ pageSize: 10, showSizeChanger: true, showTotal: (t) => `Tổng ${t} bản ghi` }}
          bordered
          size="middle"
          onRow={(record) => ({
            onClick: () => setSelectedWfId(record.id),
            style: { cursor: 'pointer', background: record.id === selectedWfId ? '#e6f4ff' : undefined },
          })}
        />
      </Card>

      {/* ---- Workflow Steps (expandable below) ---- */}
      {selectedWfId && (
        <Card style={{ marginTop: 16 }} title={`Các bước duyệt – ${selectedWf?.name ?? ''}`}>
          <Button
            type="primary"
            icon={<PlusOutlined />}
            onClick={() => openCreateStep(selectedWfId)}
            style={{ marginBottom: 16 }}
          >
            Thêm bước duyệt
          </Button>
          <Table
            rowKey="id"
            columns={stepColumns}
            dataSource={steps}
            pagination={false}
            bordered
            size="middle"
          />
        </Card>
      )}

      {/* ---- Workflow Definition Modal ---- */}
      <Modal
        title={editingWfId !== null ? 'Sửa quy trình' : 'Thêm quy trình'}
        open={wfModalOpen}
        onOk={handleSubmitWf}
        onCancel={() => setWfModalOpen(false)}
        okText={editingWfId !== null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        confirmLoading={createWfMut.isPending || updateWfMut.isPending}
      >
        <div ref={wfRef}>
          <Form form={wfForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã quy trình" rules={[{ required: true, message: 'Nhập mã' }]}>
              <Input placeholder="VD: WF_DUYET_2CAP" disabled={editingWfId !== null} />
            </Form.Item>
            <Form.Item name="name" label="Tên quy trình" rules={[{ required: true, message: 'Nhập tên' }]}>
              <Input placeholder="VD: Quy trình duyệt 2 cấp" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea rows={2} placeholder="Mô tả (tùy chọn)" />
            </Form.Item>
            <Form.Item name="totalSteps" label="Số bước duyệt" rules={[{ required: true }]}>
              <InputNumber min={1} max={5} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isDefault" valuePropName="checked">
              <Checkbox>Quy trình mặc định</Checkbox>
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked">
              <Checkbox>Đang hoạt động</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>

      {/* ---- Step Modal ---- */}
      <Modal
        title={editingStepId !== null ? 'Sửa bước duyệt' : 'Thêm bước duyệt'}
        open={stepModalOpen}
        onOk={handleSubmitStep}
        onCancel={() => setStepModalOpen(false)}
        okText={editingStepId !== null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        confirmLoading={createStepMut.isPending || updateStepMut.isPending}
      >
        <div ref={stepRef}>
          <Form form={stepForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="stepOrder" label="Thứ tự bước" rules={[{ required: true }]}>
              <InputNumber min={1} max={10} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="stepName" label="Tên bước" rules={[{ required: true, message: 'Nhập tên bước' }]}>
              <Input placeholder="VD: Trưởng phòng duyệt" />
            </Form.Item>
            <Form.Item name="stepDescription" label="Mô tả">
              <Input.TextArea rows={2} placeholder="Mô tả bước (tùy chọn)" />
            </Form.Item>
            <Form.Item name="approverRoleId" label="Role phê duyệt">
              <Select
                allowClear
                placeholder="Chọn role (tùy chọn)"
                options={ROLE_OPTIONS}
              />
            </Form.Item>
            <Form.Item name="canReject" valuePropName="checked">
              <Checkbox>Cho phép từ chối</Checkbox>
            </Form.Item>
            <Form.Item name="canRequestRevision" valuePropName="checked">
              <Checkbox>Cho phép yêu cầu chỉnh sửa</Checkbox>
            </Form.Item>
            <Form.Item name="autoApproveAfterDays" label="Tự động duyệt sau (ngày)">
              <InputNumber min={1} style={{ width: '100%' }} placeholder="Để trống nếu không dùng" />
            </Form.Item>
            <Form.Item name="notifyOnPending" valuePropName="checked">
              <Checkbox>Thông báo khi chờ duyệt</Checkbox>
            </Form.Item>
            <Form.Item name="notifyOnApprove" valuePropName="checked">
              <Checkbox>Thông báo khi duyệt</Checkbox>
            </Form.Item>
            <Form.Item name="notifyOnReject" valuePropName="checked">
              <Checkbox>Thông báo khi từ chối</Checkbox>
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
