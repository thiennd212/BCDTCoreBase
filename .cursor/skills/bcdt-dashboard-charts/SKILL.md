---
name: bcdt-dashboard-charts
description: Create BCDT dashboard pages and charts (Admin: stats, charts; User: tasks, deadlines). Use when user says "dashboard", "biểu đồ", "thống kê tổng quan", "task list", or FR-DB-01/FR-DB-02.
---

# BCDT Dashboard & Charts

Implement Admin dashboard (FR-DB-01) and User dashboard (FR-DB-02) with DevExtreme charts and grids.

## Workflow

1. **Admin vs User**: Admin = stats, charts, aggregates; User = task list, deadlines, notifications.
2. **Backend**: API returning aggregated data (counts, sums by org/period); use ReportSummary, cache (CacheKeys.DashboardStats).
3. **Frontend**: DevExtreme Chart/PieChart/BarChart; DataGrid for task list; reuse PageHeader, cards.

---

## Admin Dashboard (FR-DB-01)

### API

```csharp
// GET /api/v1/dashboard/admin/stats?organizationId=&periodId=
public record DashboardStatsDto(
    int TotalSubmissions,
    int PendingApproval,
    int ApprovedCount,
    int OverdueCount,
    Dictionary<string, decimal> ChartSeries  // e.g. by form, by status
);
```

### React: Stats cards + Chart

```tsx
// Stats: 4 cards (Total, Pending, Approved, Overdue)
// Chart: DevExtreme Chart
import Chart, { Series, Legend, Tooltip } from 'devextreme-react/chart';
import { useDashboardStats } from '@/hooks/useDashboard';

<Chart dataSource={chartData}>
  <Series valueField="count" argumentField="label" type="bar" />
  <Legend visible={false} />
  <Tooltip enabled />
</Chart>
```

---

## User Dashboard (FR-DB-02)

### API

- `GET /api/v1/dashboard/user/tasks` — submissions pending my action (approver), my drafts, deadlines.
- `GET /api/v1/notifications` — already exists; show unread count and list.

### React: Task list + deadlines

- DataGrid: columns SubmissionId, FormName, Deadline, Status, Action (link to approve/edit).
- Filter: Pending approval / My drafts / Overdue.
- Optional: small chart (e.g. submissions by period).

---

## Conventions

- Cache dashboard stats: key `dashboard:{orgId}`, TTL 1 min (see docs CacheKeys.DashboardStats).
- Use ReportSummary for pre-calculated totals where applicable.
- Charts: responsive; use same theme as app (DevExtreme theme).
- Permissions: Admin dashboard only for roles with dashboard permission; User dashboard for all authenticated.

---

## Checklist

- [ ] Admin stats API and cache
- [ ] User tasks API (filter by current user)
- [ ] DevExtreme Chart/Bar/Pie for admin
- [ ] DataGrid for user task list with link to submission/approval
- [ ] Routes: /dashboard (user), /admin/dashboard (admin) or by role
