using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.Services.Data;
using BCDT.Domain.Entities.Data;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class SubmissionDynamicIndicatorService : ISubmissionDynamicIndicatorService
{
    private readonly AppDbContext _db;

    public SubmissionDynamicIndicatorService(AppDbContext db) => _db = db;

    public async Task<Result<List<ReportDynamicIndicatorItemDto>>> GetBySubmissionIdAsync(long submissionId, CancellationToken cancellationToken = default)
    {
        var submissionExists = await _db.ReportSubmissions.AnyAsync(s => s.Id == submissionId && !s.IsDeleted, cancellationToken);
        if (!submissionExists)
            return Result.Fail<List<ReportDynamicIndicatorItemDto>>("NOT_FOUND", "Submission không tồn tại.");

        var list = await _db.ReportDynamicIndicators
            .AsNoTracking()
            .Where(d => d.SubmissionId == submissionId)
            .OrderBy(d => d.FormDynamicRegionId).ThenBy(d => d.RowOrder)
            .Select(d => new ReportDynamicIndicatorItemDto
            {
                Id = d.Id,
                FormDynamicRegionId = d.FormDynamicRegionId,
                RowOrder = d.RowOrder,
                IndicatorId = d.IndicatorId,
                IndicatorName = d.IndicatorName,
                IndicatorValue = d.IndicatorValue,
                DataType = d.DataType
            })
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<object>> PutAsync(long submissionId, PutDynamicIndicatorsRequest request, int userId, CancellationToken cancellationToken = default)
    {
        var submission = await _db.ReportSubmissions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == submissionId && !s.IsDeleted, cancellationToken);
        if (submission == null)
            return Result.Fail<object>("NOT_FOUND", "Submission không tồn tại.");

        var regionIds = request.Items.Select(x => x.FormDynamicRegionId).Distinct().ToList();
        if (regionIds.Count == 0)
        {
            await using var emptyTx = await _db.Database.BeginTransactionAsync(cancellationToken);
            try
            {
                await _db.ReportDynamicIndicators.Where(d => d.SubmissionId == submissionId).ExecuteDeleteAsync(cancellationToken);
                await emptyTx.CommitAsync(cancellationToken);
            }
            catch
            {
                await emptyTx.RollbackAsync(cancellationToken);
                throw;
            }
            return Result.Ok<object>(new { });
        }

        var validRegionIds = await _db.FormDynamicRegions
            .Where(r => regionIds.Contains(r.Id))
            .Join(_db.FormSheets, r => r.FormSheetId, s => s.Id, (r, s) => new { r.Id, s.FormDefinitionId })
            .Where(x => x.FormDefinitionId == submission.FormDefinitionId)
            .Select(x => x.Id)
            .ToListAsync(cancellationToken);

        var invalidIds = regionIds.Except(validRegionIds).ToList();
        if (invalidIds.Count > 0)
            return Result.Fail<object>("VALIDATION_FAILED", $"FormDynamicRegionId không thuộc form của submission: {string.Join(", ", invalidIds)}.");

        foreach (var regionId in validRegionIds)
        {
            var region = await _db.FormDynamicRegions.FirstAsync(r => r.Id == regionId, cancellationToken);
            var count = request.Items.Count(i => i.FormDynamicRegionId == regionId);
            if (count > region.MaxRows)
                return Result.Fail<object>("VALIDATION_FAILED", $"Vùng {regionId} vượt quá MaxRows ({region.MaxRows}).");
        }

        await using var tx = await _db.Database.BeginTransactionAsync(cancellationToken);
        try
        {
            await _db.ReportDynamicIndicators
                .Where(d => d.SubmissionId == submissionId && regionIds.Contains(d.FormDynamicRegionId))
                .ExecuteDeleteAsync(cancellationToken);

            var order = 0;
            foreach (var item in request.Items.OrderBy(i => i.FormDynamicRegionId).ThenBy(i => i.RowOrder))
            {
                if (!validRegionIds.Contains(item.FormDynamicRegionId))
                    continue;
                _db.ReportDynamicIndicators.Add(new ReportDynamicIndicator
                {
                    SubmissionId = submissionId,
                    FormDynamicRegionId = item.FormDynamicRegionId,
                    RowOrder = item.RowOrder,
                    IndicatorId = item.IndicatorId,
                    IndicatorName = item.IndicatorName ?? string.Empty,
                    IndicatorValue = item.IndicatorValue,
                    DataType = item.DataType,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = userId
                });
                order++;
            }
            await _db.SaveChangesAsync(cancellationToken);
            await tx.CommitAsync(cancellationToken);
        }
        catch
        {
            await tx.RollbackAsync(cancellationToken);
            throw;
        }

        return Result.Ok<object>(new { });
    }
}
