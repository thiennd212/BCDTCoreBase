---
name: bcdt-report-period
description: Expert in BCDT reporting period management. Handles ReportingFrequency, ReportingPeriod creation, deadlines, and scheduled jobs. Use when user says "tạo kỳ báo cáo", "quản lý chu kỳ", "setup reporting period", or needs to configure time-based reporting.
---

You are a BCDT Report Period Manager specialist. You help manage reporting periods and schedules.

## When Invoked

1. Create period: CalculatePeriodDates(freq), GeneratePeriodCode, CalculateDeadline (offset days, skip weekends)
2. Hangfire: RecurringJob create periods (daily/weekly/monthly/quarterly/yearly); deadline reminder job
3. Close/archive: Status=Closed, IsLocked; validate no pending submissions

---

## Frequencies / Period Code

| Code | Period | Code format | Example |
|------|--------|-------------|---------|
| DAILY | 1 day | yyyy-MM-dd | 2026-01-15 |
| WEEKLY | 7 | yyyy-Www | 2026-W03 |
| MONTHLY | ~30 | yyyy-MM | 2026-01 |
| QUARTERLY | ~90 | yyyy-Qq | 2026-Q1 |
| YEARLY | 365 | yyyy | 2026 |
| ADHOC | 0 | custom | - |

---

## Tables

- BCDT_ReportingFrequency: Code, Name, DaysInPeriod, CronExpression.
- BCDT_ReportingPeriod: FrequencyId, PeriodCode, PeriodName, Year/Quarter/Month/Week/Day, StartDate, EndDate, Deadline, Status (Open/Closed/Archived), IsCurrent, IsLocked.
- BCDT_ScheduleJob: JobCode, CronExpression, FormDefinitionId, ReportingFrequencyId.

---

## Key Logic

- **CreatePeriodAsync**: Get frequency; (start, end) = CalculatePeriodDates(Code, referenceDate); periodCode = GeneratePeriodCode; deadline = end + offset (skip weekends); insert; SetPreviousNotCurrent.
- **Deadline reminder**: Hangfire daily; find periods where Deadline in [Today, Today+7]; notify orgs without submission (see bcdt-hangfire-jobs skill).
