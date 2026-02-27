using BCDT.Application.Common;
using BCDT.Application.DTOs.ReportingPeriod;
using BCDT.Application.Services.Cache;
using BCDT.Application.Services.ReportingPeriod;
using BCDT.Domain.Entities.ReportingPeriod;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.ReportingPeriod;

internal static class ReportingFrequencyCacheKeys
{
    public static string List(bool includeInactive) => $"rf:list:{includeInactive}";
    public static string Id(int id) => $"rf:id:{id}";
}

public class ReportingFrequencyService : IReportingFrequencyService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
    private readonly AppDbContext _db;
    private readonly ICacheService _cache;

    public ReportingFrequencyService(AppDbContext db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    public async Task<Result<List<ReportingFrequencyDto>>> GetListAsync(bool includeInactive, CancellationToken cancellationToken = default)
    {
        var key = ReportingFrequencyCacheKeys.List(includeInactive);
        var cached = await _cache.GetAsync<List<ReportingFrequencyDto>>(key, cancellationToken);
        if (cached != null)
            return Result.Ok(cached);

        var query = _db.ReportingFrequencies.AsNoTracking();
        if (!includeInactive)
            query = query.Where(x => x.IsActive);
        var list = await query.OrderBy(x => x.DisplayOrder).ThenBy(x => x.Code)
            .Select(x => new ReportingFrequencyDto
            {
                Id = x.Id,
                Code = x.Code,
                Name = x.Name,
                NameEn = x.NameEn,
                DaysInPeriod = x.DaysInPeriod,
                CronExpression = x.CronExpression,
                Description = x.Description,
                DisplayOrder = x.DisplayOrder,
                IsActive = x.IsActive,
                CreatedAt = x.CreatedAt
            }).ToListAsync(cancellationToken);
        await _cache.SetAsync(key, list, CacheTtl, cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<ReportingFrequencyDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var key = ReportingFrequencyCacheKeys.Id(id);
        var cached = await _cache.GetAsync<ReportingFrequencyDto>(key, cancellationToken);
        if (cached != null)
            return Result.Ok<ReportingFrequencyDto?>(cached);

        var entity = await _db.ReportingFrequencies.AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Ok<ReportingFrequencyDto?>(null);
        var dto = MapToDto(entity);
        await _cache.SetAsync(key, dto, CacheTtl, cancellationToken);
        return Result.Ok<ReportingFrequencyDto?>(dto);
    }

    public async Task<Result<ReportingFrequencyDto>> CreateAsync(CreateReportingFrequencyRequest request, CancellationToken cancellationToken = default)
    {
        var exists = await _db.ReportingFrequencies.AnyAsync(x => x.Code == request.Code.Trim(), cancellationToken);
        if (exists)
            return Result.Fail<ReportingFrequencyDto>("CONFLICT", "Mã chu kỳ báo cáo đã tồn tại.");

        var entity = new ReportingFrequency
        {
            Code = request.Code.Trim(),
            Name = request.Name.Trim(),
            NameEn = request.NameEn?.Trim(),
            DaysInPeriod = request.DaysInPeriod,
            CronExpression = request.CronExpression?.Trim(),
            Description = request.Description?.Trim(),
            DisplayOrder = request.DisplayOrder,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow
        };
        _db.ReportingFrequencies.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(null, cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<ReportingFrequencyDto>> UpdateAsync(int id, UpdateReportingFrequencyRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportingFrequencies.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<ReportingFrequencyDto>("NOT_FOUND", "Chu kỳ báo cáo không tồn tại.");

        entity.Name = request.Name.Trim();
        entity.NameEn = request.NameEn?.Trim();
        entity.DaysInPeriod = request.DaysInPeriod;
        entity.CronExpression = request.CronExpression?.Trim();
        entity.Description = request.Description?.Trim();
        entity.DisplayOrder = request.DisplayOrder;
        entity.IsActive = request.IsActive;
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportingFrequencies.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Chu kỳ báo cáo không tồn tại.");

        var hasPeriods = await _db.ReportingPeriods.AnyAsync(p => p.ReportingFrequencyId == id, cancellationToken);
        if (hasPeriods)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa chu kỳ đang có kỳ báo cáo.");

        _db.ReportingFrequencies.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);
        return Result.Ok<object>(new { });
    }

    private async Task InvalidateCacheAsync(int? id = null, CancellationToken cancellationToken = default)
    {
        await _cache.RemoveAsync(ReportingFrequencyCacheKeys.List(true), cancellationToken);
        await _cache.RemoveAsync(ReportingFrequencyCacheKeys.List(false), cancellationToken);
        if (id.HasValue)
            await _cache.RemoveAsync(ReportingFrequencyCacheKeys.Id(id.Value), cancellationToken);
    }

    private static ReportingFrequencyDto MapToDto(ReportingFrequency e) => new()
    {
        Id = e.Id,
        Code = e.Code,
        Name = e.Name,
        NameEn = e.NameEn,
        DaysInPeriod = e.DaysInPeriod,
        CronExpression = e.CronExpression,
        Description = e.Description,
        DisplayOrder = e.DisplayOrder,
        IsActive = e.IsActive,
        CreatedAt = e.CreatedAt
    };
}
