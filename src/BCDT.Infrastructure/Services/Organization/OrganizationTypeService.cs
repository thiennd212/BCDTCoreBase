using BCDT.Application.Common;
using BCDT.Application.DTOs.Organization;
using BCDT.Application.Services.Cache;
using BCDT.Application.Services.Organization;
using BCDT.Domain.Entities.Organization;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

internal static class OrganizationTypeCacheKeys
{
    public static string List(bool includeInactive) => $"ot:list:{includeInactive}";
    public static string Id(int id) => $"ot:id:{id}";
}

public class OrganizationTypeService : IOrganizationTypeService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
    private readonly AppDbContext _db;
    private readonly ICacheService _cache;

    public OrganizationTypeService(AppDbContext db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    public async Task<Result<List<OrganizationTypeDto>>> GetAllAsync(bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var key = OrganizationTypeCacheKeys.List(includeInactive);
        var cached = await _cache.GetAsync<List<OrganizationTypeDto>>(key, cancellationToken);
        if (cached != null)
            return Result.Ok(cached);

        var query = _db.OrganizationTypes.AsNoTracking();
        if (!includeInactive)
            query = query.Where(x => x.IsActive);

        var types = await query.OrderBy(x => x.Level).ThenBy(x => x.Code).ToListAsync(cancellationToken);

        var typeIds = types.Select(t => t.Id).ToList();
        var counts = await _db.Organizations
            .Where(o => typeIds.Contains(o.OrganizationTypeId))
            .GroupBy(o => o.OrganizationTypeId)
            .Select(g => new { TypeId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.TypeId, x => x.Count, cancellationToken);

        var list = types.Select(x => MapToDto(x, counts.GetValueOrDefault(x.Id, 0))).ToList();
        await _cache.SetAsync(key, list, CacheTtl, cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<OrganizationTypeDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var key = OrganizationTypeCacheKeys.Id(id);
        var cached = await _cache.GetAsync<OrganizationTypeDto>(key, cancellationToken);
        if (cached != null)
            return Result.Ok<OrganizationTypeDto?>(cached);

        var entity = await _db.OrganizationTypes.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null) return Result.Ok<OrganizationTypeDto?>(null);
        var count = await _db.Organizations.CountAsync(o => o.OrganizationTypeId == id, cancellationToken);
        var dto = MapToDto(entity, count);
        await _cache.SetAsync(key, dto, CacheTtl, cancellationToken);
        return Result.Ok<OrganizationTypeDto?>(dto);
    }

    public async Task<Result<OrganizationTypeDto>> CreateAsync(CreateOrganizationTypeRequest request, CancellationToken cancellationToken = default)
    {
        var exists = await _db.OrganizationTypes.AnyAsync(x => x.Code == request.Code.Trim(), cancellationToken);
        if (exists)
            return Result.Fail<OrganizationTypeDto>("CONFLICT", "Mã loại đơn vị đã tồn tại.");

        if (request.ParentTypeId.HasValue)
        {
            var parentExists = await _db.OrganizationTypes.AnyAsync(x => x.Id == request.ParentTypeId.Value, cancellationToken);
            if (!parentExists)
                return Result.Fail<OrganizationTypeDto>("VALIDATION_FAILED", "Loại đơn vị cha không tồn tại.");
        }

        var entity = new OrganizationType
        {
            Code = request.Code.Trim(),
            Name = request.Name.Trim(),
            Level = request.Level,
            ParentTypeId = request.ParentTypeId,
            Description = request.Description?.Trim(),
            IsActive = request.IsActive
        };
        _db.OrganizationTypes.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(null, cancellationToken);
        return Result.Ok(MapToDto(entity, 0));
    }

    public async Task<Result<OrganizationTypeDto>> UpdateAsync(int id, UpdateOrganizationTypeRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.OrganizationTypes.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<OrganizationTypeDto>("NOT_FOUND", "Loại đơn vị không tồn tại.");

        if (request.ParentTypeId.HasValue)
        {
            if (request.ParentTypeId.Value == id)
                return Result.Fail<OrganizationTypeDto>("VALIDATION_FAILED", "Không thể chọn chính mình làm loại cha.");
            var parentExists = await _db.OrganizationTypes.AnyAsync(x => x.Id == request.ParentTypeId.Value, cancellationToken);
            if (!parentExists)
                return Result.Fail<OrganizationTypeDto>("VALIDATION_FAILED", "Loại đơn vị cha không tồn tại.");
        }

        entity.Name = request.Name.Trim();
        entity.Level = request.Level;
        entity.ParentTypeId = request.ParentTypeId;
        entity.Description = request.Description?.Trim();
        entity.IsActive = request.IsActive;
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);

        var count = await _db.Organizations.CountAsync(o => o.OrganizationTypeId == id, cancellationToken);
        return Result.Ok(MapToDto(entity, count));
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.OrganizationTypes.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Loại đơn vị không tồn tại.");

        var hasOrganizations = await _db.Organizations.AnyAsync(o => o.OrganizationTypeId == id, cancellationToken);
        if (hasOrganizations)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa loại đơn vị đang có đơn vị sử dụng.");

        var hasChildren = await _db.OrganizationTypes.AnyAsync(x => x.ParentTypeId == id, cancellationToken);
        if (hasChildren)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa loại đơn vị đang có loại con.");

        _db.OrganizationTypes.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);
        return Result.Ok<object>(new { });
    }

    private async Task InvalidateCacheAsync(int? id = null, CancellationToken cancellationToken = default)
    {
        await _cache.RemoveAsync(OrganizationTypeCacheKeys.List(true), cancellationToken);
        await _cache.RemoveAsync(OrganizationTypeCacheKeys.List(false), cancellationToken);
        if (id.HasValue)
            await _cache.RemoveAsync(OrganizationTypeCacheKeys.Id(id.Value), cancellationToken);
    }

    private static OrganizationTypeDto MapToDto(OrganizationType x, int orgCount) => new()
    {
        Id = x.Id,
        Code = x.Code,
        Name = x.Name,
        Level = x.Level,
        ParentTypeId = x.ParentTypeId,
        Description = x.Description,
        IsActive = x.IsActive,
        OrganizationCount = orgCount
    };
}
