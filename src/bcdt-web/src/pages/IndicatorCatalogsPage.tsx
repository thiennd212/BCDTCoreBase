import { useState, useEffect } from 'react'
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
  InputNumber,
  Select,
  Switch,
  TreeSelect,
  message,
  Tag,
  Empty,
  Row,
  Col,
} from 'antd'
import {
  PlusOutlined,
  EditOutlined,
  DeleteOutlined,
  BookOutlined,
  TagsOutlined,
} from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { indicatorCatalogsApi, indicatorsApi } from '../api/indicatorCatalogsApi'
import type {
  IndicatorCatalogDto,
  CreateIndicatorCatalogRequest,
  UpdateIndicatorCatalogRequest,
  IndicatorDto,
  CreateIndicatorRequest,
  UpdateIndicatorRequest,
} from '../types/form.types'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../constants/modalSizes'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../constants/tableActions'
import { TableActions } from '../components/TableActions'

const { Title } = Typography

// ─── Helpers ────────────────────────────────────────────────────

type TreeSelectNode = { value: number; title: string; key: number; children?: TreeSelectNode[] }

function toTreeSelectData(items: IndicatorDto[]): TreeSelectNode[] {
  return items.map((i) => ({
    value: i.id,
    title: `${i.code} – ${i.name}`,
    key: i.id,
    children: i.children?.length ? toTreeSelectData(i.children) : undefined,
  }))
}

// ─── Catalog Modal ──────────────────────────────────────────────

function CatalogModal({
  open,
  editing,
  onClose,
  onSuccess,
}: {
  open: boolean
  editing: IndicatorCatalogDto | null
  onClose: () => void
  onSuccess: () => void
}) {
  const [form] = Form.useForm()
  const qc = useQueryClient()

  const createMut = useMutation({
    mutationFn: (body: CreateIndicatorCatalogRequest) => indicatorCatalogsApi.create(body),
    onSuccess: () => {
      message.success('Tạo danh mục thành công')
      qc.invalidateQueries({ queryKey: ['indicator-catalogs'] })
      onSuccess()
    },
    onError: (e) => message.error(getApiErrorMessage(e)),
  })

  const updateMut = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateIndicatorCatalogRequest }) =>
      indicatorCatalogsApi.update(id, body),
    onSuccess: () => {
      message.success('Cập nhật danh mục thành công')
      qc.invalidateQueries({ queryKey: ['indicator-catalogs'] })
      onSuccess()
    },
    onError: (e) => message.error(getApiErrorMessage(e)),
  })

  const handleOk = async () => {
    const values = await form.validateFields()
    if (editing) {
      updateMut.mutate({ id: editing.id, body: values })
    } else {
      createMut.mutate(values)
    }
  }

  // Form initialValues chỉ áp dụng khi mount; dùng setFieldsValue khi modal mở để form luôn đúng.
  useEffect(() => {
    if (!open) return
    if (editing) {
      form.setFieldsValue({
        code: editing.code,
        name: editing.name,
        description: editing.description,
        scope: editing.scope,
        displayOrder: editing.displayOrder,
        isActive: editing.isActive,
      })
    } else {
      form.setFieldsValue({ scope: 'Global', displayOrder: 0, isActive: true, code: '', name: '', description: '' })
    }
  }, [open, editing, form])

  return (
    <Modal
      open={open}
      title={editing ? 'Sửa danh mục chỉ tiêu' : 'Thêm danh mục chỉ tiêu'}
      onCancel={onClose}
      onOk={handleOk}
      okText={editing ? 'Lưu' : 'Tạo'}
      cancelText="Hủy"
      width={MODAL_FORM.SMALL}
      confirmLoading={createMut.isPending || updateMut.isPending}
      destroyOnHidden
      style={{ top: MODAL_FORM_TOP_OFFSET }}
      styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
    >
      <Form
        form={form}
        layout="vertical"
        initialValues={{ scope: 'Global', displayOrder: 0, isActive: true }}
      >
        <Form.Item name="code" label="Mã" rules={[{ required: true, message: 'Nhập mã danh mục' }]}>
          <Input disabled={!!editing} placeholder="VD: DM_TINH" />
        </Form.Item>
        <Form.Item name="name" label="Tên" rules={[{ required: true, message: 'Nhập tên danh mục' }]}>
          <Input placeholder="VD: Danh mục tỉnh thành" />
        </Form.Item>
        <Form.Item name="description" label="Mô tả">
          <Input.TextArea rows={2} />
        </Form.Item>
        <Row gutter={16}>
          <Col span={12}>
            <Form.Item name="scope" label="Phạm vi">
              <Select
                options={[
                  { value: 'Global', label: 'Toàn hệ thống' },
                  { value: 'Organization', label: 'Theo đơn vị' },
                ]}
              />
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item name="displayOrder" label="Thứ tự hiển thị">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
        </Row>
        <Form.Item name="isActive" label="Hoạt động" valuePropName="checked">
          <Switch />
        </Form.Item>
      </Form>
    </Modal>
  )
}

