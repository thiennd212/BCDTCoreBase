using System.Data;
using System.Globalization;
using BCDT.Domain.Entities.ReportingPeriod;
using BCDT.Infrastructure.Persistence;
using Hangfire;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Logging;
using ReportingPeriodEntity = BCDT.Domain.Entities.ReportingPeriod.ReportingPeriod;

namespace BCDT.Infrastructure.Jobs;

/// <summary>
/// CK-02: Job tự động tạo kỳ báo cáo mới theo chu kỳ (DAILY/WEEKLY/MONTHLY/QUARTERLY/YEARLY).
/// Chạy hàng ngày lúc 1:00 AM UTC. Với mỗi ReportingFrequency active (không phải ADHOC),
/// kiểm tra xem kỳ hiện tại đã tồn tại chưa – nếu chưa thì tạo mới và đặt IsCurrent=true.
/// </summary>
[AutomaticRetry(Attempts = 2, OnAttemptsExceeded = AttemptsExceededAction.Fail)]
public class AutoCreateReportingPeriodJob
{
    private readonly AppDbContext _db;
    private readonly ILogger<AutoCreateReportingPeriodJob> _logger;

    public AutoCreateReportingPeriodJob(AppDbContext db, ILogger<AutoCreateReportingPeriodJob> logger)
    {
        _db = db;
        _logger = logger;
    }

    public async Task ExecuteAsync(CancellationToken cancellationToken = default)
    {
        var connection = _db.Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
            await connection.OpenAsync(cancellationToken);

        try
        {
            await SetSystemContextAsync(connection, cancellationToken);

            var today = DateTime.UtcNow.Date;
            var frequencies = await _db.ReportingFrequencies
                .AsNoTracking()
                .Where(f => f.IsActive && f.Code != "ADHOC")
                .OrderBy(f => f.DisplayOrder)
                .ToListAsync(cancellationToken);

            foreach (var freq in frequencies)
            {
                try
                {
                    await ProcessFrequencyAsync(freq, today, cancellationToken);
                }
                catch (Exception ex)
                {
                    _logger.LogError(ex, "AutoCreateReportingPeriodJob: lỗi khi xử lý tần suất {FreqCode} (Id={FreqId})", freq.Code, freq.Id);
                }
            }
        }
        finally
        {
            try { await ClearUserContextAsync(connection, cancellationToken); } catch { /* best effort */ }
        }
    }

    private async Task ProcessFrequencyAsync(ReportingFrequency freq, DateTime today, CancellationToken ct)
    {
        var (periodCode, periodName, startDate, endDate, year, quarter, month, week, day) =
            ComputePeriod(freq.Code, today);

        var exists = await _db.ReportingPeriods.AnyAsync(
            p => p.ReportingFrequencyId == freq.Id && p.PeriodCode == periodCode, ct);

        if (exists)
        {
            _logger.LogDebug("AutoCreateReportingPeriodJob: kỳ {PeriodCode} ({FreqCode}) đã tồn tại – bỏ qua.", periodCode, freq.Code);
            return;
        }

        // Unset IsCurrent cũ
        await _db.ReportingPeriods
            .Where(p => p.ReportingFrequencyId == freq.Id && p.IsCurrent)
            .ExecuteUpdateAsync(s => s.SetProperty(p => p.IsCurrent, false), ct);

        var deadline = endDate.AddDays(GetDeadlineOffsetDays(freq.Code));

        var newPeriod = new ReportingPeriodEntity
        {
            ReportingFrequencyId = freq.Id,
            PeriodCode = periodCode,
            PeriodName = periodName,
            Year = year,
            Quarter = quarter,
            Month = month,
            Week = week,
            Day = day,
            StartDate = startDate,
            EndDate = endDate,
            Deadline = deadline,
            Status = "Open",
            IsCurrent = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 0 // system
        };

        _db.ReportingPeriods.Add(newPeriod);
        await _db.SaveChangesAsync(ct);

        _logger.LogInformation(
            "AutoCreateReportingPeriodJob: đã tạo kỳ {PeriodCode} ({FreqCode}), Id={Id}, Deadline={Deadline:yyyy-MM-dd}",
            periodCode, freq.Code, newPeriod.Id, deadline);
    }

