import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, Input, Select, Typography, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { filterDefinitionsApi, dataSourcesApi } from '../../api/formDataSourceFilterApi'
import type {
  FilterDefinitionDto,
  CreateFilterDefinitionRequest,
  UpdateFilterDefinitionRequest,
  CreateFilterConditionItem,
  DataSourceDto,
} from '../../types/form.types'
import { getApiErrorMessage } from '../../api/apiClient'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../../constants/tableActions'
import { TableActions } from '../TableActions'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../../constants/modalSizes'
import { useFocusFirstInModal } from '../../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../../hooks/useScrollPageTopWhenModalOpen'

interface Props {
  formId: number
}

export function FilterDefinitionSection({ formId }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [filterForm] = Form.useForm<CreateFilterDefinitionRequest & { id?: number }>()
  const [filterConditions, setFilterConditions] = useState<(CreateFilterConditionItem & { id?: number })[]>([])

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) {
      setEditingId(null)
      setFilterConditions([])
    }
  }, [modalOpen])

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
    mutationFn: (body: CreateFilterDefinitionRequest) => filterDefinitionsApi.create(body),
    onSuccess: () => {
      message.success('Đã thêm bộ lọc')
      queryClient.invalidateQueries({ queryKey: ['filter-definitions'] })
      setModalOpen(false)
      filterForm.resetFields()
      setFilterConditions([])
      setEditingId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id: filterId, body }: { id: number; body: UpdateFilterDefinitionRequest }) =>
      filterDefinitionsApi.update(filterId, body),
    onSuccess: () => {
      message.success('Đã cập nhật bộ lọc')
      queryClient.invalidateQueries({ queryKey: ['filter-definitions'] })
      setModalOpen(false)
      setEditingId(null)
      filterForm.resetFields()
      setFilterConditions([])
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (filterId: number) => filterDefinitionsApi.delete(filterId),
    onSuccess: () => {
      message.success('Đã xóa bộ lọc')
      queryClient.invalidateQueries({ queryKey: ['filter-definitions'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const openCreate = () => {
    filterForm.setFieldsValue({
      code: '',
      name: '',
      logicalOperator: 'AND',
      dataSourceId: undefined,
    })
    setFilterConditions([])
    setModalOpen(true)
  }

  const openEdit = (record: FilterDefinitionDto) => {
    setEditingId(record.id)
    filterForm.setFieldsValue({
      code: record.code,
      name: record.name,
      logicalOperator: record.logicalOperator,
      dataSourceId: record.dataSourceId ?? undefined,
    })
    setFilterConditions(
      (record.conditions ?? []).map((c) => ({
        id: c.id,
        conditionOrder: c.conditionOrder,
        field: c.field,
        operator: c.operator,
        valueType: c.valueType ?? 'Literal',
        value: c.value ?? '',
        value2: c.value2 ?? '',
        dataType: c.dataType ?? undefined,
      }))
    )
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await filterForm.validateFields()
    if (editingId != null) {
      const conditions: UpdateFilterDefinitionRequest['conditions'] = filterConditions.map((c, i) => ({
        id: c.id ?? 0,
        conditionOrder: c.conditionOrder ?? i,
        field: c.field,
        operator: c.operator,
        valueType: c.valueType ?? 'Literal',
        value: c.value || undefined,
        value2: c.value2 || undefined,
        dataType: c.dataType ?? undefined,
      }))
      updateMutation.mutate({
        id: editingId,
        body: {
          name: values.name,
          logicalOperator: values.logicalOperator ?? 'AND',
          dataSourceId: values.dataSourceId ?? undefined,
          conditions,
        },
      })
    } else {
      createMutation.mutate({
        code: values.code,
        name: values.name,
        logicalOperator: values.logicalOperator ?? 'AND',
        dataSourceId: values.dataSourceId ?? undefined,
        conditions: filterConditions.map((c, i) => ({
          conditionOrder: c.conditionOrder ?? i,
          field: c.field,
          operator: c.operator,
          valueType: c.valueType ?? 'Literal',
          value: c.value || undefined,
          value2: c.value2 || undefined,
          dataType: c.dataType ?? undefined,
        })),
      })
    }
  }

  return (
    <>
      <Card title="P8 – Bộ lọc" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm bộ lọc
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          dataSource={filterDefinitions}
          pagination={false}
          bordered
          columns={[
            { title: 'Mã', dataIndex: 'code', key: 'code', width: 120 },
            { title: 'Tên', dataIndex: 'name', key: 'name' },
            { title: 'Logic', dataIndex: 'logicalOperator', key: 'logicalOperator', width: 70 },
            { title: 'Nguồn (ID)', dataIndex: 'dataSourceId', key: 'dataSourceId', width: 90, render: (v: number | null) => v ?? '–' },
            { title: 'Số điều kiện', key: 'conditionsCount', width: 100, render: (_: unknown, r: FilterDefinitionDto) => (r.conditions?.length ?? 0) },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: FilterDefinitionDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa bộ lọc?', okText: 'Xóa', cancelText: 'Hủy' },
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
        title={editingId != null ? 'Sửa bộ lọc' : 'Thêm bộ lọc'}
        open={modalOpen}
        onOk={handleSubmit}
        onCancel={() => setModalOpen(false)}
        okText={editingId != null ? 'Cập nhật' : 'Tạo'}
        cancelText="Hủy"
        width={MODAL_FORM.LARGE}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        styles={{ body: { maxHeight: '70vh', overflow: 'auto' } }}
      >
        <div ref={formContainerRef}>
          <Form form={filterForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã" rules={[{ required: true }]}>
              <Input placeholder="VD: DU_AN_NGAY_VB" disabled={editingId != null} />
            </Form.Item>
            <Form.Item name="name" label="Tên" rules={[{ required: true }]}>
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="logicalOperator" label="Logic gộp điều kiện">
              <Select options={[{ value: 'AND', label: 'AND' }, { value: 'OR', label: 'OR' }]} />
            </Form.Item>
            <Form.Item name="dataSourceId" label="Nguồn dữ liệu (tùy chọn)">
              <Select
                allowClear
                placeholder="Chọn nguồn"
                options={(dataSources as DataSourceDto[]).map((d) => ({ value: d.id, label: `${d.code} – ${d.name}` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Typography.Text strong style={{ display: 'block', marginBottom: 8 }}>Điều kiện</Typography.Text>
            {filterConditions.map((_, idx) => (
              <div key={idx} style={{ display: 'flex', gap: 8, marginBottom: 8, alignItems: 'flex-start', flexWrap: 'wrap' }}>
                <Input
                  placeholder="Trường"
                  value={filterConditions[idx]?.field}
                  onChange={(e) => {
                    const next = [...filterConditions]
                    if (next[idx]) next[idx] = { ...next[idx], field: e.target.value }
                    setFilterConditions(next)
                  }}
                  style={{ width: 120 }}
                />
                <Select
                  placeholder="Toán tử"
                  value={filterConditions[idx]?.operator || undefined}
                  onChange={(v) => {
                    const next = [...filterConditions]
                    if (next[idx]) next[idx] = { ...next[idx], operator: v ?? '' }
                    setFilterConditions(next)
                  }}
                  style={{ width: 100 }}
                  options={[
                    { value: '=', label: '=' },
                    { value: '<>', label: '<>' },
                    { value: '<', label: '<' },
                    { value: '>', label: '>' },
                    { value: '<=', label: '<=' },
                    { value: '>=', label: '>=' },
                    { value: 'LIKE', label: 'LIKE' },
                    { value: 'IN', label: 'IN' },
                  ]}
                />
                <Select
                  placeholder="Loại giá trị"
                  value={filterConditions[idx]?.valueType || 'Literal'}
                  onChange={(v) => {
                    const next = [...filterConditions]
                    if (next[idx]) next[idx] = { ...next[idx], valueType: v ?? 'Literal' }
                    setFilterConditions(next)
                  }}
                  style={{ width: 100 }}
                  options={[
                    { value: 'Literal', label: 'Literal' },
                    { value: 'Parameter', label: 'Parameter' },
                  ]}
                />
                <Input
                  placeholder="Giá trị"
                  value={filterConditions[idx]?.value ?? ''}
                  onChange={(e) => {
                    const next = [...filterConditions]
                    if (next[idx]) next[idx] = { ...next[idx], value: e.target.value }
                    setFilterConditions(next)
                  }}
                  style={{ width: 140 }}
                />
                <Button
                  type="text"
                  danger
                  icon={<DeleteOutlined />}
                  onClick={() => setFilterConditions(filterConditions.filter((_, i) => i !== idx))}
                />
              </div>
            ))}
            <Button
              type="dashed"
              icon={<PlusOutlined />}
              onClick={() =>
                setFilterConditions([
                  ...filterConditions,
                  { conditionOrder: filterConditions.length, field: '', operator: '=', valueType: 'Literal', value: '' },
                ])
              }
            >
              Thêm điều kiện
            </Button>
          </Form>
        </div>
      </Modal>
    </>
  )
}
