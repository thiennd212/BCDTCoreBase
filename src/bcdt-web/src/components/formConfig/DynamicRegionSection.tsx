import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, Input, InputNumber, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { formDynamicRegionsApi } from '../../api/formStructureApi'
import type {
  FormDynamicRegionDto,
  CreateFormDynamicRegionRequest,
  UpdateFormDynamicRegionRequest,
} from '../../types/form.types'
import { getApiErrorMessage } from '../../api/apiClient'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../../constants/tableActions'
import { TableActions } from '../TableActions'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../../constants/modalSizes'
import { useFocusFirstInModal } from '../../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../../hooks/useScrollPageTopWhenModalOpen'

interface Props {
  formId: number
  sheetId: number
}

export function DynamicRegionSection({ formId, sheetId }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [regionForm] = Form.useForm<CreateFormDynamicRegionRequest & { excelRowEnd?: number | null; displayOrder?: number }>()

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const { data: dynamicRegions = [], isLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-regions'],
    queryFn: () => formDynamicRegionsApi.getList(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const createMutation = useMutation({
    mutationFn: (body: CreateFormDynamicRegionRequest) =>
      formDynamicRegionsApi.create(formId, sheetId, body),
    onSuccess: () => {
      message.success('Đã thêm vùng chỉ tiêu động')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-regions'] })
      setModalOpen(false)
      regionForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ regionId, body }: { regionId: number; body: UpdateFormDynamicRegionRequest }) =>
      formDynamicRegionsApi.update(formId, sheetId, regionId, body),
    onSuccess: () => {
      message.success('Đã cập nhật vùng chỉ tiêu động')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-regions'] })
      setModalOpen(false)
      setEditingId(null)
      regionForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (regionId: number) => formDynamicRegionsApi.delete(formId, sheetId, regionId),
    onSuccess: () => {
      message.success('Đã xóa vùng chỉ tiêu động')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-regions'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const openCreate = () => {
    regionForm.setFieldsValue({
      excelRowStart: 1,
      excelRowEnd: undefined,
      excelColName: 'A',
      excelColValue: 'B',
      maxRows: 10,
      indicatorExpandDepth: 0,
      indicatorCatalogId: undefined,
      displayOrder: dynamicRegions.length,
    })
    setModalOpen(true)
  }

  const openEdit = (record: FormDynamicRegionDto) => {
    setEditingId(record.id)
    regionForm.setFieldsValue({
      excelRowStart: record.excelRowStart,
      excelRowEnd: record.excelRowEnd ?? undefined,
      excelColName: record.excelColName,
      excelColValue: record.excelColValue,
      maxRows: record.maxRows,
      indicatorExpandDepth: record.indicatorExpandDepth,
      indicatorCatalogId: record.indicatorCatalogId ?? undefined,
      displayOrder: record.displayOrder,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await regionForm.validateFields()
    const base = {
      excelRowStart: values.excelRowStart,
      excelRowEnd: values.excelRowEnd ?? undefined,
      excelColName: values.excelColName,
      excelColValue: values.excelColValue,
      maxRows: values.maxRows ?? 10,
      indicatorExpandDepth: values.indicatorExpandDepth ?? 0,
      indicatorCatalogId: values.indicatorCatalogId ?? undefined,
      displayOrder: values.displayOrder ?? dynamicRegions.length,
    }
    if (editingId != null) {
      updateMutation.mutate({
        regionId: editingId,
        body: { ...base, maxRows: base.maxRows ?? 10, indicatorExpandDepth: base.indicatorExpandDepth ?? 0, displayOrder: base.displayOrder ?? 0 },
      })
    } else {
      createMutation.mutate(base)
    }
  }

  return (
    <>
      <Card title="Vùng chỉ tiêu động" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm vùng
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          loading={isLoading}
          dataSource={dynamicRegions}
          pagination={false}
          bordered
          columns={[
            { title: 'Hàng bắt đầu', dataIndex: 'excelRowStart', key: 'excelRowStart', width: 100 },
            { title: 'Hàng kết thúc', dataIndex: 'excelRowEnd', key: 'excelRowEnd', width: 100, render: (v: number | null) => v ?? '–' },
            { title: 'Cột tên', dataIndex: 'excelColName', key: 'excelColName', width: 80 },
            { title: 'Cột giá trị', dataIndex: 'excelColValue', key: 'excelColValue', width: 80 },
            { title: 'Số dòng tối đa', dataIndex: 'maxRows', key: 'maxRows', width: 100 },
            { title: 'Độ sâu mở rộng', dataIndex: 'indicatorExpandDepth', key: 'indicatorExpandDepth', width: 100 },
            { title: 'Catalog', dataIndex: 'indicatorCatalogId', key: 'indicatorCatalogId', width: 80, render: (v: number | null) => v ?? '–' },
            { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 70 },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: FormDynamicRegionDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa vùng chỉ tiêu động?', okText: 'Xóa', cancelText: 'Hủy' },
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
        title={editingId != null ? 'Sửa vùng chỉ tiêu động' : 'Thêm vùng chỉ tiêu động'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText={editingId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.MEDIUM}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
      >
        <div ref={formContainerRef}>
          <Form form={regionForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="excelRowStart" label="Hàng bắt đầu (Excel)" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: '100%' }} placeholder="1" />
            </Form.Item>
            <Form.Item name="excelRowEnd" label="Hàng kết thúc (Excel)">
              <InputNumber min={1} style={{ width: '100%' }} placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="excelColName" label="Cột chứa tên chỉ tiêu" rules={[{ required: true }]}>
              <Input placeholder="VD: A" />
            </Form.Item>
            <Form.Item name="excelColValue" label="Cột chứa giá trị" rules={[{ required: true }]}>
              <Input placeholder="VD: B" />
            </Form.Item>
            <Form.Item name="maxRows" label="Số dòng tối đa">
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="indicatorExpandDepth" label="Độ sâu mở rộng chỉ tiêu">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="indicatorCatalogId" label="ID danh mục chỉ tiêu (tùy chọn)">
              <InputNumber style={{ width: '100%' }} placeholder="Để trống nếu không dùng catalog" />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự hiển thị">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
