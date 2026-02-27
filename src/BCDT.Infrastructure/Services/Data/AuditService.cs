using BCDT.Application.Common;
using BCDT.Application.Services.Data;
using BCDT.Domain.Entities.Data;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Data;

public class AuditService : IAuditService
{
    private readonly AppDbContext _db;

    public AuditService(AppDbContext db) => _db = db;

    public async Task<Result<object>> LogCellChangeAsync(
        long submissionId, long? dataRowId, byte sheetIndex, string cellAddress,
        string? columnName, string? oldValue, string? newValue, string changeType,
        int changedBy, string? ipAddress, string? userAgent, CancellationToken cancellationToken)
    {
        var audit = new ReportDataAudit
        {
            SubmissionId = submissionId,
            DataRowId = dataRowId,
            SheetIndex = sheetIndex,
            CellAddress = cellAddress,
            ColumnName = columnName,
            OldValue = oldValue,
            NewValue = newValue,
            ChangeType = changeType,
            ChangedAt = DateTime.UtcNow,
            ChangedBy = changedBy,
            IpAddress = ipAddress,
            UserAgent = userAgent
        };
        _db.ReportDataAudits.Add(audit);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { id = audit.Id });
    }

    public async Task<Result<int>> LogBatchCellChangesAsync(
        long submissionId, byte sheetIndex, IEnumerable<CellChangeEntry> changes,
        int changedBy, string? ipAddress, string? userAgent, CancellationToken cancellationToken)
    {
        var now = DateTime.UtcNow;
        var audits = changes.Select(c => new ReportDataAudit
        {
            SubmissionId = submissionId,
            DataRowId = c.DataRowId,
            SheetIndex = sheetIndex,
            CellAddress = c.CellAddress,
            ColumnName = c.ColumnName,
            OldValue = c.OldValue,
            NewValue = c.NewValue,
            ChangeType = c.ChangeType,
            ChangedAt = now,
            ChangedBy = changedBy,
            IpAddress = ipAddress,
            UserAgent = userAgent
        }).ToList();

        _db.ReportDataAudits.AddRange(audits);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(audits.Count);
    }

    public async Task<Result<List<AuditEntryDto>>> GetAuditHistoryAsync(long submissionId, CancellationToken cancellationToken)
    {
        var audits = await _db.ReportDataAudits
            .AsNoTracking()
            .Where(a => a.SubmissionId == submissionId)
            .OrderByDescending(a => a.ChangedAt)
            .Select(a => new AuditEntryDto
            {
                Id = a.Id,
                SubmissionId = a.SubmissionId,
                DataRowId = a.DataRowId,
                SheetIndex = a.SheetIndex,
                CellAddress = a.CellAddress,
                ColumnName = a.ColumnName,
                OldValue = a.OldValue,
                NewValue = a.NewValue,
                ChangeType = a.ChangeType,
                ChangedAt = a.ChangedAt,
                ChangedBy = a.ChangedBy
            })
            .Take(500)
            .ToListAsync(cancellationToken);
        return Result.Ok(audits);
    }
}
