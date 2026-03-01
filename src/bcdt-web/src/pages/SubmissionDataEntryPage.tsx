import { useState, useMemo, useEffect, useCallback, useRef } from 'react'
import { useParams, useNavigate, Link } from 'react-router-dom'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query'
import {
  Breadcrumb,
  Card,
  Typography,
  Button,
  message,
  Table,
  Input,
  Space,
  Popconfirm,
  Spin,
  Alert,
} from 'antd'
import { DownloadOutlined, SyncOutlined, SaveOutlined, PlusOutlined, DeleteOutlined, ExclamationCircleOutlined } from '@ant-design/icons'
import { PageSkeleton } from '../components/PageSkeleton'
import { QueryErrorDisplay } from '../components/ErrorPage'
import { ErrorBoundary } from '../components/ErrorBoundary'
import { EmptyState } from '../components/EmptyState'
import { Workbook, type WorkbookInstance } from '@fortune-sheet/react'
import type { Sheet } from '@fortune-sheet/core'
import '@fortune-sheet/react/dist/index.css'
import { FortuneExcelHelper, importToolBarItem } from '@corbe30/fortune-excel'
import { submissionsApi } from '../api/submissionsApi'
import { getApiErrorMessage } from '../api/apiClient'
import { formsApi } from '../api/formsApi'
import { formSheetsApi, formColumnsApi, formDynamicRegionsApi } from '../api/formStructureApi'
import type { FormSheetDto, FormColumnDto } from '../types/form.types'
import type {
  WorkbookSheetData,
  PutDynamicIndicatorsRequest,
  DynamicIndicatorItemRequest,
} from '../types/submission.types'
import type { FormDynamicRegionDto } from '../types/form.types'
import {
  isFortuneSheetFormat,
  isSimpleWorkbookFormat,
  simpleToFortuneSheets,
  applyFormConfigToFortuneSheets,
  mergeTemplateWithData,
} from '../utils/fortuneSheetAdapter'
import { downloadFortuneSheetsAsXlsx } from '../utils/exportSheetJsXlsx'
const { Text } = Typography

/** Vùng chỉ tiêu động kèm tên sheet (để hiển thị) */
interface RegionWithSheet extends FormDynamicRegionDto {
  sheetName: string
}

/** Một dòng chỉ tiêu động đang chỉnh sửa (local state) */
interface DynamicRowEdit {
  indicatorName: string
  indicatorValue: string
}

/** Hash SHA-256 của chuỗi (hex) */
async function sha256Hex(text: string): Promise<string> {
  const buf = await crypto.subtle.digest('SHA-256', new TextEncoder().encode(text))
  return Array.from(new Uint8Array(buf))
    .map((b) => b.toString(16).padStart(2, '0'))
    .join('')
    .toLowerCase()
}

function buildSimpleWorkbook(
  sheets: FormSheetDto[],
  columnsBySheet: Map<number, FormColumnDto[]>,
  existingJson: string | null
): WorkbookSheetData[] {
  if (existingJson) {
    try {
      const parsed = JSON.parse(existingJson) as { sheets?: { name: string; rows?: Record<string, unknown>[] }[] }
      if (parsed.sheets?.length) return parsed.sheets.map((s) => ({ name: s.name, rows: s.rows ?? [] }))
    } catch {
      /* ignore */
    }
  }
  return sheets.map((sheet) => {
    const cols = columnsBySheet.get(sheet.id) ?? []
    const emptyRow: Record<string, unknown> = {}
    cols.forEach((c) => {
      const key = c.excelColumn ?? ''
      if (key) emptyRow[key] = ''
    })
    return { name: sheet.sheetName, rows: [emptyRow] }
  })
}

