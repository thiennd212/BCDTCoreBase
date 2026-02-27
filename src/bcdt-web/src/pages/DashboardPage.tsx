import { useQuery } from '@tanstack/react-query'
import { Card, Row, Col, Statistic, Table, Typography } from 'antd'
import {
  FileTextOutlined,
  ClockCircleOutlined,
  CheckCircleOutlined,
  CloseCircleOutlined,
  ExclamationCircleOutlined,
} from '@ant-design/icons'
import { dashboardApi } from '../api/dashboardApi'
import { EmptyState } from '../components/EmptyState'

const { Title } = Typography

export function DashboardPage() {
  const { data: adminStats, isLoading: loadingAdmin } = useQuery({
    queryKey: ['dashboard', 'admin-stats'],
    queryFn: () => dashboardApi.getAdminStats(),
  })

  const { data: userTasks, isLoading: loadingUser } = useQuery({
    queryKey: ['dashboard', 'user-tasks'],
    queryFn: () => dashboardApi.getUserTasks(),
  })

  return (
    <>
      <Title level={2} style={{ marginTop: 0, marginBottom: 24 }}>
        Tổng quan
      </Title>

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
                  { title: 'Bước', key: 'step', render: (_: unknown, r: { currentStep: number; totalSteps: number }) => `${r.currentStep}/${r.totalSteps}` },
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
