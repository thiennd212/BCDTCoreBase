# B10 – Reporting Period, Aggregation, Dashboard (Phase 3 W13–14)

**Phase 3 – Week 13–14** theo [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md).  
**Mục tiêu:** Reporting Period management (CRUD kỳ báo cáo), Aggregation Engine (tính tổng ReportSummary từ ReportDataRow), Dashboard Admin (thống kê) và Dashboard User (nhiệm vụ, hạn nộp).

---

## 1. Tham chiếu

| Tài liệu / Rule | Nội dung |
|-----------------|----------|
| [07.reporting_period.sql](../script_core/sql/v2/07.reporting_period.sql) | BCDT_ReportingFrequency, BCDT_ReportingPeriod, BCDT_ScheduleJob, BCDT_ScheduleJobHistory |
| [06.KE_HOACH_MVP.md](../script_core/06.KE_HOACH_MVP.md) | Phase 3 W13–14: Reporting Period management, Aggregation Engine, Dashboard Admin/User |
| [CẤU_TRÚC_CODEBASE.md](../CẤU_TRÚC_CODEBASE.md) | Module 7 Reporting Period; API response format |
| [04.GIAI_PHAP_KY_THUAT.md](../script_core/04.GIAI_PHAP_KY_THUAT.md) | Hybrid 2-Layer, RLS |
| **always-verify-after-work** | Build, test cases, báo Pass/Fail; RUNBOOK 6.1 trước build |

---

## 2. Schema (trích từ 07.reporting_period.sql)

- **BCDT_ReportingFrequency:** Id, Code (DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY, ADHOC), Name, NameEn, DaysInPeriod, CronExpression, Description, DisplayOrder, IsActive, CreatedAt.
- **BCDT_ReportingPeriod:** Id, ReportingFrequencyId, PeriodCode, PeriodName, Year, Quarter, Month, Week, Day, StartDate, EndDate, Deadline, Status (Open, Closed, Archived), IsCurrent, IsLocked, LockedAt, LockedBy, CreatedAt, CreatedBy.
- **BCDT_ReportSubmission** (05.data_storage): đã có ReportingPeriodId (FK tham chiếu BCDT_ReportingPeriod khi có bảng).
- **BCDT_ReportSummary** (Layer 2.5): tổng tiền pre-calc theo submission/sheet; Aggregation Engine cập nhật từ ReportDataRow.

---

## 3. API cần triển khai

### 3.1. Reporting Frequencies (đọc – seed)

| Method | URL | Mô tả |
|--------|-----|--------|
| GET | /api/v1/reporting-frequencies | Danh sách (query: includeInactive) |

### 3.2. Reporting Periods (CRUD)

| Method | URL | Mô tả |
|--------|-----|--------|
| GET | /api/v1/reporting-periods | Danh sách (query: frequencyId, year, status, isCurrent) |
| GET | /api/v1/reporting-periods/{id} | Chi tiết |
| GET | /api/v1/reporting-periods/current | Kỳ hiện tại (query: frequencyId) |
| POST | /api/v1/reporting-periods | Tạo kỳ (body: ReportingFrequencyId, PeriodCode, PeriodName, Year, Quarter?, Month?, StartDate, EndDate, Deadline) |
| PUT | /api/v1/reporting-periods/{id} | Cập nhật (Status, IsCurrent, IsLocked) |
| DELETE | /api/v1/reporting-periods/{id} | Xóa (chỉ khi chưa có submission) |

### 3.3. Aggregation

| Method | URL | Mô tả |
|--------|-----|--------|
| POST | /api/v1/submissions/{id}/aggregate | Tính lại ReportSummary từ ReportDataRow cho submission |

### 3.4. Dashboard

| Method | URL | Mô tả |
|--------|-----|--------|
| GET | /api/v1/dashboard/admin/stats | Thống kê Admin: tổng submission theo status, theo kỳ, theo form (RLS) |
| GET | /api/v1/dashboard/user/tasks | User: submissions của tôi (Draft/Revision), hạn nộp (Deadline), pending approvals |

---

## 4. Entity & Layer

- **Domain:** ReportingFrequency (đã có), ReportingPeriod (thêm); ReportSubmission đã có ReportingPeriodId.
- **Application:** DTOs (ReportingFrequencyDto, ReportingPeriodDto, Create/UpdateReportingPeriodRequest); IDashboardAdminStatsDto, DashboardUserTaskDto; IReportingFrequencyService, IReportingPeriodService, IAggregationService, IDashboardService.
- **Infrastructure:** ReportingFrequencyService (read-only), ReportingPeriodService (CRUD), AggregationService (tính ReportSummary từ DataRows), DashboardService (stats + user tasks).
- **Api:** ReportingFrequenciesController, ReportingPeriodsController, SubmissionsController (POST {id}/aggregate), DashboardController (admin/stats, user/tasks).