// ─── Indicator Modal ────────────────────────────────────────────

function IndicatorModal({
  open,
  catalogId,
  editing,
  treeData,
  onClose,
  onSuccess,
}: {
  open: boolean
  catalogId: number
  editing: IndicatorDto | null
  treeData: TreeSelectNode[]
  onClose: () => void
  onSuccess: () => void
}) {
  const [form] = Form.useForm()
  const qc = useQueryClient()

  const createMut = useMutation({
    mutationFn: (body: CreateIndicatorRequest) => indicatorsApi.create(catalogId, body),
    onSuccess: () => {
      message.success('Tạo chỉ tiêu thành công')
      qc.invalidateQueries({ queryKey: ['indicators', catalogId] })
      onSuccess()
    },
    onError: (e) => message.error(getApiErrorMessage(e)),
  })

  const updateMut = useMutation({
    mutationFn: ({ id, body }: { id: number; body: UpdateIndicatorRequest }) =>
      indicatorsApi.update(catalogId, id, body),
    onSuccess: () => {
      message.success('Cập nhật chỉ tiêu thành công')
      qc.invalidateQueries({ queryKey: ['indicators', catalogId] })
      onSuccess()
    },
    onError: (e) => message.error(getApiErrorMessage(e)),
  })

  // Filter out self and descendants for parent select
  const parentTreeData = editing
    ? treeData.filter((n) => n.value !== editing.id)
    : treeData

  const handleOk = async () => {
    const values = await form.validateFields()
    if (editing) {
      updateMut.mutate({ id: editing.id, body: values })
    } else {
      createMut.mutate({ ...values, indicatorCatalogId: catalogId })
    }
  }

  // Form initialValues chỉ áp dụng khi mount; khi editing thay đổi form không cập nhật.
  // Dùng setFieldsValue khi modal mở để form luôn hiển thị đúng dữ liệu.
  useEffect(() => {
    if (!open) return
    if (editing) {
      form.setFieldsValue({
        parentId: editing.parentId,
        code: editing.code,
        name: editing.name,
        description: editing.description,
        dataType: editing.dataType,
        unit: editing.unit,
        displayOrder: editing.displayOrder,
        isActive: editing.isActive,
      })
    } else {
      form.setFieldsValue({ dataType: 'Text', displayOrder: 0, isActive: true, code: '', name: '', description: '', parentId: undefined, unit: '' })
    }
  }, [open, editing, form])

  return (
    <Modal
      open={open}
      title={editing ? 'Sửa chỉ tiêu' : 'Thêm chỉ tiêu'}
      onCancel={onClose}
      onOk={handleOk}
      okText={editing ? 'Lưu' : 'Tạo'}
      cancelText="Hủy"
      width={MODAL_FORM.MEDIUM}
      confirmLoading={createMut.isPending || updateMut.isPending}
      destroyOnHidden
      style={{ top: MODAL_FORM_TOP_OFFSET }}
      styles={{ body: { overflow: 'visible', maxHeight: 'none' } }}
    >
      <Form
        form={form}
        layout="vertical"
        initialValues={{ dataType: 'Text', displayOrder: 0, isActive: true }}
      >
        <Row gutter={16}>
          <Col span={12}>
            <Form.Item name="code" label="Mã" rules={[{ required: true, message: 'Nhập mã chỉ tiêu' }]}>
              <Input disabled={!!editing} placeholder="VD: CT_001" />
            </Form.Item>
          </Col>
          <Col span={12}>
            <Form.Item name="parentId" label="Chỉ tiêu cha">
              <TreeSelect
                treeData={parentTreeData}
                allowClear
                placeholder="Chọn chỉ tiêu cha (nếu có)"
                treeDefaultExpandAll
              />
            </Form.Item>
          </Col>
        </Row>
        <Form.Item name="name" label="Tên" rules={[{ required: true, message: 'Nhập tên chỉ tiêu' }]}>
          <Input placeholder="VD: Doanh thu thuần" />
        </Form.Item>
        <Form.Item name="description" label="Mô tả">
          <Input.TextArea rows={2} />
        </Form.Item>
        <Row gutter={16}>
          <Col span={8}>
            <Form.Item name="dataType" label="Kiểu dữ liệu">
              <Select
                options={[
                  { value: 'Text', label: 'Văn bản' },
                  { value: 'Number', label: 'Số' },
                  { value: 'Percent', label: 'Phần trăm' },
                  { value: 'Currency', label: 'Tiền tệ' },
                  { value: 'Date', label: 'Ngày' },
                  { value: 'Boolean', label: 'Có/Không' },
                ]}
              />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="unit" label="Đơn vị">
              <Input placeholder="VD: triệu đồng" />
            </Form.Item>
          </Col>
          <Col span={8}>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
          </Col>
        </Row>
        <Form.Item name="isActive" label="Hoạt động" valuePropName="checked">
          <Switch />
        </Form.Item>
      </Form>
    </Modal>
  )
}

