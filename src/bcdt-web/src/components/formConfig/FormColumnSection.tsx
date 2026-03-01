import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, Input, InputNumber, Select,
  Checkbox, Typography, TreeSelect, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, FilterOutlined } from '@ant-design/icons'
import { formColumnsApi } from '../../api/formStructureApi'
import { indicatorCatalogsApi, indicatorsApi, indicatorsByCodeApi } from '../../api/indicatorCatalogsApi'
import type {
  FormColumnDto, FormColumnTreeDto,
  CreateFormColumnRequest,
} from '../../types/form.types'
import type { IndicatorCatalogDto, IndicatorDto } from '../../types/form.types'
import { getApiErrorMessage } from '../../api/apiClient'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../../constants/tableActions'
import { TableActions } from '../TableActions'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../../constants/modalSizes'
import { buildTree, treeExcludeSelfAndDescendants } from '../../utils/treeUtils'
import type { TreeNode } from '../../utils/treeUtils'
import { useFocusFirstInModal } from '../../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../../hooks/useScrollPageTopWhenModalOpen'

const DATA_TYPES = [
  { value: 'Text', label: 'Text' },
  { value: 'Number', label: 'Number' },
  { value: 'Date', label: 'Date' },
  { value: 'Formula', label: 'Formula' },
  { value: 'Reference', label: 'Reference' },
  { value: 'Boolean', label: 'Boolean' },
]

function columnTreeToTableData(nodes: FormColumnTreeDto[]): (FormColumnTreeDto & { key: number; children?: ReturnType<typeof columnTreeToTableData> })[] {
  return nodes.map((n) => ({
    ...n,
    key: n.id,
    children: n.children?.length ? columnTreeToTableData(n.children) : undefined,
  }))
}

function indicatorToTreeSelectOptions(items: IndicatorDto[]): { value: number; label: string; children?: ReturnType<typeof indicatorToTreeSelectOptions> }[] {
  return items.map((i) => ({
    value: i.id,
    label: `${i.code} - ${i.name}`,
    children: i.children?.length ? indicatorToTreeSelectOptions(i.children) : undefined,
  }))
}

function toTreeSelectOptions<T extends { id: number; children?: T[] }>(
  nodes: TreeNode<T>[],
  titleFn: (n: T) => string
): { value: number; title: string; children?: ReturnType<typeof toTreeSelectOptions<T>> }[] {
  return nodes.map((n) => ({
    value: n.id,
    title: titleFn(n),
    children: n.children?.length ? toTreeSelectOptions(n.children, titleFn) : undefined,
  }))
}

interface Props {
  formId: number
  sheetId: number
  selectedColumnId: number | null
  onColumnSelect: (id: number | null) => void
}

