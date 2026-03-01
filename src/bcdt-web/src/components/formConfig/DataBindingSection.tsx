import { useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Card,
  Form,
  Input,
  InputNumber,
  Select,
  Checkbox,
  Button,
  message,
} from 'antd'
import { formDataBindingApi } from '../../api/formStructureApi'
import type { CreateFormDataBindingRequest } from '../../types/form.types'
import { getApiErrorMessage } from '../../api/apiClient'

const BINDING_TYPES = [
  { value: 'Static', label: 'Tĩnh (Static)' },
  { value: 'Database', label: 'Cơ sở dữ liệu' },
  { value: 'API', label: 'API' },
  { value: 'Formula', label: 'Công thức' },
  { value: 'Reference', label: 'Tham chiếu bảng mã' },
  { value: 'Organization', label: 'Đơn vị' },
  { value: 'System', label: 'Hệ thống' },
]

interface Props {
  formId: number
  sheetId: number
  columnId: number
}

export function DataBindingSection({ formId, sheetId, columnId }: Props) {
  const queryClient = useQueryClient()
  const [bindingForm] = Form.useForm<CreateFormDataBindingRequest>()

  const { data: dataBinding, isLoading: bindingLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'columns', columnId, 'data-binding'],
    queryFn: () => formDataBindingApi.get(formId, sheetId, columnId),
    enabled: Number.isInteger(formId) && sheetId != null && columnId != null,
  })

  useEffect(() => {
    if (dataBinding) {
      bindingForm.setFieldsValue({
        bindingType: dataBinding.bindingType,
        sourceTable: dataBinding.sourceTable ?? '',
        sourceColumn: dataBinding.sourceColumn ?? '',
        sourceCondition: dataBinding.sourceCondition ?? '',
        apiEndpoint: dataBinding.apiEndpoint ?? '',
        apiMethod: dataBinding.apiMethod ?? 'GET',
        apiResponsePath: dataBinding.apiResponsePath ?? '',
        formula: dataBinding.formula ?? '',
        referenceEntityTypeId: dataBinding.referenceEntityTypeId ?? undefined,
        referenceDisplayColumn: dataBinding.referenceDisplayColumn ?? '',
        defaultValue: dataBinding.defaultValue ?? '',
        transformExpression: dataBinding.transformExpression ?? '',
        cacheMinutes: dataBinding.cacheMinutes ?? 0,
        isActive: dataBinding.isActive,
      })
    } else if (!bindingLoading) {
      bindingForm.setFieldsValue({
        bindingType: 'Static',
        sourceTable: '',
        sourceColumn: '',
        sourceCondition: '',
        apiEndpoint: '',
        apiMethod: 'GET',
        apiResponsePath: '',
        formula: '',
        defaultValue: '',
        cacheMinutes: 0,
        isActive: true,
      })
    }
  }, [dataBinding, columnId, bindingLoading, bindingForm])

  const saveBindingMutation = useMutation({
    mutationFn: async (body: CreateFormDataBindingRequest) => {
      if (dataBinding)
        return formDataBindingApi.update(formId, sheetId, columnId, body)
      return formDataBindingApi.create(formId, sheetId, columnId, body)
    },
    onSuccess: () => {
      message.success('Đã lưu bộ lọc dữ liệu')
      queryClient.invalidateQueries({
        queryKey: ['forms', formId, 'sheets', sheetId, 'columns', columnId, 'data-binding'],
      })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const handleSubmit = async () => {
    const values = await bindingForm.validateFields().catch(() => null)
    if (!values) return
    saveBindingMutation.mutate({
      ...values,
      sourceTable: values.sourceTable || undefined,
      sourceColumn: values.sourceColumn || undefined,
      sourceCondition: values.sourceCondition || undefined,
      apiEndpoint: values.apiEndpoint || undefined,
      formula: values.formula || undefined,
      defaultValue: values.defaultValue || undefined,
      transformExpression: values.transformExpression || undefined,
    })
  }

  return (
    <Card title="Bộ lọc dữ liệu (Data Binding)" style={{ marginBottom: 16 }}>
      <Form form={bindingForm} layout="vertical" style={{ maxWidth: 560 }}>
        <Form.Item name="bindingType" label="Loại nguồn">
          <Select options={BINDING_TYPES} />
        </Form.Item>
        <Form.Item name="defaultValue" label="Giá trị mặc định">
          <Input placeholder="Giá trị tĩnh hoặc mặc định" />
        </Form.Item>
        <Form.Item name="formula" label="Công thức">
          <Input.TextArea rows={2} placeholder="Biểu thức hoặc tham chiếu cột" />
        </Form.Item>
        <Form.Item name="sourceTable" label="Bảng nguồn (Database)">
          <Input placeholder="Tên bảng" />
        </Form.Item>
        <Form.Item name="sourceColumn" label="Cột nguồn">
          <Input placeholder="Tên cột" />
        </Form.Item>
        <Form.Item name="sourceCondition" label="Điều kiện (WHERE)">
          <Input placeholder="VD: Status = 1" />
        </Form.Item>
        <Form.Item name="apiEndpoint" label="URL API">
          <Input placeholder="https://..." />
        </Form.Item>
        <Form.Item name="apiMethod" label="Method">
          <Select
            options={[
              { value: 'GET', label: 'GET' },
              { value: 'POST', label: 'POST' },
            ]}
          />
        </Form.Item>
        <Form.Item name="apiResponsePath" label="Đường dẫn JSON (kết quả)">
          <Input placeholder="VD: data.items" />
        </Form.Item>
        <Form.Item name="transformExpression" label="Biểu thức chuyển đổi">
          <Input placeholder="Tùy chọn" />
        </Form.Item>
        <Form.Item name="cacheMinutes" label="Cache (phút)">
          <InputNumber min={0} style={{ width: 120 }} />
        </Form.Item>
        <Form.Item name="isActive" valuePropName="checked">
          <Checkbox>Đang bật</Checkbox>
        </Form.Item>
        <Button type="primary" onClick={handleSubmit} loading={saveBindingMutation.isPending}>
          Lưu bộ lọc dữ liệu
        </Button>
      </Form>
    </Card>
  )
}
