# Task CK-02 – Hangfire job tự động tạo kỳ báo cáo

**Ngày:** 2026-02-27
**Kết quả:** ✅ DONE – Build Pass
**Size:** MEDIUM (2 files: Job + Program.cs)

## Việc đã làm

Tạo `src/BCDT.Infrastructure/Jobs/AutoCreateReportingPeriodJob.cs`:

- `[AutomaticRetry(Attempts=2)]`
- Cron: `"0 1 * * *"` (daily 1AM UTC)
- Gọi `sp_SetSystemContext` + `sp_ClearUserContext` (pattern từ AggregateSubmissionJob)
- Xử lý tất cả active frequencies (trừ ADHOC):
  - Tính period hiện tại theo `ComputePeriod(freqCode, today)`
  - Skip nếu đã tồn tại (idempotent)
  - Unset IsCurrent cũ
  - Tạo kỳ mới với deadline = ValidTo + offsetDays

## Period computation

| FreqCode | Format | Logic |
|---|---|---|
| DAILY | `yyyy-MM-dd` | today |
| WEEKLY | `yyyy-Wnn` | ISO week number |
| MONTHLY | `yyyy-MM` | tháng hiện tại |
| QUARTERLY | `yyyy-Qn` | quý = (month-1)/3 + 1 |
| YEARLY | `yyyy` | năm hiện tại |

## Deadline offsets

DAILY=1, WEEKLY=3, MONTHLY=10, QUARTERLY=15, YEARLY=30 ngày sau ValidTo.

## Đăng ký trong Program.cs

```csharp
recurringJobs.AddOrUpdate<AutoCreateReportingPeriodJob>(
    "auto-create-reporting-period",
    job => job.ExecuteAsync(CancellationToken.None),
    "0 1 * * *",
    new RecurringJobOptions { TimeZone = TimeZoneInfo.Utc });
```
