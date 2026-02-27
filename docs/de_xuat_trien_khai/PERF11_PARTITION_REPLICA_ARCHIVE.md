# Perf-11 – Partition-ready, Read replica–ready, Archive policy

**Mục đích:** Thiết kế sẵn cho partition, read replica và archive theo [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](../DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md) mục 0.3. Triển khai **tài liệu và script mẫu/cấu hình**; khi hạ tầng sẵn sàng chỉ cần bật config hoặc chạy script (không refactor lớn).

**Tham chiếu:** DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md (0.3), W16_PERFORMANCE_SECURITY.md, RUNBOOK.md, 05.data_storage.sql.

---

## 1. Partition-ready

### 1.1. Bảng cần partition (khi dữ liệu lớn)

| Bảng | Partition key đề xuất | Lý do |
|------|------------------------|--------|
| **BCDT_ReportSubmission** | `ReportingPeriodId` hoặc năm (từ ReportingPeriod) | Truy vấn thường lọc theo kỳ; list submission theo org + period. |
| **BCDT_ReportDataRow** | Cùng partition key với Submission (qua `SubmissionId` → ReportingPeriodId) | Lượng dòng lớn theo thời gian; cần thêm cột `ReportingPeriodId` (redundant) để partition trực tiếp. |
| **BCDT_ReportPresentation** | Tương tự (qua Submission) | JSON lớn; tách theo kỳ giảm kích thước từng partition. |

### 1.2. Chiến lược partition

- **Partition function:** RANGE RIGHT theo `ReportingPeriodId` (hoặc theo năm: 2024, 2025, 2026...) để mỗi partition chứa một kỳ hoặc một năm.
- **Index:** Mọi query lọc theo `ReportingPeriodId` (hoặc SubmissionId + join Submission) để tận dụng partition elimination; tránh full table scan.
- **Schema hiện tại:** `BCDT_ReportDataRow` và `BCDT_ReportPresentation` chưa có cột `ReportingPeriodId`. Khi triển khai partition:
  1. (Tùy chọn) Thêm cột `ReportingPeriodId` vào hai bảng (đồng bộ từ BCDT_ReportSubmission), backfill, rồi dùng làm partition key.
  2. Hoặc partition chỉ bảng **BCDT_ReportSubmission** theo `ReportingPeriodId`; các bảng con (DataRow, Presentation) giữ nguyên hoặc chuyển sang filegroup theo partition scheme (phức tạp hơn).

### 1.3. Script mẫu

Script **mẫu** (không chạy trực tiếp lên production): [../script_core/sql/v2/27.perf11_partition_sample.sql](../script_core/sql/v2/27.perf11_partition_sample.sql).

- Tạo partition function + scheme mẫu (theo năm hoặc ReportingPeriodId).
- Ghi chú điều kiện chạy (maintenance window, backup, test trước).
- Query tránh full scan: luôn có điều kiện `ReportingPeriodId = @p` (hoặc `IN (list)`) trong WHERE.

### 1.4. Query tránh scan toàn bảng

- List submission: `WHERE OrganizationId = @oid AND ReportingPeriodId = @pid [AND Status = @status]` → dùng index, partition elimination.
- ReportDataRow: khi có `ReportingPeriodId` trên bảng, `WHERE ReportingPeriodId = @pid AND SubmissionId = @sid` → partition + index.
- Aggregate/dashboard: filter theo period → optimizer loại bỏ partition không liên quan.

---

## 2. Read replica–ready

### 2.1. Tách read vs write trong code

| Loại | Ví dụ API / service | Ghi chú |
|------|----------------------|--------|
| **Chỉ đọc** | GET /dashboard/admin/stats, GET /dashboard/user/tasks, GET /submissions (list), GET /forms (list), GET /submissions/{id}/workbook-data (đọc), GET /reporting-periods, aggregate, báo cáo | Có thể dùng connection read replica khi cấu hình. |
| **Ghi** | POST/PUT/DELETE submission, PUT presentation, sync-from-presentation, submit, approve/reject/revision, workflow, CUD form/org/user | Luôn dùng connection chính (primary). |

### 2.2. Cấu hình connection khi bật replica

Khi hạ tầng có read replica (vd. SQL Server Always On, read-only secondary):

- **appsettings:** Thêm connection string read, ví dụ:
  - `ConnectionStrings:DefaultConnection` – primary (read/write).
  - `ConnectionStrings:ReadReplica` – secondary (chỉ đọc); khi không có replica thì để trống hoặc trùng DefaultConnection.

- **Code pattern (khi triển khai):**
  - Đăng ký hai DbContext (hoặc một DbContext với hai connection): một cho write (default), một cho read (dùng khi gọi service chỉ đọc).
  - Service read-only (vd. DashboardService.GetAdminStats, SubmissionsService.GetList, BuildWorkbookFromSubmissionService khi chỉ đọc) inject `IReadOnlyDbContext` hoặc connection "ReadReplica" và dùng connection đó.
  - Khi `ReadReplica` không cấu hình → fallback DefaultConnection (không lỗi).