    /// <summary>Tính thông tin kỳ báo cáo dựa trên tần suất và ngày hôm nay.</summary>
    private static (string periodCode, string periodName, DateTime startDate, DateTime endDate,
        int year, byte? quarter, byte? month, byte? week, byte? day)
        ComputePeriod(string freqCode, DateTime today)
    {
        return freqCode switch
        {
            "DAILY" => (
                today.ToString("yyyy-MM-dd"),
                $"Ngày {today:dd/MM/yyyy}",
                today, today,
                today.Year, null, (byte)today.Month, null, (byte)today.Day
            ),
            "WEEKLY" => ComputeWeekPeriod(today),
            "MONTHLY" => ComputeMonthPeriod(today),
            "QUARTERLY" => ComputeQuarterPeriod(today),
            "YEARLY" => (
                today.Year.ToString(),
                $"Năm {today.Year}",
                new DateTime(today.Year, 1, 1),
                new DateTime(today.Year, 12, 31),
                today.Year, null, null, null, null
            ),
            _ => throw new InvalidOperationException($"Không hỗ trợ tần suất: {freqCode}")
        };
    }

    private static (string, string, DateTime, DateTime, int, byte?, byte?, byte?, byte?) ComputeMonthPeriod(DateTime today)
    {
        var start = new DateTime(today.Year, today.Month, 1);
        var end = start.AddMonths(1).AddDays(-1);
        return (
            today.ToString("yyyy-MM"),
            $"Tháng {today.Month:00}/{today.Year}",
            start, end,
            today.Year, null, (byte)today.Month, null, null
        );
    }

    private static (string, string, DateTime, DateTime, int, byte?, byte?, byte?, byte?) ComputeQuarterPeriod(DateTime today)
    {
        var q = (byte)((today.Month - 1) / 3 + 1);
        var startMonth = (q - 1) * 3 + 1;
        var start = new DateTime(today.Year, startMonth, 1);
        var end = start.AddMonths(3).AddDays(-1);
        return (
            $"{today.Year}-Q{q}",
            $"Quý {q}/{today.Year}",
            start, end,
            today.Year, q, null, null, null
        );
    }

    private static (string, string, DateTime, DateTime, int, byte?, byte?, byte?, byte?) ComputeWeekPeriod(DateTime today)
    {
        var cal = CultureInfo.InvariantCulture.Calendar;
        var weekNum = (byte)cal.GetWeekOfYear(today, CalendarWeekRule.FirstFourDayWeek, DayOfWeek.Monday);
        // Đầu tuần (Monday)
        var dayOfWeek = (int)today.DayOfWeek;
        var daysToMonday = dayOfWeek == 0 ? 6 : dayOfWeek - 1;
        var start = today.AddDays(-daysToMonday);
        var end = start.AddDays(6);
        return (
            $"{today.Year}-W{weekNum:00}",
            $"Tuần {weekNum} năm {today.Year}",
            start, end,
            today.Year, null, null, weekNum, null
        );
    }

    /// <summary>Số ngày gia hạn nộp sau EndDate theo tần suất.</summary>
    private static int GetDeadlineOffsetDays(string freqCode) => freqCode switch
    {
        "DAILY" => 1,
        "WEEKLY" => 3,
        "MONTHLY" => 10,
        "QUARTERLY" => 15,
        "YEARLY" => 30,
        _ => 10
    };

    private static async Task SetSystemContextAsync(System.Data.Common.DbConnection conn, CancellationToken ct)
    {
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = "EXEC sp_SetSystemContext";
        await cmd.ExecuteNonQueryAsync(ct);
    }

    private static async Task ClearUserContextAsync(System.Data.Common.DbConnection conn, CancellationToken ct)
    {
        await using var cmd = conn.CreateCommand();
        cmd.CommandText = "EXEC sp_ClearUserContext";
        await cmd.ExecuteNonQueryAsync(ct);
    }
}