---

## 5. Luồng nghiệp vụ

1. **Kỳ báo cáo:** Admin tạo ReportingPeriod (vd MONTHLY 2026-01); submission tạo mới chọn ReportingPeriodId. List periods filter theo frequencyId, year.
2. **Aggregation:** Sau khi upload Excel / lưu DataRows, gọi POST submissions/{id}/aggregate (hoặc tích hợp vào SaveOrchestrator) để cập nhật ReportSummary.
3. **Dashboard Admin:** GET dashboard/admin/stats trả về số submission theo status, theo period, theo form (theo RLS).
4. **Dashboard User:** GET dashboard/user/tasks trả về: submissions của user (org) có status Draft/Revision; kỳ có Deadline sắp tới; nhiệm vụ duyệt (workflow pending).

---

## 6. Edge cases

- Tạo ReportingPeriod trùng (ReportingFrequencyId, PeriodCode) → 409 Conflict.
- Xóa ReportingPeriod đã có submission tham chiếu → 400 "Không thể xóa kỳ đã có báo cáo".
- POST aggregate với submission không tồn tại → 404.
- Dashboard: RLS áp dụng (user chỉ thấy org mình).

---

## 7. Kiểm tra cho AI (7.1)

**AI sau khi triển khai B10 chạy lần lượt và báo Pass/Fail.**

1. **Build**
   - Trước khi build: hủy process BCDT.Api nếu đang chạy (RUNBOOK 6.1).
   - Lệnh: `dotnet build src/BCDT.Api/BCDT.Api.csproj`
   - Kỳ vọng: Build succeeded.

2. **API đang chạy** (dotnet run --project src/BCDT.Api --launch-profile http). Login lấy token (POST /api/v1/auth/login, admin / Admin@123).

3. **GET /api/v1/reporting-frequencies** (Bearer token)
   - Kỳ vọng: 200, `success: true`, `data` là mảng (seed: DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY, ADHOC).

4. **GET /api/v1/reporting-periods** (Bearer token)
   - Kỳ vọng: 200, `data` là mảng (có thể rỗng).

5. **POST /api/v1/reporting-periods** – tạo kỳ tháng 01/2026
   - Body: `{ "reportingFrequencyId": 3, "periodCode": "2026-01", "periodName": "Tháng 01/2026", "year": 2026, "month": 1, "startDate": "2026-01-01", "endDate": "2026-01-31", "deadline": "2026-02-10", "status": "Open", "isCurrent": true }`
   - Kỳ vọng: 200, `data` có Id, PeriodCode = "2026-01".

6. **GET /api/v1/reporting-periods/{id}** với id vừa tạo
   - Kỳ vọng: 200, `data` khớp.

7. **GET /api/v1/reporting-periods/current?frequencyId=3**
   - Kỳ vọng: 200, `data` là kỳ hiện tại MONTHLY (nếu có).

8. **GET /api/v1/dashboard/admin/stats** (Bearer token)
   - Kỳ vọng: 200, `data` có cấu trúc thống kê (vd submissionCountByStatus, byPeriod).

9. **GET /api/v1/dashboard/user/tasks** (Bearer token)
   - Kỳ vọng: 200, `data` có cấu trúc tasks (drafts, deadlines, pendingApprovals).

10. **Edge: POST reporting-periods trùng periodCode cùng frequencyId**
    - Gửi lại body giống bước 5 (cùng 2026-01, frequencyId 3).
    - Kỳ vọng: 409 Conflict hoặc 400, message chứa "đã tồn tại" / "CONFLICT".

11. **POST /api/v1/submissions/{id}/aggregate** (với submissionId có DataRows)
    - Kỳ vọng: 200; sau đó GET submission/presentation hoặc ReportSummary được cập nhật (tùy đặc tả).

---

## 8. Postman

- Bổ sung folder **Reporting Frequencies**, **Reporting Periods**, **Dashboard (Admin Stats, User Tasks)**, và request **POST submissions/{id}/aggregate** trong [docs/postman/BCDT-API.postman_collection.json](../postman/BCDT-API.postman_collection.json). Xác thực JSON collection hợp lệ.

---

**Version:** 1.0  
**Ngày:** 2026-02-06
