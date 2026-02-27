using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Cache;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

internal static class IndicatorCatalogCacheKeys
{
    public static string List(bool includeInactive) => $"ic:list:{includeInactive}";
    public static string Id(int id) => $"ic:id:{id}";
}

public class IndicatorCatalogService : IIndicatorCatalogService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
    private readonly AppDbContext _db;
    private readonly ICacheService _cache;

    public IndicatorCatalogService(AppDbContext db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    public async Task<Result<List<IndicatorCatalogDto>>> GetAllAsync(bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var key = IndicatorCatalogCacheKeys.List(includeInactive);
        var cached = await _cache.GetAsync<List<IndicatorCatalogDto>>(key, cancellationToken);
        if (cached != null)
            return Result.Ok(cached);

        var query = _db.IndicatorCatalogs.AsNoTracking();
        if (!includeInactive)
            query = query.Where(x => x.IsActive);

        var catalogs = await query.OrderBy(x => x.DisplayOrder).ThenBy(x => x.Code).ToListAsync(cancellationToken);

        var catalogIds = catalogs.Select(c => c.Id).ToList();
        var counts = await _db.Indicators
            .Where(i => i.IndicatorCatalogId.HasValue && catalogIds.Contains(i.IndicatorCatalogId.Value))
            .GroupBy(i => i.IndicatorCatalogId!.Value)
            .Select(g => new { CatalogId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.CatalogId, x => x.Count, cancellationToken);

        var list = catalogs.Select(x => MapToDto(x, counts.GetValueOrDefault(x.Id, 0))).ToList();
        await _cache.SetAsync(key, list, CacheTtl, cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<IndicatorCatalogDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var key = IndicatorCatalogCacheKeys.Id(id);
        var cached = await _cache.GetAsync<IndicatorCatalogDto>(key, cancellationToken);
        if (cached != null)
            return Result.Ok<IndicatorCatalogDto?>(cached);

        var entity = await _db.IndicatorCatalogs.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null) return Result.Ok<IndicatorCatalogDto?>(null);
        var count = await _db.Indicators.CountAsync(i => i.IndicatorCatalogId == id, cancellationToken);
        var dto = MapToDto(entity, count);
        await _cache.SetAsync(key, dto, CacheTtl, cancellationToken);
        return Result.Ok<IndicatorCatalogDto?>(dto);
    }

    public async Task<Result<IndicatorCatalogDto>> CreateAsync(CreateIndicatorCatalogRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var exists = await _db.IndicatorCatalogs.AnyAsync(x => x.Code == request.Code.Trim(), cancellationToken);
        if (exists)
            return Result.Fail<IndicatorCatalogDto>("CONFLICT", "Mã danh mục chỉ tiêu đã tồn tại.");

        var entity = new IndicatorCatalog
        {
            Code = request.Code.Trim(),
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            Scope = request.Scope,
            DisplayOrder = request.DisplayOrder,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.IndicatorCatalogs.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(null, cancellationToken);
        return Result.Ok(MapToDto(entity, 0));
    }

    public async Task<Result<IndicatorCatalogDto>> UpdateAsync(int id, UpdateIndicatorCatalogRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.IndicatorCatalogs.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<IndicatorCatalogDto>("NOT_FOUND", "Danh mục chỉ tiêu không tồn tại.");

        entity.Name = request.Name.Trim();
        entity.Description = request.Description?.Trim();
        entity.Scope = request.Scope;
        entity.DisplayOrder = request.DisplayOrder;
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);

        var count = await _db.Indicators.CountAsync(i => i.IndicatorCatalogId == id, cancellationToken);
        return Result.Ok(MapToDto(entity, count));
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.IndicatorCatalogs.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Danh mục chỉ tiêu không tồn tại.");

        var hasIndicators = await _db.Indicators.AnyAsync(i => i.IndicatorCatalogId == id, cancellationToken);
        if (hasIndicators)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa danh mục đang chứa chỉ tiêu.");

        var usedByRegion = await _db.FormDynamicRegions.AnyAsync(r => r.IndicatorCatalogId == id, cancellationToken);
        if (usedByRegion)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa danh mục đang được vùng chỉ tiêu động tham chiếu.");

        _db.IndicatorCatalogs.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);
        return Result.Ok<object>(new { });
    }

    private async Task InvalidateCacheAsync(int? id = null, CancellationToken cancellationToken = default)
    {
        await _cache.RemoveAsync(IndicatorCatalogCacheKeys.List(true), cancellationToken);
        await _cache.RemoveAsync(IndicatorCatalogCacheKeys.List(false), cancellationToken);
        if (id.HasValue)
            await _cache.RemoveAsync(IndicatorCatalogCacheKeys.Id(id.Value), cancellationToken);
    }

    private static IndicatorCatalogDto MapToDto(IndicatorCatalog x, int indicatorCount) => new()
    {
        Id = x.Id,
        Code = x.Code,
        Name = x.Name,
        Description = x.Description,
        Scope = x.Scope,
        DisplayOrder = x.DisplayOrder,
        IsActive = x.IsActive,
        CreatedAt = x.CreatedAt,
        CreatedBy = x.CreatedBy,
        IndicatorCount = indicatorCount
    };
}
