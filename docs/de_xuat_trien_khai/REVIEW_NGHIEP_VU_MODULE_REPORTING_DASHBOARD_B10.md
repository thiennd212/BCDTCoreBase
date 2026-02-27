# Báo cáo Review nghiệp vụ – Module Reporting & Dashboard (B10)

**Ngày:** 2026-02-24  
**Agent:** bcdt-business-reviewer  
**Phạm vi:** Chu kỳ báo cáo (CK-*), Tổng hợp & Báo cáo (FR-TH-*), Dashboard (FR-DB-*); Reporting Frequency/Period, Aggregation, Dashboard Admin/User.

---

## 1. Phạm vi review

- **Yêu cầu nguồn:** 01.YEU_CAU_HE_THONG (CK-01–CK-04, FR-TH-01–FR-TH-03, FR-DB-01–FR-DB-02), YEU_CAU_HE_THONG_TONG_HOP, B10_REPORTING_PERIOD.md.
- **Implementation:** ReportingFrequenciesController, ReportingPeriodsController, DashboardController; SubmissionsController (POST {id}/aggregate); IReportingFrequencyService, IReportingPeriodService, IAggregationService, IDashboardService; BCDT_ReportingFrequency, BCDT_ReportingPeriod; FE ReportingPeriodsPage, DashboardPage.

---

## 2. Bảng đối chiếu (Yêu cầu ↔ Implementation)

| # | Yêu cầu | Nguồn | Implementation | Trạng thái |
|---|---------|-------|----------------|------------|
| 1 | Đa chu kỳ (Ngày, Tuần, Tháng, Quý, Năm, Đột xuất) | CK-01 | BCDT_ReportingFrequency (Code: DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY, ADHOC); GET /reporting-frequencies; seed đủ 6 loại | **Đạt** |
| 2 | Tự động tạo kỳ báo cáo mới | CK-02 | Admin tạo kỳ thủ công qua POST /reporting-periods; B10 doc có BCDT_ScheduleJob trong schema nhưng **chưa có** Hangfire/scheduled job tạo kỳ tự động trong code | **Một phần** (tạo thủ công đủ; auto-create chưa) |
| 3 | Hạn nộp linh hoạt theo chu kỳ | CK-03 | ReportingPeriod.Deadline (cấu hình theo kỳ); FormDefinition.DeadlineOffsetDays; submission gắn ReportingPeriodId | **Đạt** |
| 4 | Cho phép / không cho phép nộp trễ | CK-04 | FormDefinition.AllowLateSubmission; kiểm tra khi submit (block submit quá hạn nếu AllowLateSubmission = false) | **Đạt** |
| 5 | Auto-aggregation (tự động tổng hợp theo công thức) | FR-TH-01 | POST /submissions/{id}/aggregate; AggregationService cập nhật ReportSummary từ ReportDataRow; có thể gọi sau khi lưu/sync DataRows | **Đạt** |
| 6 | Drill-down (xem chi tiết từ tổng hợp) | FR-TH-02 | Xem chi tiết submission/workbook-data đã có; chưa có API riêng "từ ReportSummary drill xuống ReportDataRow" dạng một endpoint; FE có thể ghép từ submission list + workbook-data | **Một phần** (drill qua submission/ workbook-data có; endpoint drill-down riêng chưa) |
| 7 | Export báo cáo tổng hợp | FR-TH-03 | Export Excel từ submission/workbook đã có; chưa có endpoint riêng "export aggregated report" (vd export tổng hợp nhiều đơn vị theo kỳ) | **Một phần** (export submission/workbook có; export aggregated report tổng hợp chưa có) |
| 8 | Admin dashboard (thống kê, biểu đồ tổng quan) | FR-DB-01 | GET /dashboard/admin/stats; DashboardAdminStatsDto (submissionCountByStatus, byPeriod, byForm…); RLS; FE DashboardPage | **Đạt** |
| 9 | User dashboard (task list, deadline, notifications) | FR-DB-02 | GET /dashboard/user/tasks; DashboardUserTasksDto (Drafts, Revisions, UpcomingDeadlines, PendingApprovals); FE DashboardPage | **Đạt** |
| 10 | CRUD kỳ báo cáo | B10 | GET/POST/PUT/DELETE /reporting-periods; GET current?frequencyId=; 409 trùng PeriodCode; 400 xóa kỳ đã có submission | **Đạt** |
| 11 | FE ReportingPeriodsPage, DashboardPage | TONG_HOP | ReportingPeriodsPage (list, filter, CRUD kỳ); DashboardPage (admin stats, user tasks) | **Đạt** |

---

## 3. Gap

| Mức độ | Mô tả |
|--------|--------|
| **Minor** | **CK-02 Tự động tạo kỳ:** Tạo kỳ thủ công đầy đủ; chưa có scheduled job (Hangfire) tự tạo kỳ mới theo cron. Bảng BCDT_ScheduleJob có trong schema 07.reporting_period.sql nhưng service/job C# chưa triển khai. |
| **Minor** | **FR-TH-02 Drill-down:** Xem chi tiết qua submission/workbook-data có; nếu cần API riêng "drill từ summary xuống detail" (vd GET report-summary/{id}/details) có thể bổ sung sau. |
| **Minor** | **FR-TH-03 Export aggregated:** Export workbook/submission có; export "báo cáo tổng hợp" (nhiều đơn vị, một kỳ) dạng một file/endpoint chưa có. |

Không có gap **Critical** hoặc **Major** trong phạm vi B10 MVP (Reporting Period, Aggregation, Dashboard).

---

## 4. Mâu thuẫn / Rủi ro

- **Không phát hiện mâu thuẫn** giữa B10_REPORTING_PERIOD.md và code (API, DTO, service).
- **Rủi ro nhỏ:** Dashboard stats/tasks phụ thuộc RLS và session context; cần đảm bảo user/org đúng khi test.

---

## 5. Khuyến nghị

| Ưu tiên | Khuyến nghị |
|---------|-------------|
| **P2** | (Tùy chọn) Triển khai job tự động tạo kỳ (CK-02): Hangfire job đọc BCDT_ScheduleJob / ReportingFrequency.CronExpression, tạo BCDT_ReportingPeriod khi đến hạn (vd đầu tháng tạo kỳ tháng tiếp theo). |
| **P3** | Giữ checklist "Kiểm tra cho AI" B10 mục 7.1; khi sửa reporting/dashboard vẫn chạy đủ bước và báo Pass/Fail. |

**Kết luận:** Module Reporting & Dashboard (B10) **đạt đủ yêu cầu MVP** cho CK-01, CK-03, CK-04, FR-TH-01, FR-DB-01, FR-DB-02 và CRUD Reporting Period, Aggregation. Gap ở mức Minor (CK-02 auto-create, FR-TH-02/03 mở rộng); không ảnh hưởng nghiệm thu Phase 3.