### 2.3. Ví dụ appsettings (mẫu)

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=.;Database=BCDT;...",
    "ReadReplica": ""
  },
  "UseReadReplica": false
}
```

Khi bật replica: đặt `ReadReplica` = connection string secondary, `UseReadReplica` = true (hoặc chỉ cần có ReadReplica khác rỗng). Ứng dụng hiện tại chưa bắt buộc đọc config này; khi triển khai chỉ cần thêm đăng ký DbContext đọc và dùng trong service chỉ đọc.

### 2.4. Tài liệu hướng dẫn

- RUNBOOK hoặc file ops: "Khi cấu hình read replica SQL Server, cập nhật appsettings với ConnectionStrings:ReadReplica và bật UseReadReplica; không đổi code nghiệp vụ."
- Code: tách rõ trong comment hoặc interface (vd. IAppDbContext vs IAppReadOnlyDbContext) để sau này inject connection đọc dễ dàng.

---

## 3. Archive policy

### 3.1. Định nghĩa policy

- **Điều kiện archive:** Submission có `Status = 'Approved'` và kỳ báo cáo đã kết thúc quá **RetentionYears** năm (so với `ReportingPeriod.EndDate` hoặc `ApprovedAt`).
- **Hành động:** Chuyển dữ liệu (ReportSubmission, ReportPresentation, ReportDataRow, ReportSummary, ReportDataAudit) sang bảng archive hoặc DB archive; sau đó xóa hoặc đánh dấu đã archive ở bảng gốc. Triển khai bằng Hangfire job + script SQL.

### 3.2. Config mẫu

Thêm vào appsettings (hoặc section riêng):

```json
{
  "ArchivePolicy": {
    "ArchiveEnabled": false,
    "RetentionYears": 2,
    "BatchSize": 500
  }
}
```

- **ArchiveEnabled:** Bật/tắt job archive (mặc định false).
- **RetentionYears:** Số năm giữ submission Approved sau khi kỳ kết thúc (vd. 2 = archive khi EndDate &lt; Today - 2 năm).
- **BatchSize:** Số submission xử lý mỗi lần chạy job (tránh lock lâu).

### 3.3. Cách triển khai khi bật archive

1. Tạo bảng archive (cùng schema hoặc schema rút gọn): vd. `BCDT_ReportSubmission_Archive`, `BCDT_ReportPresentation_Archive`, …
2. Hangfire job định kỳ (vd. hàng tháng): lấy danh sách submission đủ điều kiện (Approved + ReportingPeriod.EndDate &lt; Today - RetentionYears); với mỗi batch: INSERT INTO …_Archive SELECT … FROM …; sau đó DELETE hoặc soft-delete bản ghi gốc.
3. Đảm bảo RLS và quyền truy cập archive (chỉ đọc, phục vụ tra cứu lịch sử).

Tài liệu này chỉ định nghĩa policy và config; không triển khai job/script thực thi ngay.

### 3.4. Triển khai Perf-18 – Archive (script mẫu)

Khi bật archive theo policy (ArchivePolicy.ArchiveEnabled = true):

1. **Chạy script tạo bảng archive:** [../script_core/sql/v2/28.perf18_archive_sample.sql](../script_core/sql/v2/28.perf18_archive_sample.sql) – tạo các bảng `BCDT_ReportSubmission_Archive`, `BCDT_ReportPresentation_Archive`, `BCDT_ReportDataRow_Archive`, `BCDT_ReportSummary_Archive`, `BCDT_ReportDataAudit_Archive` và stored procedure mẫu `sp_BCDT_ArchiveSubmissions_Batch`.
2. **Tham số proc:** `@RetentionYears` (khớp config ArchivePolicy.RetentionYears), `@BatchSize` (khớp ArchivePolicy.BatchSize). Điều kiện archive: submission `Status = 'Approved'` và `ReportingPeriod.EndDate < GETDATE() - @RetentionYears`.
3. **Gọi archive:** Hangfire job định kỳ (vd. hàng tháng) gọi `EXEC sp_BCDT_ArchiveSubmissions_Batch @RetentionYears = 2, @BatchSize = 500` hoặc từ C# (ExecuteSqlRaw) đọc config và gọi proc. Chạy script/proc **chỉ trong maintenance window** sau khi backup; không chạy trực tiếp lên production mà chưa duyệt.

---

## 4. Kiểm tra cho AI (Perf-11)

Xem [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](../DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md) mục **5.11**.

---

## 5. Tham chiếu

- [DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md](../DE_XUAT_TOI_UU_HIEU_NANG_VA_MO_RONG.md) mục 0.3, 3.2.3
- [05.data_storage.sql](../script_core/sql/v2/05.data_storage.sql)
- [27.perf11_partition_sample.sql](../script_core/sql/v2/27.perf11_partition_sample.sql)
- [28.perf18_archive_sample.sql](../script_core/sql/v2/28.perf18_archive_sample.sql) – Perf-18 archive
- [W16_PERFORMANCE_SECURITY.md](W16_PERFORMANCE_SECURITY.md)
