import { useState, useRef } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Breadcrumb,
  Card,
  Typography,
  Button,
  Space,
  message,
} from 'antd'
import { UploadOutlined } from '@ant-design/icons'
import { getApiErrorMessage } from '../api/apiClient'
import { formsApi } from '../api/formsApi'
import {
  DataSourceSection,
  FilterDefinitionSection,
  WorkflowConfigSection,
  FormSheetSection,
  FormColumnSection,
  FormRowSection,
  DynamicRegionSection,
  PlaceholderOccurrenceSection,
  DynamicColumnRegionSection,
  PlaceholderColumnOccurrenceSection,
  DataBindingSection,
  ColumnMappingSection,
} from '../components/formConfig'

const { Text } = Typography

export function FormConfigPage() {
  const { formId } = useParams<{ formId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const id = formId ? parseInt(formId, 10) : NaN

  const [selectedSheetId, setSelectedSheetId] = useState<number | null>(null)
  const [selectedColumnId, setSelectedColumnId] = useState<number | null>(null)

  const fileInputRef = useRef<HTMLInputElement>(null)

  const { data: form, isLoading: formLoading } = useQuery({
    queryKey: ['form', id],
    queryFn: () => formsApi.getById(id),
    enabled: Number.isInteger(id),
  })

  const uploadTemplateMutation = useMutation({
    mutationFn: (file: File) => formsApi.uploadTemplate(id, file),
    onSuccess: () => {
      message.success('Đã upload template. Trang nhập liệu sẽ dùng template này làm mẫu.')
      queryClient.invalidateQueries({ queryKey: ['form', id] })
      queryClient.invalidateQueries({ queryKey: ['forms', id] })
      queryClient.invalidateQueries({ queryKey: ['forms', id, 'template-display'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Upload thất bại'),
  })

  if (!Number.isInteger(id) || formLoading) {
    return (
      <Card>
        <Text type="secondary">Đang tải...</Text>
      </Card>
    )
  }
  if (!form) {
    return (
      <Card>
        <Text type="danger">Không tìm thấy biểu mẫu.</Text>
        <Button type="link" onClick={() => navigate('/forms')}>
          Quay lại danh sách
        </Button>
      </Card>
    )
  }

  return (
    <>
      <Breadcrumb
        style={{ marginBottom: 16 }}
        items={[
          { title: <Link to="/forms">Biểu mẫu</Link> },
          { title: form.name },
          { title: 'Cấu hình (hàng, cột, bộ lọc, công thức)' },
        ]}
      />
      <Typography.Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Cấu hình: {form.name}
      </Typography.Title>
      <Space style={{ marginBottom: 16 }} wrap>
        <input
          ref={fileInputRef}
          type="file"
          accept=".xlsx"
          style={{ display: 'none' }}
          onChange={(e) => {
            const file = e.target.files?.[0]
            if (file) {
              uploadTemplateMutation.mutate(file)
              e.target.value = ''
            }
          }}
        />
        <Button
          icon={<UploadOutlined />}
          onClick={() => fileInputRef.current?.click()}
          loading={uploadTemplateMutation.isPending}
        >
          Upload template Excel
        </Button>
        {form.hasTemplateDisplay && (
          <Text type="secondary">Đã có template (dùng làm mẫu nhập liệu)</Text>
        )}
      </Space>

      {/* Nguồn dữ liệu & Bộ lọc – global */}
      <DataSourceSection formId={id} />
      <FilterDefinitionSection formId={id} />

      {/* Sheet selector */}
      <FormSheetSection
        formId={id}
        selectedSheetId={selectedSheetId}
        onSheetSelect={setSelectedSheetId}
        onColumnSelect={setSelectedColumnId}
      />

      {/* Sheet-dependent sections */}
      {selectedSheetId != null && (
        <>
          <FormColumnSection
            formId={id}
            sheetId={selectedSheetId}
            selectedColumnId={selectedColumnId}
            onColumnSelect={setSelectedColumnId}
          />
          <FormRowSection formId={id} sheetId={selectedSheetId} />
          <DynamicRegionSection formId={id} sheetId={selectedSheetId} />
          <PlaceholderOccurrenceSection formId={id} sheetId={selectedSheetId} />
          <DynamicColumnRegionSection formId={id} sheetId={selectedSheetId} />
          <PlaceholderColumnOccurrenceSection formId={id} sheetId={selectedSheetId} />
        </>
      )}

      {/* Workflow config – global */}
      <WorkflowConfigSection formId={id} />

      {/* Column-dependent sections */}
      {selectedSheetId != null && selectedColumnId != null && (
        <>
          <DataBindingSection
            formId={id}
            sheetId={selectedSheetId}
            columnId={selectedColumnId}
          />
          <ColumnMappingSection
            formId={id}
            sheetId={selectedSheetId}
            columnId={selectedColumnId}
          />
        </>
      )}
    </>
  )
}
