import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, Input, InputNumber, Select, Checkbox, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { dataSourcesApi } from '../../api/formDataSourceFilterApi'
import type {
  DataSourceDto,
  CreateDataSourceRequest,
  UpdateDataSourceRequest,
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

export function DataSourceSection({ formId }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [dataSourceForm] = Form.useForm<CreateDataSourceRequest & { id?: number }>()

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const { data: dataSources = [] } = useQuery({
    queryKey: ['data-sources'],
    queryFn: () => dataSourcesApi.getList(),
    enabled: Number.isInteger(formId),
  })

  const createMutation = useMutation({
    mutationFn: (body: CreateDataSourceRequest) => dataSourcesApi.create(body),
    onSuccess: () => {
      message.success('Đã thêm nguồn dữ liệu')
      queryClient.invalidateQueries({ queryKey: ['data-sources'] })
      setModalOpen(false)
      dataSourceForm.resetFields()
      setEditingId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ id: dsId, body }: { id: number; body: UpdateDataSourceRequest }) =>
      dataSourcesApi.update(dsId, body),
    onSuccess: () => {
      message.success('Đã cập nhật nguồn dữ liệu')
      queryClient.invalidateQueries({ queryKey: ['data-sources'] })
      setModalOpen(false)
      setEditingId(null)
      dataSourceForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (dsId: number) => dataSourcesApi.delete(dsId),
    onSuccess: () => {
      message.success('Đã xóa nguồn dữ liệu')
      queryClient.invalidateQueries({ queryKey: ['data-sources'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const openCreate = () => {
    dataSourceForm.setFieldsValue({
      code: '',
      name: '',
      sourceType: 'Table',
      sourceRef: '',
      indicatorCatalogId: undefined,
      displayColumn: '',
      valueColumn: '',
      isActive: true,
    })
    setModalOpen(true)
  }

  const openEdit = (record: DataSourceDto) => {
    setEditingId(record.id)
    dataSourceForm.setFieldsValue({
      code: record.code,
      name: record.name,
      sourceType: record.sourceType,
      sourceRef: record.sourceRef ?? '',
      indicatorCatalogId: record.indicatorCatalogId ?? undefined,
      displayColumn: record.displayColumn ?? '',
      valueColumn: record.valueColumn ?? '',
      isActive: record.isActive,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await dataSourceForm.validateFields()
    if (editingId != null) {
      updateMutation.mutate({
        id: editingId,
        body: {
          name: values.name,
          sourceType: values.sourceType ?? 'Table',
          sourceRef: values.sourceRef || undefined,
          indicatorCatalogId: values.indicatorCatalogId ?? undefined,
          displayColumn: values.displayColumn || undefined,
          valueColumn: values.valueColumn || undefined,
          isActive: values.isActive ?? true,
        },
      })
    } else {
      createMutation.mutate({
        code: values.code,
        name: values.name,
        sourceType: values.sourceType ?? 'Table',
        sourceRef: values.sourceRef || undefined,
        indicatorCatalogId: values.indicatorCatalogId ?? undefined,
        displayColumn: values.displayColumn || undefined,
        valueColumn: values.valueColumn || undefined,
        isActive: values.isActive ?? true,
      })
    }
  }

  return (
    <>
      <Card title="P8 – Nguồn dữ liệu" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm nguồn dữ liệu
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          dataSource={dataSources}
          pagination={false}
          bordered
          columns={[
            { title: 'Mã', dataIndex: 'code', key: 'code', width: 120 },
            { title: 'Tên', dataIndex: 'name', key: 'name' },
            { title: 'Loại', dataIndex: 'sourceType', key: 'sourceType', width: 90 },
            { title: 'Nguồn (bảng/view)', dataIndex: 'sourceRef', key: 'sourceRef', ellipsis: true, render: (v: string | null) => v ?? '–' },
            { title: 'Cột hiển thị', dataIndex: 'displayColumn', key: 'displayColumn', width: 100, render: (v: string | null) => v ?? '–' },
            { title: 'Cột giá trị', dataIndex: 'valueColumn', key: 'valueColumn', width: 100, render: (v: string | null) => v ?? '–' },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: DataSourceDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa nguồn dữ liệu?', okText: 'Xóa', cancelText: 'Hủy' },
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
        title={editingId != null ? 'Sửa nguồn dữ liệu' : 'Thêm nguồn dữ liệu'}
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
          <Form form={dataSourceForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="code" label="Mã" rules={[{ required: true }]}>
              <Input placeholder="VD: PROJECT_LIST" disabled={editingId != null} />
            </Form.Item>
            <Form.Item name="name" label="Tên" rules={[{ required: true }]}>
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="sourceType" label="Loại nguồn">
              <Select
                options={[
                  { value: 'Table', label: 'Table' },
                  { value: 'View', label: 'View' },
                  { value: 'Catalog', label: 'Catalog' },
                  { value: 'API', label: 'API' },
                ]}
              />
            </Form.Item>
            <Form.Item name="sourceRef" label="Bảng/View (tên)">
              <Input placeholder="VD: BCDT_Project" />
            </Form.Item>
            <Form.Item name="indicatorCatalogId" label="ID danh mục chỉ tiêu (Catalog)">
              <InputNumber style={{ width: '100%' }} placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="displayColumn" label="Cột hiển thị (tên chỉ tiêu)">
              <Input placeholder="VD: Name, ProjectName" />
            </Form.Item>
            <Form.Item name="valueColumn" label="Cột giá trị">
              <Input placeholder="Tùy chọn" />
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
