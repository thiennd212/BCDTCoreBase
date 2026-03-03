import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import { Card, Table, Select, Space, message } from 'antd'
import { DeleteOutlined } from '@ant-design/icons'
import { formWorkflowConfigApi, workflowDefinitionsApi } from '../../api/workflowDefinitionsApi'
import type { FormWorkflowConfigDto } from '../../types/workflow.types'
import { getApiErrorMessage } from '../../api/apiClient'
import { ACTIONS_COLUMN_WIDTH_ICON } from '../../constants/tableActions'
import { TableActions } from '../TableActions'

interface Props {
  formId: number
}

export function WorkflowConfigSection({ formId }: Props) {
  const queryClient = useQueryClient()

  const { data: workflowConfigs = [] } = useQuery({
    queryKey: ['forms', formId, 'workflow-config'],
    queryFn: () => formWorkflowConfigApi.getByFormId(formId),
    enabled: Number.isInteger(formId),
  })

  const { data: allWorkflowDefs = [] } = useQuery({
    queryKey: ['workflow-definitions-for-config'],
    queryFn: () => workflowDefinitionsApi.getList({ includeInactive: false }),
  })

  const createWfConfigMut = useMutation({
    mutationFn: (body: { formDefinitionId: number; workflowDefinitionId: number; isActive: boolean }) =>
      formWorkflowConfigApi.create(formId, body),
    onSuccess: () => {
      message.success('Gắn quy trình thành công')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'workflow-config'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Gắn quy trình thất bại'),
  })

  const deleteWfConfigMut = useMutation({
    mutationFn: (configId: number) => formWorkflowConfigApi.delete(formId, configId),
    onSuccess: () => {
      message.success('Đã gỡ quy trình')
      queryClient.invalidateQueries({ queryKey: ['forms', formId, 'workflow-config'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Gỡ quy trình thất bại'),
  })

  return (
    <Card title="Quy trình phê duyệt" style={{ marginBottom: 16 }}>
      <Space style={{ marginBottom: 12 }}>
        <Select
          style={{ width: 320 }}
          placeholder="Chọn quy trình để gắn"
          options={allWorkflowDefs
            .filter((w) => !workflowConfigs.some((c) => c.workflowDefinitionId === w.id))
            .map((w) => ({ value: w.id, label: `${w.code} – ${w.name} (${w.totalSteps} bước)` }))}
          onSelect={(wfId: number) =>
            createWfConfigMut.mutate({ formDefinitionId: formId, workflowDefinitionId: wfId, isActive: true })
          }
        />
      </Space>
      <Table
        rowKey="id"
        size="small"
        bordered
        pagination={false}
        dataSource={workflowConfigs}
        columns={[
          { title: 'Mã quy trình', dataIndex: 'workflowDefinitionCode', key: 'wfCode', width: 160 },
          { title: 'ID quy trình', dataIndex: 'workflowDefinitionId', key: 'wfId', width: 100, align: 'center' as const },
          {
            title: 'Trạng thái',
            dataIndex: 'isActive',
            key: 'isActive',
            width: 100,
            align: 'center' as const,
            render: (v: boolean) => (v ? 'Hoạt động' : 'Tắt'),
          },
          {
            title: 'Thao tác',
            key: 'actions',
            width: 80,
            align: 'right' as const,
            render: (_: unknown, record: FormWorkflowConfigDto) => (
              <TableActions
                align="right"
                items={[
                  {
                    key: 'delete',
                    label: 'Gỡ',
                    icon: <DeleteOutlined />,
                    danger: true,
                    confirm: { title: 'Gỡ quy trình khỏi biểu mẫu?', okText: 'Gỡ', cancelText: 'Hủy' },
                    onClick: () => deleteWfConfigMut.mutate(record.id),
                  },
                ]}
              />
            ),
          },
        ]}
      />
    </Card>
  )
}
