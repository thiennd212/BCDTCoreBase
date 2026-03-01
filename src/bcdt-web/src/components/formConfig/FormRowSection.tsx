import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, Input, InputNumber, Select, Checkbox, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined } from '@ant-design/icons'
import { formRowsApi, formDynamicRegionsApi } from '../../api/formStructureApi'
import type {
  FormRowDto, FormRowTreeDto,
  CreateFormRowRequest, UpdateFormRowRequest,
} from '../../types/form.types'
import { getApiErrorMessage } from '../../api/apiClient'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../../constants/tableActions'
import { TableActions } from '../TableActions'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../../constants/modalSizes'
import { buildTree, treeExcludeSelfAndDescendants } from '../../utils/treeUtils'
import type { TreeNode } from '../../utils/treeUtils'
import { TreeSelect } from 'antd'
import { useFocusFirstInModal } from '../../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../../hooks/useScrollPageTopWhenModalOpen'

const ROW_TYPES = [
  { value: 'Header', label: 'Header' },
  { value: 'Data', label: 'Data' },
  { value: 'Total', label: 'Total' },
  { value: 'Static', label: 'Static' },
]

function rowTreeToTableData(nodes: FormRowTreeDto[]): (FormRowTreeDto & { key: number; children?: ReturnType<typeof rowTreeToTableData> })[] {
  return nodes.map((n) => ({
    ...n,
    key: n.id,
    children: n.children?.length ? rowTreeToTableData(n.children) : undefined,
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
}

export function FormRowSection({ formId, sheetId }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [rowForm] = Form.useForm<CreateFormRowRequest>()

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const { data: rows = [] } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'rows'],
    queryFn: () => formRowsApi.getList(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const { data: rowsTree = [], isLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'rows', 'tree'],
    queryFn: () => formRowsApi.getListTree(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const { data: dynamicRegions = [] } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'dynamic-regions'],
    queryFn: () => formDynamicRegionsApi.getList(formId, sheetId),
    enabled: Number.isInteger(formId),
  })

  const createMutation = useMutation({
    mutationFn: (body: CreateFormRowRequest) => formRowsApi.create(formId, sheetId, body),
    onSuccess: () => {
      message.success('Đã thêm hàng')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'rows'] })
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'rows', 'tree'] })
      setModalOpen(false)
      rowForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ rowId, body }: { rowId: number; body: UpdateFormRowRequest }) =>
      formRowsApi.update(formId, sheetId, rowId, body),
    onSuccess: () => {
      message.success('Đã cập nhật hàng')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'rows'] })
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'rows', 'tree'] })
      setModalOpen(false)
      setEditingId(null)
      rowForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (rowId: number) => formRowsApi.delete(formId, sheetId, rowId),
    onSuccess: () => {
      message.success('Đã xóa hàng')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'rows'] })
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets', sheetId, 'rows', 'tree'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const openCreate = () => {
    rowForm.setFieldsValue({
      rowCode: '',
      rowName: '',
      excelRowStart: 1,
      excelRowEnd: undefined,
      rowType: 'Data',
      isRepeating: false,
      displayOrder: rows.length,
      parentId: undefined,
      formDynamicRegionId: undefined,
    })
    setModalOpen(true)
  }

  const openEdit = (record: FormRowDto) => {
    setEditingId(record.id)
    rowForm.setFieldsValue({
      rowCode: record.rowCode ?? '',
      rowName: record.rowName ?? '',
      excelRowStart: record.excelRowStart,
      excelRowEnd: record.excelRowEnd ?? undefined,
      rowType: record.rowType,
      isRepeating: record.isRepeating,
      displayOrder: record.displayOrder,
      parentId: record.parentId ?? undefined,
      formDynamicRegionId: record.formDynamicRegionId ?? undefined,
      height: record.height ?? undefined,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await rowForm.validateFields()
    const body: CreateFormRowRequest = {
      rowCode: values.rowCode || undefined,
      rowName: values.rowName || undefined,
      excelRowStart: values.excelRowStart,
      excelRowEnd: values.excelRowEnd ?? undefined,
      rowType: values.rowType ?? 'Data',
      isRepeating: values.isRepeating ?? false,
      displayOrder: values.displayOrder ?? 0,
      parentId: values.parentId ?? undefined,
      formDynamicRegionId: values.formDynamicRegionId ?? undefined,
      height: values.height ?? undefined,
    }
    if (editingId != null) {
      updateMutation.mutate({ rowId: editingId, body })
    } else {
      createMutation.mutate(body)
    }
  }

  return (
    <>
      <Card title="Hàng (Form Row – dạng cây)" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm hàng
          </Button>
        </div>
        <Table
          rowKey="key"
          size="small"
          loading={isLoading}
          dataSource={rowTreeToTableData(rowsTree)}
          pagination={false}
          bordered
          columns={[
            { title: 'Mã hàng', dataIndex: 'rowCode', key: 'rowCode', width: 100, render: (v: string | null) => v ?? '–' },
            { title: 'Tên hàng', dataIndex: 'rowName', key: 'rowName', render: (v: string | null) => v ?? '–' },
            { title: 'Hàng Excel từ', dataIndex: 'excelRowStart', key: 'excelRowStart', width: 100 },
            { title: 'Loại', dataIndex: 'rowType', key: 'rowType', width: 90 },
            { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 80 },
            {
              title: 'Thao tác',
              key: 'actions',
              width: ACTIONS_COLUMN_WIDTH_ICON,
              align: 'right' as const,
              render: (_: unknown, record: FormRowTreeDto) => (
                <TableActions
                  align="right"
                  items={[
                    { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
                    {
                      key: 'delete',
                      label: 'Xóa',
                      icon: <DeleteOutlined />,
                      danger: true,
                      confirm: { title: 'Xóa hàng?', okText: 'Xóa', cancelText: 'Hủy' },
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
        title={editingId != null ? 'Sửa hàng' : 'Thêm hàng'}
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
          <Form form={rowForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="parentId" label="Hàng cha (phân cấp)">
              <TreeSelect
                allowClear
                placeholder="Không có (hàng gốc)"
                treeData={(() => {
                  const tree = buildTree(rows, { parentKey: 'parentId' })
                  const excluded = editingId != null ? treeExcludeSelfAndDescendants(tree, editingId) : tree
                  return toTreeSelectOptions(excluded, (n) => `${n.rowCode ?? n.id} - ${n.rowName ?? ''}`.trim() || `Hàng ${n.id}`)
                })()}
                treeDefaultExpandAll
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="rowCode" label="Mã hàng">
              <Input placeholder="VD: R1" />
            </Form.Item>
            <Form.Item name="rowName" label="Tên hàng">
              <Input placeholder="Tên hiển thị" />
            </Form.Item>
            <Form.Item name="excelRowStart" label="Hàng Excel bắt đầu" rules={[{ required: true }]}>
              <InputNumber min={1} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="excelRowEnd" label="Hàng Excel kết thúc">
              <InputNumber min={1} style={{ width: '100%' }} placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="rowType" label="Loại hàng">
              <Select options={ROW_TYPES} />
            </Form.Item>
            <Form.Item name="formDynamicRegionId" label="Vùng chỉ tiêu động (tùy chọn)">
              <Select
                allowClear
                placeholder="Không thuộc vùng"
                options={dynamicRegions.map((r) => ({ value: r.id, label: `Vùng ${r.id} (hàng ${r.excelRowStart})` }))}
                style={{ width: '100%' }}
              />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isRepeating" valuePropName="checked">
              <Checkbox>Lặp (có thể thêm nhiều dòng)</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
