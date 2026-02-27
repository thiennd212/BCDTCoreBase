using BCDT.Application.Common;
using BCDT.Application.DTOs.ReportingPeriod;
using BCDT.Application.Services.ReportingPeriod;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using ReportingPeriodEntity = BCDT.Domain.Entities.ReportingPeriod.ReportingPeriod;

namespace BCDT.Infrastructure.Services.ReportingPeriod;

public class ReportingPeriodService : IReportingPeriodService
{
    private readonly AppDbContext _db;

    public ReportingPeriodService(AppDbContext db) => _db = db;

    public async Task<Result<List<ReportingPeriodDto>>> GetListAsync(int? frequencyId, int? year, string? status, bool? isCurrent, CancellationToken cancellationToken = default)
    {
        IQueryable<ReportingPeriodEntity> query = _db.ReportingPeriods
            .AsNoTracking()
            .Include(x => x.ReportingFrequency);
        if (frequencyId.HasValue)
            query = query.Where(x => x.ReportingFrequencyId == frequencyId.Value);
        if (year.HasValue)
            query = query.Where(x => x.Year == year.Value);
        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(x => x.Status == status);
        if (isCurrent.HasValue)
            query = query.Where(x => x.IsCurrent == isCurrent.Value);
        var list = await query.OrderByDescending(x => x.Year).ThenBy(x => x.Month).ThenBy(x => x.PeriodCode)
            .Select(x => new ReportingPeriodDto
            {
                Id = x.Id,
                ReportingFrequencyId = x.ReportingFrequencyId,
                ReportingFrequencyCode = x.ReportingFrequency!.Code,
                ReportingFrequencyName = x.ReportingFrequency.Name,
                PeriodCode = x.PeriodCode,
                PeriodName = x.PeriodName,
                Year = x.Year,
                Quarter = x.Quarter,
                Month = x.Month,
                Week = x.Week,
                Day = x.Day,
                StartDate = x.StartDate,
                EndDate = x.EndDate,
                Deadline = x.Deadline,
                Status = x.Status,
                IsCurrent = x.IsCurrent,
                IsLocked = x.IsLocked,
                LockedAt = x.LockedAt,
                LockedBy = x.LockedBy,
                CreatedAt = x.CreatedAt,
                CreatedBy = x.CreatedBy
            }).ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<ReportingPeriodDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportingPeriods.AsNoTracking()
            .Include(x => x.ReportingFrequency)
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        return Result.Ok<ReportingPeriodDto?>(entity == null ? null : MapToDto(entity));
    }

    public async Task<Result<ReportingPeriodDto?>> GetCurrentAsync(int? frequencyId, CancellationToken cancellationToken = default)
    {
        IQueryable<ReportingPeriodEntity> query = _db.ReportingPeriods.AsNoTracking()
            .Include(x => x.ReportingFrequency)
            .Where(x => x.IsCurrent);
        if (frequencyId.HasValue)
            query = query.Where(x => x.ReportingFrequencyId == frequencyId.Value);
        var entity = await query.FirstOrDefaultAsync(cancellationToken);
        return Result.Ok<ReportingPeriodDto?>(entity == null ? null : MapToDto(entity));
    }