// ─── Main Page ──────────────────────────────────────────────────

export function IndicatorCatalogsPage() {
  const qc = useQueryClient()
  const [selectedCatalogId, setSelectedCatalogId] = useState<number | null>(null)

  // Catalog modal state
  const [catalogModalOpen, setCatalogModalOpen] = useState(false)
  const [editingCatalog, setEditingCatalog] = useState<IndicatorCatalogDto | null>(null)

  // Indicator modal state
  const [indicatorModalOpen, setIndicatorModalOpen] = useState(false)
  const [editingIndicator, setEditingIndicator] = useState<IndicatorDto | null>(null)

  // Queries
  const catalogsQuery = useQuery({
    queryKey: ['indicator-catalogs'],
    queryFn: () => indicatorCatalogsApi.getList(true),
  })

  const indicatorsQuery = useQuery({
    queryKey: ['indicators', selectedCatalogId],
    queryFn: () => indicatorsApi.getList(selectedCatalogId!, true),
    enabled: !!selectedCatalogId,
  })

  // Reset indicator modal khi đổi danh mục để tránh editingIndicator thuộc catalog cũ
  useEffect(() => {
    setIndicatorModalOpen(false)
    setEditingIndicator(null)
  }, [selectedCatalogId])

  const deleteCatalogMut = useMutation({
    mutationFn: (id: number) => indicatorCatalogsApi.delete(id),
    onSuccess: () => {
      message.success('Xóa danh mục thành công')
      qc.invalidateQueries({ queryKey: ['indicator-catalogs'] })
      if (selectedCatalogId) setSelectedCatalogId(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e)),
  })

  const deleteIndicatorMut = useMutation({
    mutationFn: (id: number) => indicatorsApi.delete(selectedCatalogId!, id),
    onSuccess: () => {
      message.success('Xóa chỉ tiêu thành công')
      qc.invalidateQueries({ queryKey: ['indicators', selectedCatalogId] })
    },
    onError: (e) => message.error(getApiErrorMessage(e)),
  })

  // Catalog handlers
  const openCreateCatalog = () => {
    setEditingCatalog(null)
    setCatalogModalOpen(true)
  }
  const openEditCatalog = (record: IndicatorCatalogDto) => {
    setEditingCatalog(record)
    setCatalogModalOpen(true)
  }
  const closeCatalogModal = () => {
    setCatalogModalOpen(false)
    setEditingCatalog(null)
  }

  // Indicator handlers
  const openCreateIndicator = () => {
    setEditingIndicator(null)
    setIndicatorModalOpen(true)
  }
  const openEditIndicator = (record: IndicatorDto) => {
    setEditingIndicator(record)
    setIndicatorModalOpen(true)
  }
  const closeIndicatorModal = () => {
    setIndicatorModalOpen(false)
    setEditingIndicator(null)
  }

  // Data
  const catalogs = catalogsQuery.data ?? []
  const indicatorTree = indicatorsQuery.data ?? []
  const treeSelectData = toTreeSelectData(indicatorTree)

  const selectedCatalog = catalogs.find((c) => c.id === selectedCatalogId)

  // ─── Catalog columns ───────────────────────────────────────────
  const catalogColumns = [
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 140,
    },
    {
      title: 'Tên danh mục',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Số chỉ tiêu',
      dataIndex: 'indicatorCount',
      key: 'indicatorCount',
      width: 100,
      align: 'center' as const,
      render: (v: number) => <Tag color="blue">{v}</Tag>,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 100,
      render: (v: boolean) => (
        <Tag color={v ? 'green' : 'default'}>{v ? 'Hoạt động' : 'Ngưng'}</Tag>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      render: (_: unknown, record: IndicatorCatalogDto) => (
        <TableActions
          items={[
            {
              key: 'edit',
              label: 'Sửa',
              icon: <EditOutlined />,
              onClick: () => openEditCatalog(record),
            },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              onClick: () => deleteCatalogMut.mutate(record.id),
              confirm: {
                title: 'Xóa danh mục?',
                description: `Xóa "${record.name}"? Thao tác không thể hoàn tác.`,
              },
            },
          ]}
        />
      ),
    },
  ]

  // ─── Indicator columns (expandable tree) ────────────────────────
  const indicatorColumns = [
    {
      title: 'Mã',
      dataIndex: 'code',
      key: 'code',
      width: 140,
    },
    {
      title: 'Tên chỉ tiêu',
      dataIndex: 'name',
      key: 'name',
      ellipsis: true,
    },
    {
      title: 'Kiểu',
      dataIndex: 'dataType',
      key: 'dataType',
      width: 100,
    },
    {
      title: 'Đơn vị',
      dataIndex: 'unit',
      key: 'unit',
      width: 100,
    },
    {
      title: 'Trạng thái',
      dataIndex: 'isActive',
      key: 'isActive',
      width: 90,
      render: (v: boolean) => (
        <Tag color={v ? 'green' : 'default'}>{v ? 'HĐ' : 'Ngưng'}</Tag>
      ),
    },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      render: (_: unknown, record: IndicatorDto) => (
        <TableActions
          items={[
            {
              key: 'edit',
              label: 'Sửa',
              icon: <EditOutlined />,
              onClick: () => openEditIndicator(record),
            },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              onClick: () => deleteIndicatorMut.mutate(record.id),
              confirm: {
                title: 'Xóa chỉ tiêu?',
                description: `Xóa "${record.name}"? Thao tác không thể hoàn tác.`,
              },
            },
          ]}
        />
      ),
    },
  ]

  return (
    <div>
      <Title level={4} style={{ marginBottom: 16 }}>
        <BookOutlined style={{ marginRight: 8 }} />
        Danh mục chỉ tiêu
      </Title>

      <Row gutter={16}>
        {/* ─── Bên trái: Danh sách Catalog ─── */}
        <Col xs={24} lg={10} xl={8}>
          <Card
            title="Danh mục"
            size="small"
            extra={
              <Button type="primary" icon={<PlusOutlined />} size="small" onClick={openCreateCatalog}>
                Thêm
              </Button>
            }
          >
            <Table
              rowKey="id"
              columns={catalogColumns}
              dataSource={catalogs}
              loading={catalogsQuery.isLoading}
              pagination={false}
              size="small"
              bordered
              rowClassName={(record) =>
                record.id === selectedCatalogId ? 'ant-table-row-selected' : ''
              }
              onRow={(record) => ({
                onClick: () => setSelectedCatalogId(record.id),
                style: { cursor: 'pointer' },
              })}
              scroll={{ x: 520 }}
            />
          </Card>
        </Col>

        {/* ─── Bên phải: Chỉ tiêu (tree) ─── */}
        <Col xs={24} lg={14} xl={16}>
          <Card
            title={
              selectedCatalog ? (
                <Space>
                  <TagsOutlined />
                  <span>Chỉ tiêu – {selectedCatalog.name}</span>
                  <Tag color="blue">{selectedCatalog.code}</Tag>
                </Space>
              ) : (
                'Chỉ tiêu'
              )
            }
            size="small"
            extra={
              selectedCatalogId ? (
                <Button
                  type="primary"
                  icon={<PlusOutlined />}
                  size="small"
                  onClick={openCreateIndicator}
                >
                  Thêm chỉ tiêu
                </Button>
              ) : null
            }
          >
            {!selectedCatalogId ? (
              <Empty description="Chọn một danh mục bên trái để xem chỉ tiêu" />
            ) : (
              <Table
                rowKey="id"
                columns={indicatorColumns}
                dataSource={indicatorTree}
                loading={indicatorsQuery.isLoading}
                pagination={false}
                size="small"
                bordered
                expandable={{
                  childrenColumnName: 'children',
                  defaultExpandAllRows: true,
                }}
                scroll={{ x: 680 }}
              />
            )}
          </Card>
        </Col>
      </Row>

      {/* Modals */}
      <CatalogModal
        open={catalogModalOpen}
        editing={editingCatalog}
        onClose={closeCatalogModal}
        onSuccess={closeCatalogModal}
      />

      {selectedCatalogId && (
        <IndicatorModal
          open={indicatorModalOpen}
          catalogId={selectedCatalogId}
          editing={editingIndicator}
          treeData={treeSelectData}
          onClose={closeIndicatorModal}
          onSuccess={closeIndicatorModal}
        />
      )}
    </div>
  )
}