export function FormColumnSection({ formId, sheetId, selectedColumnId, onColumnSelect }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [createMode, setCreateMode] = useState<'from-catalog' | 'manual'>('from-catalog')
  const [selectedCatalogId, setSelectedCatalogId] = useState<number | null>(null)
  const [selectedIndicatorId, setSelectedIndicatorId] = useState<number | null>(null)
  const [columnForm] = Form.useForm<CreateFormColumnRequest>()

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  // Special indicator for new columns
  const { data: specialIndicator } = useQuery({
    queryKey: ['indicators', 'by-code', '_SPECIAL_GENERIC'],
    queryFn: () => indicatorsByCodeApi.getByCode('_SPECIAL_GENERIC'),
    staleTime: 5 * 60 * 1000,
  })
  const specialIndicatorId = specialIndicator?.id ?? null

  const { data: columns = [], isLoading: columnsLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'columns'],
    queryFn: () => formColumnsApi.getList(formId, sheetId) as Promise<FormColumnDto[]>,
    enabled: Number.isInteger(formId),
  })

  const { data: columnsTree = [], isLoading: columnsTreeLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'columns', 'tree'],
    queryFn: () => formColumnsApi.getListTree(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const { data: indicatorCatalogs = [] } = useQuery({
    queryKey: ['indicator-catalogs'],
    queryFn: () => indicatorCatalogsApi.getList(),
    enabled: modalOpen && editingId == null && createMode === 'from-catalog',
  })

  const { data: indicatorsForColumn = [] } = useQuery({
    queryKey: ['indicators', selectedCatalogId],
    queryFn: () => indicatorsApi.getList(selectedCatalogId!, true),
    enabled: modalOpen && selectedCatalogId != null,
  })

  const createMutation = useMutation({
    mutationFn: (body: CreateFormColumnRequest) => formColumnsApi.create(formId, sheetId, body),
    onSuccess: () => {
      message.success('Đã thêm cột')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'columns'] })
      setModalOpen(false)
      setCreateMode('from-catalog')
      setSelectedCatalogId(null)
      setSelectedIndicatorId(null)
      columnForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ columnId, body }: { columnId: number; body: CreateFormColumnRequest }) =>
      formColumnsApi.update(formId, sheetId, columnId, body),
    onSuccess: () => {
      message.success('Đã cập nhật cột')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'columns'] })
      setModalOpen(false)
      setEditingId(null)
      columnForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (columnId: number) => formColumnsApi.delete(formId, sheetId, columnId),
    onSuccess: () => {
      message.success('Đã xóa cột')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'columns'] })
      onColumnSelect(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const handleCreateFromIndicator = () => {
    if (selectedIndicatorId == null) {
      message.warning('Vui lòng chọn một chỉ tiêu từ danh mục.')
      return
    }
    createMutation.mutate({
      indicatorId: selectedIndicatorId,
      parentId: undefined,
      columnCode: '',
      columnName: '',
      excelColumn: 'A',
      dataType: 'Text',
      isRequired: false,
      isEditable: true,
      isHidden: false,
      displayOrder: columns.length,
    })
  }

  const openCreate = () => {
    setCreateMode('from-catalog')
    setSelectedCatalogId(null)
    setSelectedIndicatorId(null)
    columnForm.setFieldsValue({
      parentId: undefined,
      indicatorId: specialIndicatorId ?? undefined,
      columnCode: '',
      columnName: '',
      columnGroupName: '',
      columnGroupLevel2: '',
      columnGroupLevel3: '',
      columnGroupLevel4: '',
      excelColumn: 'A',
      dataType: 'Text',
      isRequired: false,
      isEditable: true,
      isHidden: false,
      displayOrder: columns.length,
    })
    setModalOpen(true)
  }

  const openEdit = (record: FormColumnDto) => {
    setEditingId(record.id)
    columnForm.setFieldsValue({
      parentId: record.parentId ?? undefined,
      indicatorId: record.indicatorId,
      columnCode: record.columnCode,
      columnName: record.columnName,
      columnGroupName: record.columnGroupName ?? '',
      columnGroupLevel2: record.columnGroupLevel2 ?? '',
      columnGroupLevel3: record.columnGroupLevel3 ?? '',
      columnGroupLevel4: record.columnGroupLevel4 ?? '',
      excelColumn: record.excelColumn,
      dataType: record.dataType,
      isRequired: record.isRequired,
      isEditable: record.isEditable,
      isHidden: record.isHidden,
      defaultValue: record.defaultValue ?? '',
      formula: record.formula ?? '',
      validationRule: record.validationRule ?? '',
      validationMessage: record.validationMessage ?? '',
      displayOrder: record.displayOrder,
      width: record.width ?? undefined,
      format: record.format ?? '',
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await columnForm.validateFields()
    const body: CreateFormColumnRequest = {
      ...values,
      parentId: values.parentId ?? undefined,
      columnGroupName: values.columnGroupName || undefined,
      columnGroupLevel2: values.columnGroupLevel2 || undefined,
      columnGroupLevel3: values.columnGroupLevel3 || undefined,
      columnGroupLevel4: values.columnGroupLevel4 || undefined,
      defaultValue: values.defaultValue || undefined,
      formula: values.formula || undefined,
      validationRule: values.validationRule || undefined,
      validationMessage: values.validationMessage || undefined,
      format: values.format || undefined,
    }
    if (editingId != null) {
      body.indicatorId = values.indicatorId ?? (columns as FormColumnDto[]).find((c) => c.id === editingId)?.indicatorId ?? 0
    } else {
      body.indicatorId = values.indicatorId ?? specialIndicatorId ?? null
    }
    if (body.indicatorId == null || body.indicatorId === 0) {
      message.warning('Vui lòng chọn chỉ tiêu từ danh mục hoặc đợi tải chỉ tiêu đặc biệt (Tạo cột mới).')
      return
    }
    if (editingId != null) updateMutation.mutate({ columnId: editingId, body })
    else createMutation.mutate(body)
  }

  const columnColumns = [
    { title: 'Mã cột', dataIndex: 'columnCode', key: 'columnCode', width: 100 },
    { title: 'Tên cột', dataIndex: 'columnName', key: 'columnName' },
    { title: 'Cột Excel', dataIndex: 'excelColumn', key: 'excelColumn', width: 90 },
    { title: 'Kiểu', dataIndex: 'dataType', key: 'dataType', width: 90 },
    { title: 'Công thức', dataIndex: 'formula', key: 'formula', ellipsis: true },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: FormColumnDto) => (
        <TableActions
          align="right"
          items={[
            { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
            {
              key: 'filter',
              label: 'Bộ lọc / Ánh xạ',
              icon: <FilterOutlined />,
              onClick: () => onColumnSelect(record.id),
            },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: { title: 'Xóa cột?', okText: 'Xóa', cancelText: 'Hủy' },
              onClick: () => deleteMutation.mutate(record.id),
            },
          ]}
        />
      ),
    },
  ]

  return (
    <>
      <Card title="Cột (dạng cây – theo sheet đã chọn)" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm cột
          </Button>
        </div>
        <Table
          rowKey="key"
          size="small"
          columns={columnColumns}
          dataSource={columnTreeToTableData(columnsTree)}
          loading={columnsLoading || columnsTreeLoading}
          pagination={false}
          bordered
          onRow={(record) => ({
            onClick: () => onColumnSelect(record.id),
            style: {
              cursor: 'pointer',
              background: selectedColumnId === record.id ? '#e6f4ff' : undefined,
            },
          })}
        />
      </Card>

      <Modal
        title={
          editingId != null
            ? 'Sửa cột'
            : createMode === 'from-catalog'
              ? 'Thêm cột (chọn từ danh mục chỉ tiêu)'
              : 'Thêm cột (nhập trực tiếp)'
        }
        open={modalOpen}
        onOk={
          editingId != null
            ? () => void handleSubmit()
            : createMode === 'from-catalog'
              ? () => handleCreateFromIndicator()
              : () => void handleSubmit()
        }
        okText={
          editingId != null
            ? 'Cập nhật'
            : createMode === 'from-catalog'
              ? 'Tạo cột từ chỉ tiêu'
              : 'Tạo'
        }
        cancelText="Hủy"
        onCancel={() => {
          setModalOpen(false)
          setCreateMode('from-catalog')
          setSelectedCatalogId(null)
          setSelectedIndicatorId(null)
        }}
        width={MODAL_FORM.LARGE}
        style={{ top: MODAL_FORM_TOP_OFFSET }}
        destroyOnHidden={false}
        styles={{ body: { maxHeight: '70vh', overflow: 'auto' } }}
      >
        <div ref={formContainerRef}>
          {editingId == null && createMode === 'from-catalog' ? (
            <>
              <Typography.Text type="secondary" style={{ display: 'block', marginBottom: 8 }}>
                Nên chọn từ danh mục để thống nhất giữa các biểu mẫu. Dùng &quot;Tạo cột mới (nhập tay)&quot; cho cột tiêu đề, công thức hoặc đặc biệt.
              </Typography.Text>
              <Form layout="vertical" style={{ marginTop: 16 }}>
                <Form.Item label="Danh mục chỉ tiêu">
                  <Select
                    placeholder="Chọn danh mục chỉ tiêu"
                    allowClear
                    value={selectedCatalogId ?? undefined}
                    onChange={(v) => {
                      setSelectedCatalogId(v ?? null)
                      setSelectedIndicatorId(null)
                    }}
                    options={(indicatorCatalogs as IndicatorCatalogDto[]).map((c) => ({ value: c.id, label: c.name }))}
                    style={{ width: '100%' }}
                  />
                </Form.Item>
                <Form.Item label="Chọn chỉ tiêu">
                  <TreeSelect
                    placeholder="Chọn chỉ tiêu (sau khi chọn danh mục)"
                    allowClear
                    value={selectedIndicatorId ?? undefined}
                    onChange={(v) => setSelectedIndicatorId(v ?? null)}
                    treeData={indicatorToTreeSelectOptions(indicatorsForColumn as IndicatorDto[])}
                    treeDefaultExpandAll
                    style={{ width: '100%' }}
                    disabled={selectedCatalogId == null}
                  />
                </Form.Item>
              </Form>
              <div style={{ marginTop: 16 }}>
                <Button type="link" onClick={() => { setCreateMode('manual'); columnForm.setFieldsValue({ indicatorId: specialIndicatorId ?? undefined, columnCode: '', columnName: '', excelColumn: 'A', dataType: 'Text', isRequired: false, isEditable: true, isHidden: false, displayOrder: columns.length }) }} style={{ padding: 0 }}>
                  Tạo cột mới (nhập trực tiếp)
                </Button>
              </div>
            </>
          ) : (
            <Form form={columnForm} layout="vertical" style={{ marginTop: 16 }}>
              {editingId == null && (
                <div style={{ marginBottom: 12 }}>
                  <Button type="link" onClick={() => { setCreateMode('from-catalog'); setSelectedIndicatorId(null) }} style={{ padding: 0 }}>
                    Quay lại chọn từ danh mục
                  </Button>
                </div>
              )}
              <Form.Item name="parentId" label="Cột cha (phân cấp)">
                <TreeSelect
                  allowClear
                  placeholder="Không có (cột gốc)"
                  treeData={(() => {
                    const flat = columns as FormColumnDto[]
                    const tree = buildTree(flat, { parentKey: 'parentId' })
                    const excluded = editingId != null ? treeExcludeSelfAndDescendants(tree, editingId) : tree
                    return toTreeSelectOptions(excluded, (n) => `${n.columnCode} - ${n.columnName}`)
                  })()}
                  treeDefaultExpandAll
                  style={{ width: '100%' }}
                />
              </Form.Item>
              <Form.Item name="columnCode" label="Mã cột" rules={[{ required: true }]}>
                <Input placeholder="VD: COL_A" />
              </Form.Item>
              <Form.Item name="columnName" label="Tên cột" rules={[{ required: true }]}>
                <Input placeholder="Tên hiển thị" />
              </Form.Item>
              <Form.Item name="columnGroupName" label="Nhóm header tầng 1">
                <Input placeholder="VD: Thông tin chung (merge header Excel)" />
              </Form.Item>
              <Form.Item name="columnGroupLevel2" label="Nhóm header tầng 2">
                <Input placeholder="Tùy chọn (header nhiều tầng)" />
              </Form.Item>
              <Form.Item name="columnGroupLevel3" label="Nhóm header tầng 3">
                <Input placeholder="Tùy chọn" />
              </Form.Item>
              <Form.Item name="columnGroupLevel4" label="Nhóm header tầng 4">
                <Input placeholder="Tùy chọn" />
              </Form.Item>
              <Form.Item name="excelColumn" label="Cột Excel" rules={[{ required: true }]}>
                <Input placeholder="A, B, C..." />
              </Form.Item>
              <Form.Item name="dataType" label="Kiểu dữ liệu">
                <Select options={DATA_TYPES} />
              </Form.Item>
              <Form.Item name="formula" label="Công thức">
                <Input.TextArea rows={2} placeholder="Công thức Excel hoặc tham chiếu" />
              </Form.Item>
              <Form.Item name="defaultValue" label="Giá trị mặc định">
                <Input />
              </Form.Item>
              <Form.Item name="displayOrder" label="Thứ tự">
                <InputNumber min={0} style={{ width: '100%' }} />
              </Form.Item>
              <Form.Item name="validationRule" label="Quy tắc kiểm tra">
                <Input placeholder="Regex hoặc biểu thức" />
              </Form.Item>
              <Form.Item name="validationMessage" label="Thông báo lỗi">
                <Input />
              </Form.Item>
              <Form.Item name="format" label="Định dạng (số, ngày)">
                <Input placeholder="VD: #,##0.00" />
              </Form.Item>
              <Form.Item name="width" label="Độ rộng">
                <InputNumber min={0} style={{ width: 120 }} />
              </Form.Item>
              <Form.Item name="isRequired" valuePropName="checked">
                <Checkbox>Bắt buộc</Checkbox>
              </Form.Item>
              <Form.Item name="isEditable" valuePropName="checked">
                <Checkbox>Có thể sửa</Checkbox>
              </Form.Item>
              <Form.Item name="isHidden" valuePropName="checked">
                <Checkbox>Ẩn</Checkbox>
              </Form.Item>
            </Form>
          )}
        </div>
      </Modal>
    </>
  )
}
