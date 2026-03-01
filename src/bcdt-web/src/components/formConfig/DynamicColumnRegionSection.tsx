import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, Input, InputNumber, Select, Checkbox, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { formDynamicColumnRegionsApi } from '../../api/formDataSourceFilterApi'
import type {
  FormDynamicColumnRegionDto,
  CreateFormDynamicColumnRegionRequest,
  UpdateFormDynamicColumnRegionRequest,
} from '../../types/form.types'
import { getApiErrorMessage } from '../../api/apiClient'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../../constants/tableActions'
import { TableActions } from '../TableActions'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../../constants/modalSizes'
import { useFocusFirstInModal } from '../../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../../hooks/useScrollPageTopWhenModalOpen'

const COLUMN_SOURCE_TYPES = [
  { value: 'ByReportingPeriod', label: 'Theo kỳ báo cáo' },
  { value: 'ByCatalog', label: 'Theo danh mục' },
  { value: 'ByDataSource', label: 'Theo nguồn dữ liệu' },
  { value: 'Fixed', label: 'Cố định (danh sách)' },
]

interface Props {
  formId: number
  sheetId: number
}

export function DynamicColumnRegionSection({ formId, sheetId }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [columnRegionForm] = Form.useForm<CreateFormDynamicColumnRegionRequest & { id?: number }>()

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const { data: dynamicColumnRegions = [], isLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-column-regions'],
    queryFn: () => formDynamicColumnRegionsApi.getList(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const createMutation = useMutation({
    mutationFn: (body: CreateFormDynamicColumnRegionRequest) =>
      formDynamicColumnRegionsApi.create(formId, sheetId, body),
    onSuccess: () => {
      message.success('Đã thêm vùng cột động')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-column-regions'] })
      setModalOpen(false)
      columnRegionForm.resetFields()
      setEditingId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ regionId, body }: { regionId: number; body: UpdateFormDynamicColumnRegionRequest }) =>
      formDynamicColumnRegionsApi.update(formId, sheetId, regionId, body),
    onSuccess: () => {
      message.success('Đã cập nhật vùng cột động')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-column-regions'] })
      setModalOpen(false)
      setEditingId(null)
      columnRegionForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (regionId: number) => formDynamicColumnRegionsApi.delete(formId, sheetId, regionId),
    onSuccess: () => {
      message.success('Đã xóa vùng cột động')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-column-regions'] })
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-column-occurrences'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const openCreate = () => {
    columnRegionForm.setFieldsValue({
      code: '',
      name: '',
      columnSourceType: 'ByReportingPeriod',
      columnSourceRef: undefined,
      labelColumn: undefined,
      displayOrder: dynamicColumnRegions.length,
      isActive: true,
    })
    setModalOpen(true)
  }

  const openEdit = (record: FormDynamicColumnRegionDto) => {
    setEditingId(record.id)
    columnRegionForm.setFieldsValue({
      code: record.code,
      name: record.name,
      columnSourceType: record.columnSourceType,
      columnSourceRef: record.columnSourceRef ?? undefined,
      labelColumn: record.labelColumn ?? undefined,
      displayOrder: record.displayOrder,
      isActive: record.isActive,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await columnRegionForm.validateFields()
    const body: CreateFormDynamicColumnRegionRequest = {
      code: values.code?.trim() ?? '',
      name: values.name?.trim() ?? '',
      columnSourceType: values.columnSourceType ?? 'ByReportingPeriod',
      columnSourceRef: values.columnSourceRef?.trim() || undefined,
      labelColumn: values.labelColumn?.trim() || undefined,
      displayOrder: values.displayOrder ?? 0,
      isActive: values.isActive ?? true,
    }
    if (editingId != null) {
      updateMutation.mutate({ regionId: editingId, body })
    } else {
      createMutation.mutate(body)
    }
  }

  return (
    <>
      <Card title="P8 – Vùng cột động" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm vùng cột động
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          loading={isLoading}
          dataSource={dynamicColumnRegions}
          pagination={false}
          bordered
          columns={[
            { title: 'Mã', dataIndex: 'code', key: 'code', width: 120 },
            { title: 'Tên', dataIndex: 'name', key: 'name' },
            { title: 'Nguồn cột', dataIndex: 'columnSourceType', key: 'columnSourceType', width: 140 },
            { title: 'Tham chiếu', dataIndex: 'columnSourceRef', key: 'columnSourceRef', ellipsis: true, render: (v: string | null) => v ?? '–' },
            { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 70 },
            { title: 'Bật', dataIndex: 'isActive', key: 'isActive', width: 60, render: (v: boolean) => (v ? 'Có' : 'Không') },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: FormDynamicColumnRegionDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa vùng cột động?', okText: 'Xóa', cancelText: 'Hủy' },
                      onClick: () => deleteMutation.mutate(record.id),
                    },
                  ]}
                />
              ),
            },
          ]}
        />
      </Card>

      <Modal
        title={editingId != null ? 'Sửa vùng cột động' : 'Thêm vùng cột động'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => { setModalOpen(false); setEditingId(null) }}
        okText={editingId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={columnRegionForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã" rules={[{ required: true }]}>
              <Input placeholder="VD: COL_BY_PERIOD" disabled={editingId != null} />
            </Form.Item>
            <Form.Item name="name" label="Tên" rules={[{ required: true }]}>
              <Input placeholder="VD: Cột theo tháng trong kỳ" />
            </Form.Item>
            <Form.Item name="columnSourceType" label="Nguồn cột" rules={[{ required: true }]}>
              <Select options={COLUMN_SOURCE_TYPES} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="columnSourceRef" label="Tham chiếu (ID danh mục/nguồn hoặc danh sách cố định)">
              <Input placeholder="VD: 1 (catalog id), hoặc A,B,C (Fixed)" />
            </Form.Item>
            <Form.Item name="labelColumn" label="Cột nhãn (tên hiển thị)">
              <Input placeholder="VD: Name, MonthName" />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isActive" valuePropName="checked">
              <Checkbox>Đang bật</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
