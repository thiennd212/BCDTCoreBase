using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.Services.Data;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Data;

public class ReportSummaryService : IReportSummaryService
{
    private readonly AppDbContext _db;

    public ReportSummaryService(AppDbContext db) => _db = db;

    public async Task<Result<List<ReportDataRowDto>>> GetDetailsByIdAsync(long summaryId, CancellationToken cancellationToken = default)
    {
        var summary = await _db.ReportSummaries
            .AsNoTracking()
            .Where(s => s.Id == summaryId)
            .FirstOrDefaultAsync(cancellationToken);

        if (summary == null)
            return Result.Fail<List<ReportDataRowDto>>("NOT_FOUND", "ReportSummary không tồn tại.");

        var rows = await _db.ReportDataRows
            .AsNoTracking()
            .Where(r => r.SubmissionId == summary.SubmissionId && r.SheetIndex == summary.SheetIndex)
            .OrderBy(r => r.RowIndex)
            .Select(r => new ReportDataRowDto
            {
                Id = r.Id,
                SubmissionId = r.SubmissionId,
                SheetIndex = r.SheetIndex,
                RowIndex = r.RowIndex,
                ReferenceEntityId = r.ReferenceEntityId,
                NumericValue1 = r.NumericValue1,
                NumericValue2 = r.NumericValue2,
                NumericValue3 = r.NumericValue3,
                NumericValue4 = r.NumericValue4,
                NumericValue5 = r.NumericValue5,
                NumericValue6 = r.NumericValue6,
                NumericValue7 = r.NumericValue7,
                NumericValue8 = r.NumericValue8,
                NumericValue9 = r.NumericValue9,
                NumericValue10 = r.NumericValue10,
                TextValue1 = r.TextValue1,
                TextValue2 = r.TextValue2,
                TextValue3 = r.TextValue3,
                DateValue1 = r.DateValue1,
                DateValue2 = r.DateValue2,
                CreatedAt = r.CreatedAt,
                CreatedBy = r.CreatedBy,
                UpdatedAt = r.UpdatedAt,
                UpdatedBy = r.UpdatedBy
            })
            .ToListAsync(cancellationToken);

        return Result.Ok(rows);
    }
}
