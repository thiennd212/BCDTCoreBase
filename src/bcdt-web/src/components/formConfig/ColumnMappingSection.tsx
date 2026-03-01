import { useEffect } from 'react'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, Form, Input, InputNumber, Select, Button, message } from 'antd'
import { formColumnMappingApi } from '../../api/formStructureApi'
import type { CreateFormColumnMappingRequest } from '../../types/form.types'
import { getApiErrorMessage } from '../../api/apiClient'

interface Props {
  formId: number
  sheetId: number
  columnId: number
}

export function ColumnMappingSection({ formId, sheetId, columnId }: Props) {
  const queryClient = useQueryClient()
  const [mappingForm] = Form.useForm<CreateFormColumnMappingRequest>()

  const { data: columnMapping, isLoading: mappingLoading } = useQuery({
    queryKey: ['forms', formId, 'sheets', sheetId, 'columns', columnId, 'column-mapping'],
    queryFn: () => formColumnMappingApi.get(formId, sheetId, columnId),
    enabled: Number.isInteger(formId) && sheetId != null && columnId != null,
  })

  useEffect(() => {
    if (columnMapping) {
      mappingForm.setFieldsValue({
        targetColumnName: columnMapping.targetColumnName,
        targetColumnIndex: columnMapping.targetColumnIndex,
        aggregateFunction: columnMapping.aggregateFunction ?? '',
      })
    } else if (!mappingLoading) {
      mappingForm.setFieldsValue({
        targetColumnName: '',
        targetColumnIndex: 0,
        aggregateFunction: '',
      })
    }
  }, [columnMapping, columnId, mappingLoading, mappingForm])

  const saveMappingMutation = useMutation({
    mutationFn: async (body: CreateFormColumnMappingRequest) => {
      if (columnMapping)
        return formColumnMappingApi.update(formId, sheetId, columnId, body)
      return formColumnMappingApi.create(formId, sheetId, columnId, body)
    },
    onSuccess: () => {
      message.success('Đã lưu ánh xạ cột')
      queryClient.invalidateQueries({
        queryKey: ['forms', formId, 'sheets', sheetId, 'columns', columnId, 'column-mapping'],
      })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Thất bại'),
  })

  const handleSubmit = async () => {
    const values = await mappingForm.validateFields()
    saveMappingMutation.mutate({
      targetColumnName: values.targetColumnName,
      targetColumnIndex: values.targetColumnIndex ?? 0,
      aggregateFunction: values.aggregateFunction || undefined,
    })
  }

  return (
    <Card title="Ánh xạ cột (Column Mapping)">
      <Form form={mappingForm} layout="vertical" style={{ maxWidth: 400 }}>
        <Form.Item
          name="targetColumnName"
          label="Tên cột đích"
          rules={[{ required: true, message: 'Nhập tên cột đích' }]}
        >
          <Input placeholder="Tên cột khi lưu" />
        </Form.Item>
        <Form.Item name="targetColumnIndex" label="Thứ tự cột đích">
          <InputNumber min={0} style={{ width: 120 }} />
        </Form.Item>
        <Form.Item name="aggregateFunction" label="Hàm tổng hợp">
          <Select
            allowClear
            placeholder="Sum, Avg, ..."
            options={[
              { value: 'Sum', label: 'Sum' },
              { value: 'Avg', label: 'Avg' },
              { value: 'Min', label: 'Min' },
              { value: 'Max', label: 'Max' },
              { value: 'Count', label: 'Count' },
            ]}
          />
        </Form.Item>
        <Button type="primary" onClick={handleSubmit} loading={saveMappingMutation.isPending}>
          Lưu ánh xạ cột
        </Button>
      </Form>
    </Card>
  )
}
