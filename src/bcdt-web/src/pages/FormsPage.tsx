import { useState, useRef, useEffect } from 'react'
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
  InputNumber,
  Checkbox,
  message,
  Tag,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, SettingOutlined, UploadOutlined, DownloadOutlined, CopyOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { QueryErrorDisplay } from '../components/ErrorPage'
import { formsApi } from '../api/formsApi'
import { reportingFrequenciesApi } from '../api/reportingFrequenciesApi'
import type {
  FormDefinitionDto,
  CreateFormDefinitionRequest,
  UpdateFormDefinitionRequest,
} from '../types/form.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'
import { useFocusFirstInModal } from '../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../hooks/useScrollPageTopWhenModalOpen'

const { Text } = Typography

const defaultCreate: CreateFormDefinitionRequest = {
  code: '',
  name: '',
  description: '',
  formType: 'Input',
  reportingFrequencyId: undefined,
  deadlineOffsetDays: 5,
  allowLateSubmission: true,
  requireApproval: true,
  autoCreateReport: false,
  isActive: true,
}

export function FormsPage() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [form] = Form.useForm<CreateFormDefinitionRequest & { status?: string }>()
  const [templateForm] = Form.useForm<{ name: string; code?: string }>()
  const [cloneForm] = Form.useForm<{ newCode: string; newName: string }>()
  const [modalOpen, setModalOpen] = useState(false)
  const [templateModalOpen, setTemplateModalOpen] = useState(false)
  const [cloneModalOpen, setCloneModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [selectedFormId, setSelectedFormId] = useState<number | null>(null)
  const [cloningRecord, setCloningRecord] = useState<FormDefinitionDto | null>(null)
  const formContainerRef = useRef<HTMLDivElement>(null)
  const templateFormRef = useRef<HTMLDivElement>(null)
  const cloneFormRef = useRef<HTMLDivElement>(null)
  const templateFileInputRef = useRef<HTMLInputElement>(null)
  const [templateFile, setTemplateFile] = useState<File | null>(null)
  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)
  useFocusFirstInModal(templateModalOpen, templateFormRef)
  useScrollPageTopWhenModalOpen(templateModalOpen)
  useFocusFirstInModal(cloneModalOpen, cloneFormRef)
  useScrollPageTopWhenModalOpen(cloneModalOpen)

  const { data: forms = [], isLoading, error } = useQuery({
    queryKey: ['forms'],
    queryFn: () => formsApi.getList({ includeInactive: true }),
  })

  const { data: versions = [] } = useQuery({
    queryKey: ['forms', selectedFormId, 'versions'],
    queryFn: () => formsApi.getVersions(selectedFormId!),
    enabled: selectedFormId != null,
  })

  const { data: frequencies = [] } = useQuery({
    queryKey: ['reporting-frequencies'],
    queryFn: () => reportingFrequenciesApi.getList(),
  })

  const createMutation = useMutation({
    mutationFn: formsApi.create,
    onSuccess: () => {
      message.success('Tạo biểu mẫu thành công')
      queryClient.invalidateQueries({ queryKey: ['forms'] })
      setModalOpen(false)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo biểu mẫu thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateFormDefinitionRequest }) =>
      formsApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật biểu mẫu thành công')
      queryClient.invalidateQueries({ queryKey: ['forms'] })
      setModalOpen(false)
      setEditingId(null)
      form.resetFields()
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Cập nhật thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: formsApi.delete,
    onSuccess: () => {
      message.success('Đã xóa biểu mẫu')
      queryClient.invalidateQueries({ queryKey: ['forms'] })
      if (selectedFormId != null) setSelectedFormId(null)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Xóa thất bại'),
  })

  const cloneMutation = useMutation({
    mutationFn: ({ id, body }: { id: number; body: { newCode: string; newName: string } }) =>
      formsApi.clone(id, body),
    onSuccess: (data) => {
      message.success('Nhân bản biểu mẫu thành công')
      queryClient.invalidateQueries({ queryKey: ['forms'] })
      setCloneModalOpen(false)
      setCloningRecord(null)
      cloneForm.resetFields()
      navigate(`/forms/${data.id}/config`)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Nhân bản thất bại'),
  })

  const createFromTemplateMutation = useMutation({
    mutationFn: ({ file, name, code }: { file: File; name: string; code?: string }) =>
      formsApi.createFromTemplate(file, name, code),
    onSuccess: (data) => {
      message.success('Đã tạo biểu mẫu từ template. Số sheet và cột đã trích xuất từ file.')
      queryClient.invalidateQueries({ queryKey: ['forms'] })
      setTemplateModalOpen(false)
      setTemplateFile(null)
      templateForm.resetFields()
      navigate(`/forms/${data.id}/config`)
    },
    onError: (err) => message.error(getApiErrorMessage(err) || 'Tạo từ template thất bại'),
  })

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const openCreate = () => {
    form.setFieldsValue({ ...defaultCreate })
    setEditingId(null)
    setModalOpen(true)
  }

  const openEdit = (record: FormDefinitionDto) => {
    setEditingId(record.id)
    form.setFieldsValue({
      code: record.code,
      name: record.name,
      description: record.description ?? '',
      formType: record.formType ?? 'Input',
      reportingFrequencyId: record.reportingFrequencyId ?? undefined,
      deadlineOffsetDays: record.deadlineOffsetDays ?? 5,
      allowLateSubmission: record.allowLateSubmission ?? true,
      requireApproval: record.requireApproval ?? true,
      autoCreateReport: record.autoCreateReport ?? false,
      isActive: record.isActive ?? !record.isDeleted,
      status: record.status ?? 'Draft',
    })
    setModalOpen(true)
  }

  const openClone = (record: FormDefinitionDto) => {
    setCloningRecord(record)
    cloneForm.setFieldsValue({ newCode: `${record.code}_COPY`, newName: `${record.name} (bản sao)` })
    setCloneModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await form.validateFields()
    if (editingId !== null) {
      const body: UpdateFormDefinitionRequest = {
        code: values.code,
        name: values.name,
        description: values.description || undefined,
        formType: values.formType ?? 'Input',
        reportingFrequencyId: values.reportingFrequencyId ?? undefined,
        deadlineOffsetDays: values.deadlineOffsetDays ?? 5,
        allowLateSubmission: values.allowLateSubmission ?? true,
        requireApproval: values.requireApproval ?? true,
        autoCreateReport: values.autoCreateReport ?? false,
        isActive: values.isActive ?? true,
        status: values.status ?? 'Draft',
      }
      updateMutation.mutate({ id: editingId, body })
    } else {
      createMutation.mutate({
        code: values.code,
        name: values.name,
        description: values.description || undefined,
        formType: values.formType ?? 'Input',
        reportingFrequencyId: values.reportingFrequencyId ?? undefined,
        deadlineOffsetDays: values.deadlineOffsetDays ?? 5,
        allowLateSubmission: values.allowLateSubmission ?? true,
        requireApproval: values.requireApproval ?? true,
        autoCreateReport: values.autoCreateReport ?? false,
        isActive: values.isActive ?? true,
      })
    }
  }

  const frequencyOptions = frequencies.map((f) => ({ value: f.id, label: `${f.code} - ${f.name}` }))

  const columns = [
    { title: 'Mã', dataIndex: 'code', key: 'code', width: 120, ellipsis: true },
    { title: 'Tên biểu mẫu', dataIndex: 'name', key: 'name', ellipsis: true },
    { title: 'Mô tả', dataIndex: 'description', key: 'description', ellipsis: true },
    {
      title: 'Trạng thái',
      dataIndex: 'status',
      key: 'status',
      width: 100,
      render: (v: string) => (
        <Tag color={v === 'Active' || v === 'Published' ? 'green' : v === 'Archived' ? 'default' : 'blue'}>
          {v === 'Published' ? 'Đã xuất bản' : v === 'Draft' ? 'Nháp' : v === 'Archived' ? 'Lưu trữ' : v}
        </Tag>
      ),
    },
    {
      title: 'Phiên bản',
      key: 'versions',
      width: 100,
      render: (_: unknown, record: FormDefinitionDto) => (
        <Typography.Link onClick={() => setSelectedFormId(record.id)}>Xem phiên bản</Typography.Link>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: FormDefinitionDto) => (
        <TableActions
          align="right"
          items={[
            {
              key: 'config',
              label: 'Cấu hình',
              icon: <SettingOutlined />,
              onClick: () => navigate(`/forms/${record.id}/config`),
            },
            ...(record.templateFileName
              ? [
                  {
                    key: 'download',
                    label: 'Tải template',
                    icon: <DownloadOutlined />,
                    onClick: () =>
                      formsApi
                        .downloadTemplate(record.id, record.templateFileName || `${record.code}_template.xlsx`)
                        .catch(() => message.error('Tải template thất bại')),
                  },
                ]
              : []),
            { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
            { key: 'clone', label: 'Nhân bản', icon: <CopyOutlined />, onClick: () => openClone(record) },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: {
                title: 'Xóa biểu mẫu',
                description: 'Bạn có chắc muốn xóa biểu mẫu này?',
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

  if (error) return <QueryErrorDisplay error={error} />

  return (
    <>
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Biểu mẫu
      </Typography.Title>
      <Card>
        <Space wrap style={{ marginBottom: 16 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm biểu mẫu
          </Button>
          <Button icon={<UploadOutlined />} onClick={() => { setTemplateModalOpen(true); setTemplateFile(null); templateForm.setFieldsValue({ name: '', code: '' }); }}>
            Tạo từ template Excel
          </Button>
        </Space>
        <Table
          rowKey="id"
          columns={columns}
          dataSource={forms}
          loading={isLoading}
          pagination={{ pageSize: 10, showSizeChanger: true }}
          bordered
        />
        {selectedFormId != null && (
          <Card
            size="small"
            title="Phiên bản"
            style={{ marginTop: 16 }}
            extra={
              <Typography.Link onClick={() => setSelectedFormId(null)}>Đóng</Typography.Link>
            }
          >
            <Table
              size="small"
              rowKey="id"
              dataSource={versions}
              columns={[
                { title: 'Tên phiên bản', dataIndex: 'versionName', key: 'versionName' },
                {
                  title: 'Mô tả thay đổi',
                  dataIndex: 'changeDescription',
                  key: 'changeDescription',
                  ellipsis: true,
                },
                {
                  title: 'Hoạt động',
                  dataIndex: 'isActive',
                  key: 'isActive',
                  width: 90,
                  render: (v: boolean) => (v ? 'Có' : 'Không'),
                },
              ]}
              pagination={false}
            />
          </Card>
        )}
      </Card>

      <Modal
        title={editingId !== null ? 'Sửa biểu mẫu' : 'Thêm biểu mẫu'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText={editingId !== null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
      >
        <div ref={formContainerRef}>
          <Form form={form} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã biểu mẫu" rules={[{ required: true, message: 'Nhập mã' }]}>
              <Input placeholder="VD: BM01" disabled={editingId != null} />
            </Form.Item>
            <Form.Item name="name" label="Tên biểu mẫu" rules={[{ required: true, message: 'Nhập tên' }]}>
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea rows={2} placeholder="Mô tả (tùy chọn)" />
            </Form.Item>
            <Form.Item name="formType" label="Loại biểu mẫu">
              <Select
                options={[
                  { value: 'Input', label: 'Nhập liệu' },
                  { value: 'Aggregate', label: 'Tổng hợp' },
                ]}
              />
            </Form.Item>
            <Form.Item name="reportingFrequencyId" label="Chu kỳ báo cáo">
              <Select allowClear placeholder="Chọn chu kỳ" options={frequencyOptions} />
            </Form.Item>
            <Form.Item name="deadlineOffsetDays" label="Số ngày trước hạn (offset)">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="allowLateSubmission" valuePropName="checked">
              <Checkbox>Cho phép nộp trễ</Checkbox>
            </Form.Item>
            <Form.Item name="requireApproval" valuePropName="checked">
              <Checkbox>Yêu cầu duyệt</Checkbox>
            </Form.Item>
            <Form.Item name="autoCreateReport" valuePropName="checked">
              <Checkbox>Tự tạo báo cáo</Checkbox>
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked">
              <Checkbox>Đang hoạt động</Checkbox>
            </Form.Item>
            {editingId !== null && (
              <Form.Item name="status" label="Trạng thái">
                <Select
                  options={[
                    { value: 'Draft', label: 'Nháp' },
                    { value: 'Published', label: 'Đã xuất bản' },
                    { value: 'Archived', label: 'Lưu trữ' },
                  ]}
                />
              </Form.Item>
            )}
          </Form>
        </div>
      </Modal>

      <Modal
        title="Tạo biểu mẫu từ template Excel"
        open={templateModalOpen}
        onOk={() => {
          if (!templateFile) {
            message.warning('Vui lòng chọn file Excel (.xlsx)')
            return
          }
          templateForm.validateFields().then((values) => {
            createFromTemplateMutation.mutate({
              file: templateFile,
              name: values.name,
              code: values.code?.trim() || undefined,
            })
          })
        }}
        onCancel={() => { setTemplateModalOpen(false); setTemplateFile(null); templateForm.resetFields(); }}
        okText="Tạo biểu mẫu"
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden
        confirmLoading={createFromTemplateMutation.isPending}
      >
        <div ref={templateFormRef}>
          <Text type="secondary" style={{ display: 'block', marginBottom: 12 }}>
            Chọn file Excel (.xlsx) đã soạn trong Office (có format, merge, style). Hệ thống sẽ trích xuất số sheet, thông tin cột, format và dùng template làm mẫu nhập liệu.
          </Text>
          <Form form={templateForm} layout="vertical">
            <Form.Item label="File template (.xlsx)" required>
              <Space align="center" wrap>
                <input
                  ref={templateFileInputRef}
                  type="file"
                  accept=".xlsx"
                  style={{ display: 'none' }}
                  onChange={(e) => setTemplateFile(e.target.files?.[0] ?? null)}
                />
                <Button
                  type="default"
                  icon={<UploadOutlined />}
                  onClick={() => templateFileInputRef.current?.click()}
                >
                  Chọn file
                </Button>
                {templateFile ? (
                  <Text>{templateFile.name}</Text>
                ) : (
                  <Text type="secondary">Chưa chọn file</Text>
                )}
              </Space>
            </Form.Item>
            <Form.Item name="name" label="Tên biểu mẫu" rules={[{ required: true, message: 'Nhập tên biểu mẫu' }]}>
              <Input placeholder="VD: Báo cáo doanh thu tháng" />
            </Form.Item>
            <Form.Item name="code" label="Mã biểu mẫu (tùy chọn)">
              <Input placeholder="Để trống sẽ tự sinh từ tên" />
            </Form.Item>
          </Form>
        </div>
      </Modal>
      <Modal
        title={`Nhân bản biểu mẫu: ${cloningRecord?.name ?? ''}`}
        open={cloneModalOpen}
        onOk={() => {
          cloneForm.validateFields().then((values) => {
            if (!cloningRecord) return
            cloneMutation.mutate({ id: cloningRecord.id, body: values })
          })
        }}
        onCancel={() => { setCloneModalOpen(false); setCloningRecord(null); cloneForm.resetFields() }}
        okText="Nhân bản"
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden
        confirmLoading={cloneMutation.isPending}
      >
        <div ref={cloneFormRef}>
          <Form form={cloneForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="newCode" label="Mã biểu mẫu mới" rules={[{ required: true, message: 'Nhập mã biểu mẫu mới' }]}>
              <Input placeholder="VD: BM01_COPY" />
            </Form.Item>
            <Form.Item name="newName" label="Tên biểu mẫu mới" rules={[{ required: true, message: 'Nhập tên biểu mẫu mới' }]}>
              <Input placeholder="VD: Báo cáo doanh thu (bản sao)" />
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
