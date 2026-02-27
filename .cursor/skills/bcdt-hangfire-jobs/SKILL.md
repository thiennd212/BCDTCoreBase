---
name: bcdt-hangfire-jobs
description: Create Hangfire background jobs for BCDT (scheduling, reporting period, reminders, bulk import). Use when user says "Hangfire", "background job", "tạo kỳ báo cáo", "nhắc hạn nộp", "scheduling", or recurring job.
---

# BCDT Hangfire Jobs

Create background jobs using Hangfire (SQL Server storage). Dashboard: `/hangfire`.

## Workflow

1. **Identify job type**: Recurring (CRON), one-time (fire-and-forget), or delayed.
2. **Create job class** in Application or Infrastructure; inject services (IReportingPeriodService, INotificationService, etc.).
3. **Register** in `Program.cs`: `AddHangfire`, `UseHangfireDashboard`; schedule recurring in `RecurringJob.AddOrUpdate`.

---

## Job Examples

### 1. Create reporting periods (CK-02)

```csharp
// Recurring: daily 00:05
public class CreateReportingPeriodJob
{
    private readonly IReportingPeriodService _periodService;
    public CreateReportingPeriodJob(IReportingPeriodService periodService) => _periodService = periodService;

    public async Task ExecuteAsync()
    {
        await _periodService.CreatePeriodsForUpcomingAsync();
    }
}

// Registration
RecurringJob.AddOrUpdate<CreateReportingPeriodJob>("create-periods", j => j.ExecuteAsync(), "5 0 * * *");
```

### 2. Deadline reminder (WF-03, WF-04)

```csharp
public class DeadlineReminderJob
{
    private readonly INotificationService _notification;
    private readonly ISubmissionRepository _repo;

    public async Task ExecuteAsync()
    {
        var dueSoon = await _repo.GetSubmissionsDueInDaysAsync(2);
        foreach (var s in dueSoon)
            await _notification.SendDeadlineReminderAsync(s);
    }
}

RecurringJob.AddOrUpdate<DeadlineReminderJob>("deadline-reminder", j => j.ExecuteAsync(), "0 8 * * *");
```

### 3. Bulk import (queue processing)

```csharp
BackgroundJob.Enqueue<BulkImportProcessor>(p => p.ProcessAsync(submissionId));
```

---

## Conventions

- Job class: parameterless ctor; dependencies via DI; method `ExecuteAsync()` or `ProcessAsync(id)`.
- RecurringJob: unique job id, CRON expression, time zone if needed.
- Use `[AutomaticRetry(Attempts = 3)]` for transient failures.
- Don't put long-running logic in HTTP request; enqueue instead.

---

## Checklist

- [ ] Job registered in startup
- [ ] Connection string for Hangfire storage (SQL Server)
- [ ] Dashboard path configured (e.g. `/hangfire`), authorization if needed
- [ ] Recurring jobs idempotent where possible
