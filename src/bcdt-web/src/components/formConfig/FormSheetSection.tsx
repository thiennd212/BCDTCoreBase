import { useRef, useState, useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card, Table, Button, Modal, Form, Input, InputNumber, Checkbox, message,
} from 'antd'
import { PlusOutlined, EditOutlined, DeleteOutlined, UnorderedListOutlined } from '@ant-design/icons'
import { formSheetsApi } from '../../api/formStructureApi'
import type { FormSheetDto, CreateFormSheetRequest } from '../../types/form.types'
import { getApiErrorMessage } from '../../api/apiClient'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../../constants/tableActions'
import { TableActions } from '../TableActions'
import { MODAL_FORM, MODAL_FORM_TOP_OFFSET } from '../../constants/modalSizes'
import { useFocusFirstInModal } from '../../hooks/useFocusFirstInModal'
import { useScrollPageTopWhenModalOpen } from '../../hooks/useScrollPageTopWhenModalOpen'

interface Props {
  formId: number
  selectedSheetId: number | null
  onSheetSelect: (id: number | null) => void
  onColumnSelect: (id: number | null) => void
}

export function FormSheetSection({ formId, selectedSheetId, onSheetSelect, onColumnSelect }: Props) {
  const queryClient = useQueryClient()
  const formContainerRef = useRef<HTMLDivElement>(null)

  const [modalOpen, setModalOpen] = useState(false)
  const [editingId, setEditingId] = useState<number | null>(null)
  const [sheetForm] = Form.useForm<CreateFormSheetRequest>()

  useFocusFirstInModal(modalOpen, formContainerRef)
  useScrollPageTopWhenModalOpen(modalOpen)

  useEffect(() => {
    if (!modalOpen) setEditingId(null)
  }, [modalOpen])

  const { data: sheets = [], isLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets'],
    queryFn: () => formSheetsApi.getList(formId),
    enabled: Number.isInteger(formId),
  })

  const createMutation = useMutation({
    mutationFn: (body: CreateFormSheetRequest) => formSheetsApi.create(formId, body),
    onSuccess: () => {
      message.success('Đã thêm sheet')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets'] })
      setModalOpen(false)
      sheetForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const updateMutation = useMutation({
    mutationFn: ({ sheetId, body }: { sheetId: number; body: CreateFormSheetRequest }) =>
      formSheetsApi.update(formId, sheetId, body),
    onSuccess: () => {
      message.success('Đã cập nhật sheet')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets'] })
      setModalOpen(false)
      setEditingId(null)
      sheetForm.resetFields()
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const deleteMutation = useMutation({
    mutationFn: (sheetId: number) => formSheetsApi.delete(formId, sheetId),
    onSuccess: () => {
      message.success('Đã xóa sheet')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'sheets'] })
      if (selectedSheetId) onSheetSelect(null)
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const openCreate = () => {
    sheetForm.setFieldsValue({
      sheetIndex: sheets.length,
      sheetName: '',
      displayName: '',
      description: '',
      isDataSheet: true,
      isVisible: true,
      displayOrder: sheets.length,
      dataStartRow: undefined,
    })
    setModalOpen(true)
  }

  const openEdit = (record: FormSheetDto) => {
    setEditingId(record.id)
    sheetForm.setFieldsValue({
      sheetIndex: record.sheetIndex,
      sheetName: record.sheetName,
      displayName: record.displayName ?? '',
      description: record.description ?? '',
      isDataSheet: record.isDataSheet,
      isVisible: record.isVisible,
      displayOrder: record.displayOrder,
      dataStartRow: record.dataStartRow ?? undefined,
    })
    setModalOpen(true)
  }

  const handleSubmit = async () => {
    const values = await sheetForm.validateFields()
    const body = {
      ...values,
      displayName: values.displayName || undefined,
      description: values.description || undefined,
      dataStartRow: values.dataStartRow ?? undefined,
    }
    if (editingId != null) updateMutation.mutate({ sheetId: editingId, body })
    else createMutation.mutate(body)
  }

  const sheetColumns = [
    { title: 'STT', dataIndex: 'sheetIndex', key: 'sheetIndex', width: 60 },
    { title: 'Tên sheet', dataIndex: 'sheetName', key: 'sheetName' },
    { title: 'Tên hiển thị', dataIndex: 'displayName', key: 'displayName', ellipsis: true },
    { title: 'Thứ tự', dataIndex: 'displayOrder', key: 'displayOrder', width: 80 },
    {
      title: 'Thao tác',
      key: 'actions',
      width: ACTIONS_COLUMN_WIDTH_ICON,
      align: 'right' as const,
      render: (_: unknown, record: FormSheetDto) => (
        <TableActions
          align="right"
          items={[
            { key: 'edit', label: 'Sửa', icon: <EditOutlined />, onClick: () => openEdit(record) },
            {
              key: 'columns',
              label: 'Cột',
              icon: <UnorderedListOutlined />,
              onClick: () => {
                onSheetSelect(record.id)
                onColumnSelect(null)
              },
            },
            {
              key: 'delete',
              label: 'Xóa',
              icon: <DeleteOutlined />,
              danger: true,
              confirm: { title: 'Xóa sheet?', okText: 'Xóa', cancelText: 'Hủy' },
              onClick: () => deleteMutation.mutate(record.id),
            },
          ]}
        />
      ),
    },
  ]

  return (
    <>
      <Card title="Sheet (Hàng)" style={{ marginBottom: 16 }}>
        <div style={{ marginBottom: 12 }}>
          <Button type="primary" icon={<PlusOutlined />} onClick={openCreate}>
            Thêm sheet
          </Button>
        </div>
        <Table
          rowKey="id"
          size="small"
          columns={sheetColumns}
          dataSource={sheets}
          loading={isLoading}
          pagination={false}
          bordered
          onRow={(record) => ({
            onClick: () => {
              onSheetSelect(record.id)
              onColumnSelect(null)
            },
            style: {
              cursor: 'pointer',
              background: selectedSheetId === record.id ? '#e6f4ff' : undefined,
            },
          })}
        />
      </Card>

      <Modal
        title={editingId != null ? 'Sửa sheet' : 'Thêm sheet'}
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
          <Form form={sheetForm} layout="vertical" style={{ marginTop: 16 }}>
            <Form.Item name="sheetIndex" label="Chỉ số sheet" rules={[{ required: true }]}>
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="sheetName" label="Tên sheet" rules={[{ required: true }]}>
              <Input placeholder="VD: Sheet1" />
            </Form.Item>
            <Form.Item name="displayName" label="Tên hiển thị">
              <Input placeholder="Tùy chọn" />
            </Form.Item>
            <Form.Item name="description" label="Mô tả">
              <Input.TextArea rows={2} />
            </Form.Item>
            <Form.Item name="displayOrder" label="Thứ tự hiển thị">
              <InputNumber min={0} style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item
              name="dataStartRow"
              label="Hàng bắt đầu dữ liệu (template)"
              tooltip="Hàng Excel bắt đầu điền dữ liệu (1-based). VD: 4 = hàng 4 trở đi là dữ liệu, hàng 1–3 là header. Để trống = tự động theo header cột."
            >
              <InputNumber min={1} placeholder="Để trống = tự động" style={{ width: '100%' }} />
            </Form.Item>
            <Form.Item name="isDataSheet" valuePropName="checked">
              <Checkbox>Là sheet dữ liệu</Checkbox>
            </Form.Item>
            <Form.Item name="isVisible" valuePropName="checked">
              <Checkbox>Hiển thị</Checkbox>
            </Form.Item>
          </Form>
        </div>
      </Modal>
    </>
  )
}
