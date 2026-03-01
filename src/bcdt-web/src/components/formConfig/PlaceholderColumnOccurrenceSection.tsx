import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, InputNumber, Select, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import {
  formPlaceholderColumnOccurrencesApi,
  formDynamicColumnRegionsApi,
  filterDefinitionsApi,
} from '../../api/formDataSourceFilterApi'
import type {
  FormPlaceholderColumnOccurrenceDto,
  CreateFormPlaceholderColumnOccurrenceRequest,
  UpdateFormPlaceholderColumnOccurrenceRequest,
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

export function PlaceholderColumnOccurrenceSection({ formId, sheetId }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [columnOccurrenceForm] = Form.useForm<CreateFormPlaceholderColumnOccurrenceRequest>()

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const { data: placeholderColumnOccurrences = [], isLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-column-occurrences'],
    queryFn: () => formPlaceholderColumnOccurrencesApi.getList(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const { data: dynamicColumnRegions = [] } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-column-regions'],
    queryFn: () => formDynamicColumnRegionsApi.getList(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const { data: filterDefinitions = [] } = useQuery({
    queryKey: ['filter-definitions'],
    queryFn: () => filterDefinitionsApi.getList(),
    enabled: Number.isInteger(formId),
  })

  const createMutation = useMutation({
    mutationFn: (body: CreateFormPlaceholderColumnOccurrenceRequest) =>
      formPlaceholderColumnOccurrencesApi.create(formId, sheetId, body),
    onSuccess: () => {
      message.success('Đã thêm vị trí placeholder cột')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-column-occurrences'] })
      setModalOpen(false)
      columnOccurrenceForm.resetFields()
      setEditingId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ occurrenceId, body }: { occurrenceId: number; body: UpdateFormPlaceholderColumnOccurrenceRequest }) =>
      formPlaceholderColumnOccurrencesApi.update(formId, sheetId, occurrenceId, body),
    onSuccess: () => {
      message.success('Đã cập nhật vị trí placeholder cột')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-column-occurrences'] })
      setModalOpen(false)
      setEditingId(null)
      columnOccurrenceForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (occurrenceId: number) =>
      formPlaceholderColumnOccurrencesApi.delete(formId, sheetId, occurrenceId),
    onSuccess: () => {
      message.success('Đã xóa vị trí placeholder cột')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'placeholder-column-occurrences'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const openCreate = () => {
    columnOccurrenceForm.setFieldsValue({
      formDynamicColumnRegionId: undefined,
      excelColStart: 1,
      filterDefinitionId: undefined,
      displayOrder: placeholderColumnOccurrences.length,
      maxColumns: undefined,
    })
    setModalOpen(true)
  }

  const openEdit = (record: FormPlaceholderColumnOccurrenceDto) => {
    setEditingId(record.id)
    columnOccurrenceForm.setFieldsValue({
      formDynamicColumnRegionId: record.formDynamicColumnRegionId,
      excelColStart: record.excelColStart,
      filterDefinitionId: record.filterDefinitionId ?? undefined,
      displayOrder: record.displayOrder,
      maxColumns: record.maxColumns ?? undefined,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await columnOccurrenceForm.validateFields()
    const body: CreateFormPlaceholderColumnOccurrenceRequest = {
      formDynamicColumnRegionId: values.formDynamicColumnRegionId,
      excelColStart: values.excelColStart,
      filterDefinitionId: values.filterDefinitionId ?? undefined,
      displayOrder: values.displayOrder ?? 0,
      maxColumns: values.maxColumns ?? undefined,
    }
    if (editingId != null) {
      updateMutation.mutate({ occurrenceId: editingId, body })
    } else {
      createMutation.mutate(body)
    }
  }

  return (
    <>
      <Card title="P8 – Vị trí placeholder cột (mở rộng N cột)" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm vị trí placeholder cột
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          loading={isLoading}
          dataSource={placeholderColumnOccurrences}
          pagination={false}
          bordered
          columns={[
            { title: 'Cột Excel', dataIndex: 'excelColStart', key: 'excelColStart', width: 90 },
            {
              title: 'Vùng cột động',
              dataIndex: 'formDynamicColumnRegionId',
              key: 'formDynamicColumnRegionId',
              render: (v: number) => {
                const r = dynamicColumnRegions.find((x) => x.id === v)
                return r ? `${r.name} (${r.code})` : v
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
            { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 70 },
            { title: 'Max cột', dataIndex: 'maxColumns', key: 'maxColumns', width: 80, render: (v: number | null) => v ?? '–' },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: FormPlaceholderColumnOccurrenceDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa vị trí placeholder cột?', okText: 'Xóa', cancelText: 'Hủy' },
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
        title={editingId != null ? 'Sửa vị trí placeholder cột' : 'Thêm vị trí placeholder cột'}
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
          <Form form={columnOccurrenceForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="formDynamicColumnRegionId" label="Vùng cột động" rules={[{ required: true }]}>
              <Select
                placeholder="Chọn vùng cột động"
                options={dynamicColumnRegions.map((r) => ({ value: r.id, label: `${r.code} – ${r.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="excelColStart" label="Cột Excel bắt đầu (1-based)" rules={[{ required: true }]}>
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
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="maxColumns" label="Số cột tối đa (tùy chọn)">
              <InputNumber min={0} style={{ width: '100%' }} placeholder="Để trống = không giới hạn" />
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
