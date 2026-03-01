import { useState } from 'react'
import { useQuery } from '@tanstack/react-query'
import { Card, Row, Col, Statistic, Table, Typography, Select, Button, Space } from 'antd'
import {
  FileTextOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  ExclamationCircleOutlined,
  DownloadOutlined,
} from '@ant-design/icons'
import { dashboardApi } from '../api/dashboardApi'
import { reportingPeriodsApi } from '../api/reportingPeriodsApi'
import { EmptyState } from '../components/EmptyState'
import type { DashboardAdminStatsDto } from '../types/dashboard.types'

const { Title } = Typography

/** Export thống kê admin ra file CSV (client-side). */
function exportStatsCsv(stats: DashboardAdminStatsDto, periodLabel: string) {
  const rows: string[][] = []

  rows.push(['Thống kê báo cáo', periodLabel])
  rows.push([])
  rows.push(['Chỉ số', 'Số lượng'])
  rows.push(['Tổng số', String(stats.totalSubmissions)])
  rows.push(['Nháp', String(stats.draftCount)])
  rows.push(['Đã gửi', String(stats.submittedCount)])
  rows.push(['Đã duyệt', String(stats.approvedCount)])
  rows.push(['Từ chối', String(stats.rejectedCount)])
  rows.push(['Chỉnh sửa', String(stats.revisionCount)])

  if (stats.submissionsByPeriod.length > 0) {
    rows.push([])
    rows.push(['Theo kỳ báo cáo', ''])
    rows.push(['Kỳ', 'Số lượng'])
    stats.submissionsByPeriod.forEach((p) => rows.push([p.periodName, String(p.count)]))
  }

  if (stats.submissionsByForm.length > 0) {
    rows.push([])
    rows.push(['Theo biểu mẫu', ''])
    rows.push(['Biểu mẫu', 'Số lượng'])
    stats.submissionsByForm.forEach((f) => rows.push([f.formName, String(f.count)]))
  }

  const csv = rows.map((r) => r.map((c) => `"${c.replace(/"/g, '""')}"`).join(',')).join('\n')
  const bom = '\uFEFF'
  const blob = new Blob([bom + csv], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = `dashboard_stats_${new Date().toISOString().slice(0, 10)}.csv`
  document.body.appendChild(a)
  a.click()
  URL.revokeObjectURL(url)
  document.body.removeChild(a)
}

export function DashboardPage() {
  const [selectedPeriodId, setSelectedPeriodId] = useState<number | null>(null)

  const { data: periods = [] } = useQuery({
    queryKey: ['reporting-periods', 'dashboard-filter'],
    queryFn: () => reportingPeriodsApi.getList(),
  })

  const { data: adminStats, isLoading: loadingAdmin } = useQuery({
    queryKey: ['dashboard', 'admin-stats', selectedPeriodId],
    queryFn: () => dashboardApi.getAdminStats(selectedPeriodId),
  })

  const { data: userTasks, isLoading: loadingUser } = useQuery({
    queryKey: ['dashboard', 'user-tasks'],
    queryFn: () => dashboardApi.getUserTasks(),
  })

  const periodOptions = periods.map((p) => ({ value: p.id, label: `${p.periodCode} – ${p.periodName}` }))
  const selectedPeriodLabel = selectedPeriodId
    ? (periods.find((p) => p.id === selectedPeriodId)?.periodName ?? '')
    : 'Tất cả kỳ'

  return (
    <>
      <Title level={2} style={{ marginTop: 0, marginBottom: 16 }}>
        Tổng quan
      </Title>

      {/* Toolbar: filter kỳ + export */}
      <Space wrap style={{ marginBottom: 16 }}>
        <Select
          allowClear
          placeholder="Lọc theo kỳ báo cáo"
          style={{ minWidth: 240 }}
          options={periodOptions}
          value={selectedPeriodId ?? undefined}
          onChange={(v) => setSelectedPeriodId(v ?? null)}
        />
        <Button
          icon={<DownloadOutlined />}
          disabled={!adminStats}
          onClick={() => adminStats && exportStatsCsv(adminStats, selectedPeriodLabel)}
        >
          Xuất CSV
        </Button>
      </Space>

      <Row gutter={[16, 16]}>
        <Col xs={24} md={12} lg={8}>
          <Card loading={loadingAdmin} title="Thống kê báo cáo">
            {adminStats && (
              <Row gutter={16}>
                <Col span={12}>
                  <Statistic title="Tổng số" value={adminStats.totalSubmissions} prefix={<FileTextOutlined />} />
                </Col>
                <Col span={12}>
                  <Statistic title="Nháp" value={adminStats.draftCount} />
                </Col>
                <Col span={12}>
                  <Statistic title="Đã gửi" value={adminStats.submittedCount} prefix={<ClockCircleOutlined />} />
                </Col>
                <Col span={12}>
                  <Statistic title="Đã duyệt" value={adminStats.approvedCount} prefix={<CheckCircleOutlined />} />
                </Col>
                <Col span={12}>
                  <Statistic title="Từ chối" value={adminStats.rejectedCount} prefix={<CloseCircleOutlined />} />
                </Col>
                <Col span={12}>
                  <Statistic title="Chỉnh sửa" value={adminStats.revisionCount} prefix={<ExclamationCircleOutlined />} />
                </Col>
              </Row>
            )}
          </Card>
        </Col>

        <Col xs={24} md={12} lg={8}>
          <Card loading={loadingAdmin} title="Theo kỳ báo cáo">
            {adminStats?.submissionsByPeriod && adminStats.submissionsByPeriod.length > 0 ? (
              <Table
                size="small"
                rowKey="reportingPeriodId"
                dataSource={adminStats.submissionsByPeriod}
                columns={[
                  { title: 'Kỳ', dataIndex: 'periodName', key: 'periodName', ellipsis: true },
                  { title: 'Số lượng', dataIndex: 'count', key: 'count', width: 80 },
                ]}
                pagination={false}
              />
            ) : (
              <EmptyState compact description="Chưa có dữ liệu" />
            )}
          </Card>
        </Col>

        <Col xs={24} md={12} lg={8}>
          <Card loading={loadingAdmin} title="Theo biểu mẫu">
            {adminStats?.submissionsByForm && adminStats.submissionsByForm.length > 0 ? (
              <Table
                size="small"
                rowKey="formDefinitionId"
                dataSource={adminStats.submissionsByForm}
                columns={[
                  { title: 'Biểu mẫu', dataIndex: 'formName', key: 'formName', ellipsis: true },
                  { title: 'Số lượng', dataIndex: 'count', key: 'count', width: 80 },
                ]}
                pagination={false}
              />
            ) : (
              <EmptyState compact description="Chưa có dữ liệu" />
            )}
          </Card>
        </Col>
      </Row>

      <Row gutter={[16, 16]} style={{ marginTop: 16 }}>
        <Col xs={24} lg={12}>
          <Card loading={loadingUser} title="Báo cáo nháp / Chỉnh sửa">
            {userTasks && (userTasks.drafts.length > 0 || userTasks.revisions.length > 0) ? (
              <Table
                size="small"
                rowKey="submissionId"
                dataSource={[...userTasks.drafts, ...userTasks.revisions]}
                columns={[
                  { title: 'Biểu mẫu', dataIndex: 'formName', key: 'formName', ellipsis: true },
                  { title: 'Kỳ', dataIndex: 'periodName', key: 'periodName', ellipsis: true },
                  { title: 'Trạng thái', dataIndex: 'status', key: 'status', width: 90 },
                ]}
                pagination={false}
              />
            ) : (
              <EmptyState compact description="Không có báo cáo nháp hoặc yêu cầu chỉnh sửa" />
            )}
          </Card>
        </Col>

        <Col xs={24} lg={12}>
          <Card loading={loadingUser} title="Chờ duyệt">
            {userTasks?.pendingApprovals && userTasks.pendingApprovals.length > 0 ? (
              <Table
                size="small"
                rowKey="workflowInstanceId"
                dataSource={userTasks.pendingApprovals}
                columns={[
                  { title: 'Biểu mẫu', dataIndex: 'formName', key: 'formName', ellipsis: true },
                  { title: 'Đơn vị', dataIndex: 'organizationName', key: 'organizationName', ellipsis: true },
                  {
                    title: 'Bước',
                    key: 'step',
                    width: 70,
                    render: (_: unknown, r: { currentStep: number; totalSteps: number }) =>
                      `${r.currentStep}/${r.totalSteps}`,
                  },
                ]}
                pagination={false}
              />
            ) : (
              <EmptyState compact description="Không có nhiệm vụ chờ duyệt" />
            )}
          </Card>
        </Col>
      </Row>
    </>
  )
}
