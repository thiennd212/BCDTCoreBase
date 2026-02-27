using System.Data;
using BCDT.Application.Services.Data;
using BCDT.Infrastructure.Persistence;
using Hangfire;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Jobs;

/// <summary>Perf-13: Job nền tính tổng hợp (aggregate) cho submission. Prod-8 (R2): Gọi sp_SetSystemContext trước khi dùng DbContext (RLS).</summary>
[AutomaticRetry(Attempts = 2, OnAttemptsExceeded = AttemptsExceededAction.Fail)]
public class AggregateSubmissionJob
{
    private readonly IAggregationService _aggregationService;
    private readonly AppDbContext _db;

    public AggregateSubmissionJob(IAggregationService aggregationService, AppDbContext db)
    {
        _aggregationService = aggregationService;
        _db = db;
    }

    public async Task ExecuteAsync(long submissionId, CancellationToken cancellationToken = default)
    {
        var connection = _db.Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
            await connection.OpenAsync(cancellationToken);

        try
        {
            await SetSystemContextOnConnection(connection, cancellationToken);
            await _aggregationService.AggregateSubmissionAsync(submissionId, cancellationToken);
        }
        finally
        {
            try
            {
                await ClearUserContextOnConnection(connection, cancellationToken);
            }
            catch
            {
                // Best effort clear
            }
        }
    }

    private static async Task SetSystemContextOnConnection(System.Data.Common.DbConnection connection, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "EXEC sp_SetSystemContext";
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task ClearUserContextOnConnection(System.Data.Common.DbConnection connection, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "EXEC sp_ClearUserContext";
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }
}