export function SubmissionDataEntryPage() {
  const { submissionId } = useParams<{ submissionId: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const id = submissionId ? parseInt(submissionId, 10) : NaN
  const [sheetData, setSheetData] = useState<Sheet[] | null>(null)
  const [workbookKey, setWorkbookKey] = useState(0)
  const sheetRef = useRef<WorkbookInstance | null>(null)

  const { data: submission, isLoading: subLoading, isError: subError, error: subErr } = useQuery({
    queryKey: ['submission', id],
    queryFn: () => submissionsApi.getById(id),
    enabled: Number.isInteger(id),
    retry: 1,
  })

  const { data: sheets = [], isLoading: sheetsLoading, isError: sheetsError, error: sheetsErr } = useQuery({
    queryKey: ['forms', submission?.formDefinitionId, 'sheets'],
    queryFn: () => formSheetsApi.getList(submission!.formDefinitionId),
    enabled: submission != null,
    retry: 1,
  })

  const { data: form } = useQuery({
    queryKey: ['forms', submission?.formDefinitionId],
    queryFn: () => formsApi.getById(submission!.formDefinitionId),
    enabled: submission != null,
  })

  const { data: allColumns = [], isLoading: colsLoading } = useQuery({
    queryKey: ['forms', submission?.formDefinitionId, 'sheets', sheets.map((s) => s.id).join(',')],
    queryFn: async () => {
      if (!submission || sheets.length === 0) return []
      const list: FormColumnDto[] = []
      for (const sheet of sheets) {
        const cols = await formColumnsApi.getList(submission.formDefinitionId, sheet.id)
        list.push(...cols)
      }
      return list
    },
    enabled: submission != null && sheets.length > 0,
  })

  const { data: presentation, isFetched: presFetched } = useQuery({
    queryKey: ['submission', id, 'presentation'],
    queryFn: () => submissionsApi.getPresentation(id),
    enabled: Number.isInteger(id),
  })

  const columnsBySheet = useMemo(() => {
    const map = new Map<number, FormColumnDto[]>()
    for (const col of allColumns) {
      const arr = map.get(col.formSheetId) ?? []
      arr.push(col)
      map.set(col.formSheetId, arr)
    }
    for (const arr of map.values()) arr.sort((a, b) => a.displayOrder - b.displayOrder)
    return map
  }, [allColumns])

  const sheetIdsOrder = useMemo(() => sheets.map((s) => s.id), [sheets])

  /** Tất cả vùng chỉ tiêu động của biểu mẫu (theo từng sheet) */
  const { data: dynamicRegionsAll = [], isLoading: regionsLoading } = useQuery({
    queryKey: ['forms', submission?.formDefinitionId, 'dynamic-regions-all', sheetIdsOrder.join(',')],
    queryFn: async (): Promise<RegionWithSheet[]> => {
      if (!submission || sheets.length === 0) return []
      const list: RegionWithSheet[] = []
      for (const s of sheets) {
        const regions = await formDynamicRegionsApi.getList(submission.formDefinitionId, s.id)
        list.push(...regions.map((r) => ({ ...r, sheetName: s.sheetName })))
      }
      return list
    },
    enabled: !!submission && sheets.length > 0,
  })

  const { data: dynamicIndicators = [], isFetched: dynamicIndicatorsFetched } = useQuery({
    queryKey: ['submission', id, 'dynamic-indicators'],
    queryFn: () => submissionsApi.getDynamicIndicators(id),
    enabled: Number.isInteger(id) && !!submission && (submission.status === 'Draft' || submission.status === 'Revision'),
  })

  /** State chỉnh sửa: regionId -> danh sách dòng (Tên chỉ tiêu, Giá trị) */
  const [dynamicRowsByRegion, setDynamicRowsByRegion] = useState<Record<number, DynamicRowEdit[]>>({})

  useEffect(() => {
    if (!dynamicIndicatorsFetched || dynamicRegionsAll.length === 0) return
    const byRegion: Record<number, DynamicRowEdit[]> = {}
    const sorted = [...dynamicIndicators].sort((a, b) => a.formDynamicRegionId - b.formDynamicRegionId || a.rowOrder - b.rowOrder)
    for (const item of sorted) {
      const arr = byRegion[item.formDynamicRegionId] ?? []
      arr.push({
        indicatorName: item.indicatorName ?? '',
        indicatorValue: item.indicatorValue ?? '',
      })
      byRegion[item.formDynamicRegionId] = arr
    }
    for (const r of dynamicRegionsAll) {
      if (!(r.id in byRegion)) byRegion[r.id] = []
    }
    setDynamicRowsByRegion(byRegion)
  }, [dynamicIndicatorsFetched, dynamicIndicators, dynamicRegionsAll])

  const needWorkbookFromForm = presFetched && (presentation == null || !(presentation?.workbookJson?.trim?.()))
  const { data: workbookFromSubmission, isFetched: workbookDataFetched } = useQuery({
    queryKey: ['submission', id, 'workbook-data'],
    queryFn: () => submissionsApi.getWorkbookData(id),
    enabled: Number.isInteger(id) && !!needWorkbookFromForm,
  })

  const useTemplateDisplay = needWorkbookFromForm && !!form?.hasTemplateDisplay && !!submission?.formDefinitionId
  const { data: templateDisplayParsed, isFetched: templateDisplayFetched } = useQuery({
    queryKey: ['forms', submission?.formDefinitionId, 'template-display'],
    queryFn: async () => {
      const raw = await formsApi.getTemplateDisplay(submission!.formDefinitionId)
      return raw
    },
    enabled: !!useTemplateDisplay,
  })

  useEffect(() => {
    if (!sheets.length || !columnsBySheet.size || !presFetched || sheetData !== null) return
    const raw = presentation?.workbookJson ?? null
    let data: Sheet[]
    if (raw?.trim()) {
      try {
        const parsed = JSON.parse(raw) as unknown
        if (isFortuneSheetFormat(parsed)) {
          data = applyFormConfigToFortuneSheets(parsed, columnsBySheet, sheetIdsOrder)
          setSheetData(data)
          return
        }
        if (isSimpleWorkbookFormat(parsed)) {
          data = simpleToFortuneSheets(
            parsed.sheets,
            columnsBySheet,
            sheetIdsOrder
          )
          setSheetData(data)
          return
        }
      } catch {
        /* fallback */
      }
    }
    if (needWorkbookFromForm) {
      if (useTemplateDisplay && templateDisplayFetched && isFortuneSheetFormat(templateDisplayParsed)) {
        const templateSheets = templateDisplayParsed as Sheet[]
        const n = Math.min(templateSheets.length, sheetIdsOrder.length)
        if (n > 0) {
          const dataSheets = (workbookFromSubmission?.sheets ?? []).map(
            (s: { name: string; rows?: Record<string, unknown>[] }) => ({ name: s.name, rows: s.rows ?? [] })
          ) as { name: string; rows: Record<string, unknown>[] }[]
          const padded = templateSheets.slice(0, n).map((t, i) => dataSheets[i] ?? { name: t.name, rows: [] })
          const dataStartRowBySheet = new Map<number, number>()
          sheets.forEach((s) => {
            if (s.dataStartRow != null && s.dataStartRow >= 1) dataStartRowBySheet.set(s.id, s.dataStartRow)
          })
          data = mergeTemplateWithData(
            templateSheets.slice(0, n),
            padded,
            columnsBySheet,
            sheetIdsOrder.slice(0, n),
            dataStartRowBySheet.size > 0 ? dataStartRowBySheet : undefined
          )
          data = applyFormConfigToFortuneSheets(data, columnsBySheet, sheetIdsOrder.slice(0, n))
          setSheetData(data)
          return
        }
      }
      if (!workbookDataFetched) return
    }
    if (workbookFromSubmission?.sheets?.length) {
      data = simpleToFortuneSheets(
        workbookFromSubmission.sheets as { name: string; rows: Record<string, unknown>[] }[],
        columnsBySheet,
        sheetIdsOrder
      )
      setSheetData(data)
      return
    }
    const simple = buildSimpleWorkbook(sheets, columnsBySheet, null)
    data = simpleToFortuneSheets(simple, columnsBySheet, sheetIdsOrder)
    setSheetData(data)
  }, [
    sheets,
    columnsBySheet,
    presFetched,
    presentation?.workbookJson,
    sheetIdsOrder,
    needWorkbookFromForm,
    workbookDataFetched,
    workbookFromSubmission,
    useTemplateDisplay,
    templateDisplayFetched,
    templateDisplayParsed,
  ])

  const putPresentationMutation = useMutation({
    mutationFn: async (payload: { workbookJson: string; workbookHash: string; fileSize: number; sheetCount: number }) =>
      submissionsApi.putPresentation(id, payload),
    onSuccess: () => {
      message.success('Đã lưu dữ liệu')
      queryClient.invalidateQueries({ queryKey: ['submission', id, 'presentation'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Lưu thất bại'),
  })

  const syncFromPresentationMutation = useMutation({
    mutationFn: () => submissionsApi.syncFromPresentation(id),
    onSuccess: (data) => {
      message.success(data.message ?? `Đã đồng bộ ${data.dataRowCount} dòng vào bảng dữ liệu.`)
      queryClient.invalidateQueries({ queryKey: ['submission', id] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Đồng bộ thất bại'),
  })

  const putDynamicIndicatorsMutation = useMutation({
    mutationFn: (body: PutDynamicIndicatorsRequest) => submissionsApi.putDynamicIndicators(id, body),
    onSuccess: () => {
      message.success('Đã lưu chỉ tiêu động')
      queryClient.invalidateQueries({ queryKey: ['submission', id, 'dynamic-indicators'] })
      queryClient.invalidateQueries({ queryKey: ['submission', id, 'workbook-data'] })
    },
    onError: (e) => message.error(getApiErrorMessage(e) || 'Lưu chỉ tiêu động thất bại'),
  })

  const addDynamicRow = useCallback((regionId: number) => {
    setDynamicRowsByRegion((prev) => {
      const arr = [...(prev[regionId] ?? []), { indicatorName: '', indicatorValue: '' }]
      return { ...prev, [regionId]: arr }
    })
  }, [])

  const removeDynamicRow = useCallback((regionId: number, index: number) => {
    setDynamicRowsByRegion((prev) => {
      const arr = (prev[regionId] ?? []).filter((_, i) => i !== index)
      return { ...prev, [regionId]: arr }
    })
  }, [])

  const updateDynamicRow = useCallback((regionId: number, index: number, field: 'indicatorName' | 'indicatorValue', value: string) => {
    setDynamicRowsByRegion((prev) => {
      const arr = [...(prev[regionId] ?? [])]
      if (arr[index]) arr[index] = { ...arr[index], [field]: value }
      return { ...prev, [regionId]: arr }
    })
  }, [])

  const handleSaveDynamicIndicators = useCallback(() => {
    const items: DynamicIndicatorItemRequest[] = []
    for (const [regionIdStr, rows] of Object.entries(dynamicRowsByRegion)) {
      const regionId = Number(regionIdStr)
      rows.forEach((row, rowOrder) => {
        items.push({
          formDynamicRegionId: regionId,
          rowOrder,
          indicatorName: row.indicatorName,
          indicatorValue: row.indicatorValue || undefined,
        })
      })
    }
    putDynamicIndicatorsMutation.mutate({ items })
  }, [dynamicRowsByRegion, putDynamicIndicatorsMutation])

  const handleSave = useCallback(() => {
    if (!sheetData || sheetData.length === 0) return
    const workbookJson = JSON.stringify(sheetData)
    sha256Hex(workbookJson).then((workbookHash) => {
      const fileSize = new TextEncoder().encode(workbookJson).length
      putPresentationMutation.mutate({
        workbookJson,
        workbookHash,
        fileSize,
        sheetCount: sheetData.length,
      })
    })
  }, [sheetData, putPresentationMutation])

  /** Tải Excel (.xlsx) chuẩn – dùng SheetJS, mở bằng Excel không báo lỗi repair. */
  const handleDownloadXlsx = useCallback(() => {
    const sheets = sheetRef.current?.getAllSheets?.() ?? sheetData ?? []
    if (sheets.length === 0) {
      message.warning('Chưa có dữ liệu sheet để tải.')
      return
    }
    const name = submission ? `BaoCao_${submission.id}` : 'export'
    downloadFortuneSheetsAsXlsx(sheets, name)
    message.success('Đã tải file Excel.')
  }, [sheetData, submission])

  if (!Number.isInteger(id) || subLoading) {
    return <PageSkeleton title="Đang tải báo cáo..." rows={4} />
  }
  if (subError) {
    return <QueryErrorDisplay error={subErr} />
  }
  if (!submission) {
    return <QueryErrorDisplay error={{ status: 404 }} />
  }
  if (sheetsError) {
    return <QueryErrorDisplay error={sheetsErr} />
  }
  if (submission.status !== 'Draft' && submission.status !== 'Revision') {
    return (
      <Card>
        <Alert
          type="warning"
          icon={<ExclamationCircleOutlined />}
          showIcon
          message="Không thể nhập liệu"
          description={`Chỉ báo cáo trạng thái Nháp hoặc Chỉnh sửa mới nhập liệu được. Trạng thái hiện tại: ${submission.status}.`}
          action={
            <Button size="small" onClick={() => navigate('/submissions')}>
              Quay lại
            </Button>
          }
        />
      </Card>
    )
  }

  const dataLoading = sheetsLoading || colsLoading || (sheetData === null && presFetched)
  if (dataLoading && sheetData === null) {
    return <PageSkeleton title="Đang tải cấu trúc biểu mẫu..." rows={3} />
  }
  if (presFetched && sheets.length === 0) {
    return (
      <EmptyState
        description="Biểu mẫu chưa có sheet/cột. Vào Cấu hình biểu mẫu để thêm hàng và cột, sau đó quay lại nhập liệu."
        actionLabel="Mở cấu hình biểu mẫu"
        onAction={() => navigate(`/forms/${submission.formDefinitionId}/config`)}
      />
    )
  }
  const safeSheetData = sheetData ?? []

  return (
    <div style={{ display: 'flex', flexDirection: 'column', height: 'calc(100vh - 88px)', minHeight: 400 }}>
      <div style={{ flexShrink: 0, display: 'flex', alignItems: 'center', justifyContent: 'space-between', flexWrap: 'wrap', gap: 8, marginBottom: 8 }}>
        <Breadcrumb
          style={{ marginBottom: 0 }}
          items={[
            { title: <Link to="/submissions">Báo cáo</Link> },
            { title: `Báo cáo #${submission.id}` },
            { title: 'Nhập liệu Excel' },
          ]}
        />
        <span style={{ display: 'flex', gap: 8, flexWrap: 'wrap', alignItems: 'center' }}>
          {putPresentationMutation.isError && (
            <Text type="danger" style={{ fontSize: 12 }}>
              <ExclamationCircleOutlined /> Lưu thất bại – thử lại
            </Text>
          )}
          <Button size="middle" icon={<DownloadOutlined />} onClick={handleDownloadXlsx}>
            Tải Excel (.xlsx)
          </Button>
          <Button
            size="middle"
            icon={<SyncOutlined />}
            onClick={() => syncFromPresentationMutation.mutate()}
            loading={syncFromPresentationMutation.isPending}
          >
            Đồng bộ dữ liệu
          </Button>
          <Button
            size="middle"
            type="primary"
            icon={<SaveOutlined />}
            onClick={handleSave}
            loading={putPresentationMutation.isPending}
          >
            Lưu
          </Button>
        </span>
      </div>

      {dynamicRegionsAll.length > 0 && (
        <Card title="Chỉ tiêu động" size="small" style={{ marginBottom: 8 }}>
          {regionsLoading ? (
            <Spin size="small" />
          ) : (
            <>
              {dynamicRegionsAll.map((region) => {
                const rows = dynamicRowsByRegion[region.id] ?? []
                return (
                  <div key={region.id} style={{ marginBottom: 16 }}>
                    <Text strong>
                      {region.sheetName} – Cột {region.excelColName} / {region.excelColValue}
                    </Text>
                    <Table
                      size="small"
                      bordered
                      pagination={false}
                      dataSource={rows.map((r, i) => ({ key: i, ...r }))}
                      columns={[
                        { title: 'Tên chỉ tiêu', dataIndex: 'indicatorName', key: 'indicatorName', render: (v: string, __: unknown, index: number) => <Input value={v} onChange={(e) => updateDynamicRow(region.id, index, 'indicatorName', e.target.value)} placeholder="Tên chỉ tiêu" /> },
                        { title: 'Giá trị', dataIndex: 'indicatorValue', key: 'indicatorValue', render: (v: string, __: unknown, index: number) => <Input value={v} onChange={(e) => updateDynamicRow(region.id, index, 'indicatorValue', e.target.value)} placeholder="Giá trị" /> },
                        {
                          title: '',
                          key: 'actions',
                          width: 56,
                          render: (_: unknown, __: unknown, index: number) => (
                            <Popconfirm title="Xóa dòng?" onConfirm={() => removeDynamicRow(region.id, index)} okText="Xóa" cancelText="Hủy">
                              <Button type="text" size="small" danger icon={<DeleteOutlined />} />
                            </Popconfirm>
                          ),
                        },
                      ]}
                      style={{ marginTop: 8 }}
                    />
                    <Button type="dashed" size="small" icon={<PlusOutlined />} onClick={() => addDynamicRow(region.id)} style={{ marginTop: 4 }}>
                      Thêm dòng
                    </Button>
                  </div>
                )
              })}
              <Space style={{ marginTop: 8 }}>
                <Button type="primary" size="small" icon={<SaveOutlined />} onClick={handleSaveDynamicIndicators} loading={putDynamicIndicatorsMutation.isPending}>
                  Lưu chỉ tiêu động
                </Button>
              </Space>
            </>
          )}
        </Card>
      )}

      <Card
        size="small"
        style={{ flex: 1, marginBottom: 0, display: 'flex', flexDirection: 'column', overflow: 'hidden' }}
        styles={{ body: { flex: 1, minHeight: 0, display: 'flex', flexDirection: 'column', overflow: 'hidden', paddingBottom: 12 } }}
      >
        <Text type="secondary" style={{ flexShrink: 0, display: 'block', marginBottom: 6, fontSize: 12 }}>
          Công thức, định dạng, khóa ô. Tải Excel (.xlsx) để mở không lỗi; Import trên toolbar. Chỉnh sửa xong bấm Lưu → Đồng bộ dữ liệu.
        </Text>
        {safeSheetData.length === 0 ? (
          <div style={{ flex: 1, display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Spin tip="Đang tải bảng tính..." />
          </div>
        ) : (
          <div style={{ flex: 1, minHeight: 0, border: '1px solid #e8e8e8', borderRadius: 6, overflow: 'hidden' }}>
            <FortuneExcelHelper
              setKey={setWorkbookKey}
              setSheets={setSheetData}
              sheetRef={sheetRef}
              config={{
                import: { xlsx: true, csv: true },
                export: { xlsx: false, csv: false },
              }}
            />
            <ErrorBoundary>
              <Workbook
                key={workbookKey}
                ref={sheetRef}
                data={safeSheetData}
                onChange={setSheetData}
                showFormulaBar={true}
                showToolbar={true}
                showSheetTabs={true}
                allowEdit={true}
                lang="vi"
                customToolbarItems={[importToolBarItem()]}
              />
            </ErrorBoundary>
          </div>
        )}
      </Card>
    </div>
  )
}