    public async Task<Result<ReportingPeriodDto>> CreateAsync(CreateReportingPeriodRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        if (request.EndDate < request.StartDate)
            return Result.Fail<ReportingPeriodDto>("VALIDATION_FAILED", "EndDate phải >= StartDate.");
        var exists = await _db.ReportingPeriods.AnyAsync(
            x => x.ReportingFrequencyId == request.ReportingFrequencyId && x.PeriodCode == request.PeriodCode,
            cancellationToken);
        if (exists)
            return Result.Fail<ReportingPeriodDto>("CONFLICT", "Kỳ báo cáo với PeriodCode này đã tồn tại cho chu kỳ đã chọn.");

        var entity = new ReportingPeriodEntity
        {
            ReportingFrequencyId = request.ReportingFrequencyId,
            PeriodCode = request.PeriodCode.Trim(),
            PeriodName = request.PeriodName.Trim(),
            Year = request.Year,
            Quarter = request.Quarter,
            Month = request.Month,
            Week = request.Week,
            Day = request.Day,
            StartDate = request.StartDate,
            EndDate = request.EndDate,
            Deadline = request.Deadline,
            Status = request.Status ?? "Open",
            IsCurrent = request.IsCurrent,
            IsLocked = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        if (request.IsCurrent)
        {
            await _db.ReportingPeriods.Where(x => x.ReportingFrequencyId == request.ReportingFrequencyId)
                .ExecuteUpdateAsync(s => s.SetProperty(p => p.IsCurrent, false), cancellationToken);
        }
        _db.ReportingPeriods.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await _db.Entry(entity).Reference(x => x.ReportingFrequency).LoadAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<ReportingPeriodDto>> UpdateAsync(int id, UpdateReportingPeriodRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportingPeriods.Include(x => x.ReportingFrequency)
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<ReportingPeriodDto>("NOT_FOUND", "Kỳ báo cáo không tồn tại.");
        if (request.PeriodName != null) entity.PeriodName = request.PeriodName.Trim();
        if (request.StartDate.HasValue) entity.StartDate = request.StartDate.Value;
        if (request.EndDate.HasValue) entity.EndDate = request.EndDate.Value;
        if (request.Deadline.HasValue) entity.Deadline = request.Deadline.Value;
        if (request.Status != null) entity.Status = request.Status;
        if (request.IsCurrent.HasValue)
        {
            if (request.IsCurrent.Value)
            {
                await _db.ReportingPeriods.Where(x => x.ReportingFrequencyId == entity.ReportingFrequencyId && x.Id != id)
                    .ExecuteUpdateAsync(s => s.SetProperty(p => p.IsCurrent, false), cancellationToken);
            }
            entity.IsCurrent = request.IsCurrent.Value;
        }
        if (request.IsLocked.HasValue)
        {
            entity.IsLocked = request.IsLocked.Value;
            if (request.IsLocked.Value) { entity.LockedAt = DateTime.UtcNow; entity.LockedBy = updatedBy; }
            else { entity.LockedAt = null; entity.LockedBy = null; }
        }
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportingPeriods.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Kỳ báo cáo không tồn tại.");
        var hasSubmission = await _db.ReportSubmissions.AnyAsync(x => x.ReportingPeriodId == id, cancellationToken);
        if (hasSubmission)
            return Result.Fail<object>("CONFLICT", "Không thể xóa kỳ đã có báo cáo nộp.");
        _db.ReportingPeriods.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    public async Task<Result<PeriodSummaryExportDto>> GetSummaryExportAsync(int periodId, CancellationToken cancellationToken = default)
    {
        var periodExists = await _db.ReportingPeriods.AnyAsync(p => p.Id == periodId, cancellationToken);
        if (!periodExists)
            return Result.Fail<PeriodSummaryExportDto>("NOT_FOUND", "Kỳ báo cáo không tồn tại.");

        var submissions = await _db.ReportSubmissions
            .AsNoTracking()
            .Where(s => s.ReportingPeriodId == periodId && !s.IsDeleted)
            .Select(s => new { s.Id, s.OrganizationId })
            .ToListAsync(cancellationToken);

        var submissionIds = submissions.Select(s => s.Id).ToList();
        var submissionMap = submissions.ToDictionary(s => s.Id, s => s.OrganizationId);

        var summaries = await _db.ReportSummaries
            .AsNoTracking()
            .Where(s => submissionIds.Contains(s.SubmissionId))
            .ToListAsync(cancellationToken);

        var rows = summaries.Select(s => new PeriodSummaryRowDto
        {
            SubmissionId = s.SubmissionId,
            OrganizationId = submissionMap.GetValueOrDefault(s.SubmissionId),
            SheetIndex = s.SheetIndex,
            DataRowCount = s.DataRowCount,
            TotalValue1 = s.TotalValue1,
            TotalValue2 = s.TotalValue2,
            TotalValue3 = s.TotalValue3,
            TotalValue4 = s.TotalValue4,
            TotalValue5 = s.TotalValue5,
            TotalValue6 = s.TotalValue6,
            TotalValue7 = s.TotalValue7,
            TotalValue8 = s.TotalValue8,
            TotalValue9 = s.TotalValue9,
            TotalValue10 = s.TotalValue10
        }).ToList();

        return Result.Ok(new PeriodSummaryExportDto
        {
            PeriodId = periodId,
            ExportedAt = DateTime.UtcNow,
            Rows = rows
        });
    }

    private static ReportingPeriodDto MapToDto(ReportingPeriodEntity x) => new()
    {
        Id = x.Id,
        ReportingFrequencyId = x.ReportingFrequencyId,
        ReportingFrequencyCode = x.ReportingFrequency?.Code,
        ReportingFrequencyName = x.ReportingFrequency?.Name,
        PeriodCode = x.PeriodCode,
        PeriodName = x.PeriodName,
        Year = x.Year,
        Quarter = x.Quarter,
        Month = x.Month,
        Week = x.Week,
        Day = x.Day,
        StartDate = x.StartDate,
        EndDate = x.EndDate,
        Deadline = x.Deadline,
        Status = x.Status,
        IsCurrent = x.IsCurrent,
        IsLocked = x.IsLocked,
        LockedAt = x.LockedAt,
        LockedBy = x.LockedBy,
        CreatedAt = x.CreatedAt,
        CreatedBy = x.CreatedBy
    };
}
