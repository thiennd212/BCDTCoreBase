import React, { useState, useRef, useEffect } from 'react'
import { useNavigate } from 'react-router-dom'
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
  Select,
  message,
  Tag,
  Upload,
  Tooltip,
} from 'antd'
import {
  PlusOutlined,
  UploadOutlined,
  FormOutlined,
  SendOutlined,
  CheckOutlined,
  CloseOutlined,
  EditOutlined,
  CheckCircleOutlined,
} from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { submissionsApi } from '../api/submissionsApi'
import { workflowInstancesApi, type BulkApproveResultDto } from '../api/workflowInstancesApi'
import { formsApi } from '../api/formsApi'
import { organizationsApi } from '../api/organizationsApi'
import { reportingPeriodsApi } from '../api/reportingPeriodsApi'
import type { ReportSubmissionDto, CreateReportSubmissionRequest } from '../types/submission.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON_MANY } from '../constants/tableActions'
import { TableActions, type TableActionItem } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text } = Typography

const statusColors: Record<string, string> = {
  Draft: 'default',
  Submitted: 'processing',
  Approved: 'success',
  Rejected: 'error',
  Revision: 'warning',
}

export function SubmissionsPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [form] = Form.useForm<CreateReportSubmissionRequest>()
  const [modalOpen, setModalOpen] = useState(false)
  const [filterFormId, setFilterFormId] = useState<number | undefined>()
  const [filterPeriodId, setFilterPeriodId] = useState<number | undefined>()
  const [filterStatus, setFilterStatus] = useState<string | undefined>()
  const [workflowModalOpen, setWorkflowModalOpen] = useState(false)
  const [workflowAction, setWorkflowAction] = useState<'approve' | 'reject' | 'revision' | null>(null)
  const [workflowInstanceId, setWorkflowInstanceId] = useState<number | null>(null)
  const [workflowComments, setWorkflowComments] = useState('')
  const [selectedRowKeys, setSelectedRowKeys] = useState<React.Key[]>([])
  const [bulkModalOpen, setBulkModalOpen] = useState(false)
  const [bulkComments, setBulkComments] = useState('')
  const formContainerRef = useRef<HTMLDivElement>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  const { data: submissions = [], isLoading, error } = useQuery({
    queryKey: ['submissions', filterFormId, filterPeriodId, filterStatus],
    queryFn: () =>
      submissionsApi.getList({
        formDefinitionId: filterFormId,
        reportingPeriodId: filterPeriodId,
        status: filterStatus,
        includeDeleted: false,
      }),
  })

  const { data: forms = [] } = useQuery({ queryKey: ['forms'], queryFn: () => formsApi.getList() })
  const { data: organizations = [] } = useQuery({ queryKey: ['organizations'], queryFn: () => organizationsApi.getList({ all: true }) })
  const { data: periods = [] } = useQuery({ queryKey: ['reporting-periods'], queryFn: () => reportingPeriodsApi.getList() })

  const createMutation = useMutation({
    mutationFn: submissionsApi.create,
    onSuccess: () => {
      message.success('Tạo báo cáo thành công')
      queryClient.invalidateQueries({ queryKey: ['submissions'] })
      setModalOpen(false)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo báo cáo thất bại'),
  })

  const submitMutation = useMutation({
    mutationFn: (id: number) => submissionsApi.submit(id),
    onSuccess: () => {
      message.success('Đã gửi duyệt')
      queryClient.invalidateQueries({ queryKey: ['submissions'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Gửi duyệt thất bại'),
  })

  const uploadMutation = useMutation({
    mutationFn: ({ id, file }: { id: number; file: File }) => submissionsApi.uploadExcel(id, file),
    onSuccess: () => {
      message.success('Upload Excel thành công')
      queryClient.invalidateQueries({ queryKey: ['submissions'] })
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Upload thất bại'),
  })

  const approveMutation = useMutation({
    mutationFn: ({ id, comments }: { id: number; comments?: string }) =>
      workflowInstancesApi.approve(id, comments ? { comments } : undefined),
    onSuccess: () => {
      message.success('Đã duyệt')
      queryClient.invalidateQueries({ queryKey: ['submissions'] })
      setWorkflowModalOpen(false)
      setWorkflowInstanceId(null)
      setWorkflowAction(null)
      setWorkflowComments('')
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Duyệt thất bại'),
  })

  const rejectMutation = useMutation({
    mutationFn: ({ id, comments }: { id: number; comments?: string }) =>
      workflowInstancesApi.reject(id, comments ? { comments } : undefined),
    onSuccess: () => {
      message.success('Đã từ chối')
      queryClient.invalidateQueries({ queryKey: ['submissions'] })
      setWorkflowModalOpen(false)
      setWorkflowInstanceId(null)
      setWorkflowAction(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Từ chối thất bại'),
  })

  const revisionMutation = useMutation({
    mutationFn: ({ id, comments }: { id: number; comments?: string }) =>
      workflowInstancesApi.requestRevision(id, comments ? { comments } : undefined),
    onSuccess: () => {
      message.success('Đã yêu cầu chỉnh sửa')
      queryClient.invalidateQueries({ queryKey: ['submissions'] })
      setWorkflowModalOpen(false)
      setWorkflowInstanceId(null)
      setWorkflowAction(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Yêu cầu chỉnh sửa thất bại'),
  })

  const bulkApproveMutation = useMutation({
    mutationFn: ({ wfIds, comments }: { wfIds: number[]; comments?: string }) =>
      workflowInstancesApi.bulkApprove({ workflowInstanceIds: wfIds, comments }),
    onSuccess: (data: BulkApproveResultDto) => {
      if (data.failed.length === 0) {
        message.success(`Đã duyệt ${data.succeededIds.length} báo cáo`)
      } else {
        message.warning(`Duyệt ${data.succeededIds.length} thành công, ${data.failed.length} thất bại`)
      }
      queryClient.invalidateQueries({ queryKey: ['submissions'] })
      setBulkModalOpen(false)
      setBulkComments('')
      setSelectedRowKeys([])
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Duyệt hàng loạt thất bại'),
  })

  const [selectedFormIdForVersion, setSelectedFormIdForVersion] = useState<number | null>(null)
  const { data: formVersions = [] } = useQuery({
    queryKey: ['form-versions', selectedFormIdForVersion],
    queryFn: () => formsApi.getVersions(selectedFormIdForVersion!),
    enabled: selectedFormIdForVersion != null && selectedFormIdForVersion > 0,
  })

  useEffect(() => {
    if (modalOpen && formVersions.length > 0 && form.getFieldValue('formVersionId') == null) {
      form.setFieldValue('formVersionId', formVersions[0].id)
    }
  }, [modalOpen, formVersions])

  const openCreate = () => {
    const firstForm = forms[0]
    form.setFieldsValue({
      formDefinitionId: firstForm?.id ?? undefined,
      formVersionId: undefined,
      organizationId: undefined,
      reportingPeriodId: periods[0]?.id ?? undefined,
    })
    setSelectedFormIdForVersion(firstForm?.id ?? null)
    setModalOpen(true)
  }

  const handleCreateSubmit = async () => {
    const values = await form.validateFields()
    createMutation.mutate({
      formDefinitionId: values.formDefinitionId,
      formVersionId: values.formVersionId ?? formVersions[0]?.id ?? 0,
      organizationId: values.organizationId,
      reportingPeriodId: values.reportingPeriodId,
      status: 'Draft',
    })
  }

  const openWorkflowModal = async (submissionId: number, action: 'approve' | 'reject' | 'revision') => {
    try {
      const instance = await submissionsApi.getWorkflowInstance(submissionId)
      if (!instance) {
        message.error('Không tìm thấy luồng duyệt')
        return
      }
      setWorkflowInstanceId(instance.id)
      setWorkflowAction(action)
      setWorkflowComments('')
      setWorkflowModalOpen(true)
    } catch (e) {
      message.error((e as Error).message || 'Không thể tải thông tin duyệt')
    }
  }

  const handleWorkflowOk = () => {
    if (workflowInstanceId == null || workflowAction == null) return
    if (workflowAction === 'approve') approveMutation.mutate({ id: workflowInstanceId, comments: workflowComments })
    else if (workflowAction === 'reject') rejectMutation.mutate({ id: workflowInstanceId, comments: workflowComments })
    else revisionMutation.mutate({ id: workflowInstanceId, comments: workflowComments })
  }

  const handleBulkApprove = () => {
    const selectedSubmissions = submissions.filter((s) => selectedRowKeys.includes(s.id) && s.status === 'Submitted')
    const wfIds = selectedSubmissions.map((s) => s.workflowInstanceId).filter((id): id is number => id != null)
    if (wfIds.length === 0) {
      message.warning('Không có báo cáo đã gửi duyệt nào được chọn')
      return
    }
    setBulkModalOpen(true)
  }

  const selectedSubmitted = submissions.filter((s) => selectedRowKeys.includes(s.id) && s.status === 'Submitted')

  const rowSelection = {
    selectedRowKeys,
    onChange: (keys: React.Key[]) => setSelectedRowKeys(keys),
    getCheckboxProps: (record: ReportSubmissionDto) => ({
      disabled: record.status !== 'Submitted',
    }),
  }

  const formOptions = forms.map((f) => ({ value: f.id, label: `${f.code} - ${f.name}` }))
  const orgOptions = organizations.map((o) => ({ value: o.id, label: `${o.code} - ${o.name}` }))
  const periodOptions = periods.map((p) => ({ value: p.id, label: `${p.periodCode} - ${p.periodName}` }))

  const columns = [
    { title: 'ID', dataIndex: 'id', key: 'id', width: 70 },
    { title: 'Form', dataIndex: 'formDefinitionId', key: 'formDefinitionId', width: 80 },
    { title: 'Đơn vị', dataIndex: 'organizationId', key: 'organizationId', width: 80 },
    { title: 'Kỳ', dataIndex: 'reportingPeriodId', key: 'reportingPeriodId', width: 80 },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (v: string) => <Tag color={statusColors[v] ?? 'default'}>{v}</Tag>,
    },
    { title: 'Ngày tạo', dataIndex: 'createdAt', key: 'createdAt', width: 110, render: (v: string) => v?.slice(0, 10) },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON_MANY,
      align: 'right' as const,
      render: (_: unknown, record: ReportSubmissionDto) => {
        const items: TableActionItem[] = []
        if (record.status === 'Draft' || record.status === 'Revision') {
          items.push({
            key: 'entry',
            label: 'Nhập liệu',
            icon: <FormOutlined />,
            onClick: () => navigate(`/submissions/${record.id}/entry`),
          })
        }
        if (record.status === 'Draft') {
          items.push({
            key: 'submit',
            label: 'Gửi duyệt',
            icon: <SendOutlined />,
            onClick: () => submitMutation.mutate(record.id),
          })
        }
        if (record.status === 'Submitted') {
          items.push({
            key: 'approve',
            label: 'Duyệt',
            icon: <CheckOutlined />,
            onClick: () => openWorkflowModal(record.id, 'approve'),
          })
          items.push({
            key: 'reject',
            label: 'Từ chối',
            icon: <CloseOutlined />,
            danger: true,
            onClick: () => openWorkflowModal(record.id, 'reject'),
          })
          items.push({
            key: 'revision',
            label: 'Yêu cầu sửa',
            icon: <EditOutlined />,
            onClick: () => openWorkflowModal(record.id, 'revision'),
          })
        }
        return (
          <Space size="small" wrap={false} style={{ justifyContent: 'flex-end', width: '100%' }}>
            <TableActions items={items} align="right" />
            {record.status === 'Draft' && (
              <Upload
                showUploadList={false}
                accept=".xlsx,.xls"
                beforeUpload={(file) => {
                  uploadMutation.mutate({ id: record.id, file })
                  return false
                }}
              >
                <Tooltip title="Upload Excel">
                  <Button type="link" size="small" icon={<UploadOutlined />} />
                </Tooltip>
              </Upload>
            )}
          </Space>
        )
      },
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
        Báo cáo
      </Typography.Title>
      <Card>
        <Space style={{ marginBottom: 16 }} wrap>
          <Select
            placeholder="Lọc theo biểu mẫu"
            allowClear
            style={{ width: 200 }}
            value={filterFormId}
            onChange={setFilterFormId}
            options={formOptions}
          />
          <Select
            placeholder="Lọc theo kỳ"
            allowClear
            style={{ width: 200 }}
            value={filterPeriodId}
            onChange={setFilterPeriodId}
            options={periodOptions}
          />
          <Select
            placeholder="Trạng thái"
            allowClear
            style={{ width: 120 }}
            value={filterStatus}
            onChange={setFilterStatus}
            options={[
              { value: 'Draft', label: 'Nháp' },
              { value: 'Submitted', label: 'Đã gửi' },
              { value: 'Approved', label: 'Đã duyệt' },
              { value: 'Rejected', label: 'Từ chối' },
              { value: 'Revision', label: 'Chỉnh sửa' },
            ]}
          />
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Tạo báo cáo
          </Button>
          {selectedSubmitted.length > 0 && (
            <Button
              type="primary"
              icon={<CheckCircleOutlined />}
              onClick={handleBulkApprove}
            >
              Duyệt hàng loạt ({selectedSubmitted.length})
            </Button>
          )}
        </Space>
        <Table
          rowKey="id"
          rowSelection={rowSelection}
          columns={columns}
          dataSource={submissions}
          loading={isLoading}
          pagination={{ pageSize: 10, showSizeChanger: true }}
          bordered
        />
      </Card>

      <Modal
        title="Tạo báo cáo"
        open={modalOpen}
        onOk={handleCreateSubmit}
        onCancel={() => setModalOpen(false)}
        okText="Tạo"
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="formDefinitionId" label="Biểu mẫu" rules={[{ required: true }]}>
              <Select
                options={formOptions}
                placeholder="Chọn biểu mẫu"
                onChange={(id) => {
                  setSelectedFormIdForVersion(id ?? null)
                  form.setFieldValue('formVersionId', undefined)
                }}
              />
            </Form.Item>
            <Form.Item name="formVersionId" label="Phiên bản" rules={[{ required: true }]}>
              <Select
                placeholder="Chọn phiên bản"
                options={formVersions.map((v) => ({ value: v.id, label: `${v.versionName}${v.isActive ? ' (đang dùng)' : ''}` }))}
                loading={selectedFormIdForVersion != null && formVersions.length === 0}
              />
            </Form.Item>
            <Form.Item name="organizationId" label="Đơn vị" rules={[{ required: true }]}>
              <Select options={orgOptions} placeholder="Chọn đơn vị" />
            </Form.Item>
            <Form.Item name="reportingPeriodId" label="Kỳ báo cáo" rules={[{ required: true }]}>
              <Select options={periodOptions} placeholder="Chọn kỳ" />
            </Form.Item>
          </Form>
        </div>
      </Modal>

      <Modal
        title={`Duyệt hàng loạt ${selectedSubmitted.length} báo cáo`}
        open={bulkModalOpen}
        onOk={() => {
          const wfIds = selectedSubmitted.map((s) => s.workflowInstanceId).filter((id): id is number => id != null)
          bulkApproveMutation.mutate({ wfIds, comments: bulkComments || undefined })
        }}
        onCancel={() => { setBulkModalOpen(false); setBulkComments('') }}
        okText="Duyệt tất cả"
        cancelText="Hủy"
        confirmLoading={bulkApproveMutation.isPending}
      >
        <Form layout="vertical">
          <Form.Item label="Nhận xét (tùy chọn)">
            <Input.TextArea
              rows={3}
              value={bulkComments}
              onChange={(e) => setBulkComments(e.target.value)}
              placeholder="Nhập nhận xét nếu cần"
            />
          </Form.Item>
        </Form>
      </Modal>

      <Modal
        title={
          workflowAction === 'approve'
            ? 'Duyệt báo cáo'
            : workflowAction === 'reject'
              ? 'Từ chối báo cáo'
              : 'Yêu cầu chỉnh sửa'
        }
        open={workflowModalOpen}
        onOk={handleWorkflowOk}
        onCancel={() => {
          setWorkflowModalOpen(false)
          setWorkflowInstanceId(null)
          setWorkflowAction(null)
        }}
        okText={workflowAction === 'approve' ? 'Duyệt' : workflowAction === 'reject' ? 'Từ chối' : 'Gửi yêu cầu'}
        cancelText="Hủy"
      >
        <Form layout="vertical">
          <Form.Item label="Nhận xét (tùy chọn)">
            <Input.TextArea
              rows={3}
              value={workflowComments}
              onChange={(e) => setWorkflowComments(e.target.value)}
              placeholder="Nhập nhận xét nếu cần"
            />
          </Form.Item>
        </Form>
      </Modal>
    </>
  )
}
