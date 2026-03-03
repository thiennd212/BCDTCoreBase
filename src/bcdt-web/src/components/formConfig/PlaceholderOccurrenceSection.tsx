import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, InputNumber, Select, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { formPlaceholderOccurrencesApi, dataSourcesApi, filterDefinitionsApi } from '../../api/formDataSourceFilterApi'
import { formDynamicRegionsApi } from '../../api/formStructureApi'
import type {
  FormPlaceholderOccurrenceDto,
  CreateFormPlaceholderOccurrenceRequest,
  UpdateFormPlaceholderOccurrenceRequest,
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

export function PlaceholderOccurrenceSection({ formId, sheetId }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [occurrenceForm] = Form.useForm<CreateFormPlaceholderOccurrenceRequest>()

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const { data: placeholderOccurrences = [], isLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-occurrences'],
    queryFn: () => formPlaceholderOccurrencesApi.getList(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const { data: dynamicRegions = [] } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-regions'],
    queryFn: () => formDynamicRegionsApi.getList(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const { data: filterDefinitions = [] } = useQuery({
    queryKey: ['filter-definitions'],
    queryFn: () => filterDefinitionsApi.getList(),
    enabled: Number.isInteger(formId),
  })

  const { data: dataSources = [] } = useQuery({
    queryKey: ['data-sources'],
    queryFn: () => dataSourcesApi.getList(),
    enabled: Number.isInteger(formId),
  })

  const createMutation = useMutation({
    mutationFn: (body: CreateFormPlaceholderOccurrenceRequest) =>
      formPlaceholderOccurrencesApi.create(formId, sheetId, body),
    onSuccess: () => {
      message.success('Đã thêm vị trí placeholder')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-occurrences'] })
      setModalOpen(false)
      occurrenceForm.resetFields()
      setEditingId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ occurrenceId, body }: { occurrenceId: number; body: UpdateFormPlaceholderOccurrenceRequest }) =>
      formPlaceholderOccurrencesApi.update(formId, sheetId, occurrenceId, body),
    onSuccess: () => {
      message.success('Đã cập nhật vị trí placeholder')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-occurrences'] })
      setModalOpen(false)
      setEditingId(null)
      occurrenceForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (occurrenceId: number) =>
      formPlaceholderOccurrencesApi.delete(formId, sheetId, occurrenceId),
    onSuccess: () => {
      message.success('Đã xóa vị trí placeholder')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-occurrences'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const openCreate = () => {
    occurrenceForm.setFieldsValue({
      formDynamicRegionId: undefined,
      excelRowStart: 1,
      filterDefinitionId: undefined,
      dataSourceId: undefined,
      displayOrder: placeholderOccurrences.length,
      maxRows: undefined,
    })
    setModalOpen(true)
  }

  const openEdit = (record: FormPlaceholderOccurrenceDto) => {
    setEditingId(record.id)
    occurrenceForm.setFieldsValue({
      formDynamicRegionId: record.formDynamicRegionId,
      excelRowStart: record.excelRowStart,
      filterDefinitionId: record.filterDefinitionId ?? undefined,
      dataSourceId: record.dataSourceId ?? undefined,
      displayOrder: record.displayOrder,
      maxRows: record.maxRows ?? undefined,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await occurrenceForm.validateFields()
    const body: CreateFormPlaceholderOccurrenceRequest = {
      formDynamicRegionId: values.formDynamicRegionId,
      excelRowStart: values.excelRowStart,
      filterDefinitionId: values.filterDefinitionId ?? undefined,
      dataSourceId: values.dataSourceId ?? undefined,
      displayOrder: values.displayOrder ?? 0,
      maxRows: values.maxRows ?? undefined,
    }
    if (editingId != null) {
      updateMutation.mutate({ occurrenceId: editingId, body })
    } else {
      createMutation.mutate(body)
    }
  }

  return (
    <>
      <Card title="P8 – Vị trí placeholder (mở rộng N hàng)" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm vị trí placeholder
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          loading={isLoading}
          dataSource={placeholderOccurrences}
          pagination={false}
          bordered
          columns={[
            { title: 'Hàng Excel', dataIndex: 'excelRowStart', key: 'excelRowStart', width: 90 },
            {
              title: 'Vùng chỉ tiêu',
              dataIndex: 'formDynamicRegionId',
              key: 'formDynamicRegionId',
              width: 100,
              render: (v: number) => {
                const r = dynamicRegions.find((x) => x.id === v)
                return r ? `Vùng ${r.id} (hàng ${r.excelRowStart})` : v
              },
            },
            {
              title: 'Bộ lọc',
              dataIndex: 'filterDefinitionId',
              key: 'filterDefinitionId',
              width: 100,
              render: (v: number | null) => {
                if (v == null) return '–'
                const f = filterDefinitions.find((x) => x.id === v)
                return f ? f.name : v
              },
            },
            {
              title: 'Nguồn dữ liệu',
              dataIndex: 'dataSourceId',
              key: 'dataSourceId',
              width: 100,
              render: (v: number | null) => {
                if (v == null) return '–'
                const d = dataSources.find((x) => x.id === v)
                return d ? d.name : v
              },
            },
            { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 70 },
            { title: 'Max hàng', dataIndex: 'maxRows', key: 'maxRows', width: 80, render: (v: number | null) => v ?? '–' },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: FormPlaceholderOccurrenceDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa vị trí placeholder?', okText: 'Xóa', cancelText: 'Hủy' },
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
        title={editingId != null ? 'Sửa vị trí placeholder' : 'Thêm vị trí placeholder'}
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
          <Form form={occurrenceForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="formDynamicRegionId" label="Vùng chỉ tiêu động" rules={[{ required: true }]}>
              <Select
                placeholder="Chọn vùng"
                options={dynamicRegions.map((r) => ({
                  value: r.id,
                  label: `Vùng ${r.id} (hàng ${r.excelRowStart}, cột ${r.excelColName}/${r.excelColValue})`,
                }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="excelRowStart" label="Hàng Excel bắt đầu" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="filterDefinitionId" label="Bộ lọc (tùy chọn)">
              <Select
                allowClear
                placeholder="Không lọc"
                options={filterDefinitions.map((f) => ({ value: f.id, label: `${f.code} – ${f.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="dataSourceId" label="Nguồn dữ liệu (tùy chọn)">
              <Select
                allowClear
                placeholder="Dùng nguồn từ vùng"
                options={dataSources.map((d) => ({ value: d.id, label: `${d.code} – ${d.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="maxRows" label="Số dòng tối đa (tùy chọn)">
              <InputNumber min={0} style={{ width: '100%' }} placeholder="Để trống = không giới hạn" />
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
