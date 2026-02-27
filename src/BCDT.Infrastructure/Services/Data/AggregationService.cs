using BCDT.Application.Common;
using BCDT.Application.Services.Data;
using BCDT.Domain.Entities.Data;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Data;

public class AggregationService : IAggregationService
{
    private readonly AppDbContext _db;

    public AggregationService(AppDbContext db) => _db = db;

    public async Task<Result<object>> AggregateSubmissionAsync(long submissionId, CancellationToken cancellationToken = default)
    {
        var submissionExists = await _db.ReportSubmissions.AnyAsync(x => x.Id == submissionId, cancellationToken);
        if (!submissionExists)
            return Result.Fail<object>("NOT_FOUND", "Submission không tồn tại.");

        var rows = await _db.ReportDataRows
            .AsNoTracking()
            .Where(x => x.SubmissionId == submissionId)
            .ToListAsync(cancellationToken);

        var bySheet = rows.GroupBy(x => x.SheetIndex).ToList();
        var now = DateTime.UtcNow;

        foreach (var group in bySheet)
        {
            var sheetIndex = group.Key;
            var list = group.ToList();
            var summary = await _db.ReportSummaries.FirstOrDefaultAsync(
                x => x.SubmissionId == submissionId && x.SheetIndex == sheetIndex, cancellationToken);

            decimal? Sum(int i)
            {
                return list.Sum(r => i switch
                {
                    1 => r.NumericValue1,
                    2 => r.NumericValue2,
                    3 => r.NumericValue3,
                    4 => r.NumericValue4,
                    5 => r.NumericValue5,
                    6 => r.NumericValue6,
                    7 => r.NumericValue7,
                    8 => r.NumericValue8,
                    9 => r.NumericValue9,
                    10 => r.NumericValue10,
                    _ => null
                });
            }

            if (summary == null)
            {
                summary = new ReportSummary
                {
                    SubmissionId = submissionId,
                    SheetIndex = sheetIndex,
                    TotalValue1 = Sum(1),
                    TotalValue2 = Sum(2),
                    TotalValue3 = Sum(3),
                    TotalValue4 = Sum(4),
                    TotalValue5 = Sum(5),
                    TotalValue6 = Sum(6),
                    TotalValue7 = Sum(7),
                    TotalValue8 = Sum(8),
                    TotalValue9 = Sum(9),
                    TotalValue10 = Sum(10),
                    RowCount = list.Count,
                    DataRowCount = list.Count,
                    CalculatedAt = now
                };
                _db.ReportSummaries.Add(summary);
            }
            else
            {
                summary.TotalValue1 = Sum(1);
                summary.TotalValue2 = Sum(2);
                summary.TotalValue3 = Sum(3);
                summary.TotalValue4 = Sum(4);
                summary.TotalValue5 = Sum(5);
                summary.TotalValue6 = Sum(6);
                summary.TotalValue7 = Sum(7);
                summary.TotalValue8 = Sum(8);
                summary.TotalValue9 = Sum(9);
                summary.TotalValue10 = Sum(10);
                summary.RowCount = list.Count;
                summary.DataRowCount = list.Count;
                summary.CalculatedAt = now;
            }
        }

        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { submissionId, sheetsProcessed = bySheet.Count, calculatedAt = now });
    }
}
