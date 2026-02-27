using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Cache;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

internal static class FilterDefinitionCacheKeys
{
    public const string List = "fd:list";
    public static string Id(int id) => $"fd:id:{id}";
}

public class FilterDefinitionService : IFilterDefinitionService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
    private readonly AppDbContext _db;
    private readonly ICacheService _cache;

    public FilterDefinitionService(AppDbContext db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    public async Task<Result<List<FilterDefinitionDto>>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var cached = await _cache.GetAsync<List<FilterDefinitionDto>>(FilterDefinitionCacheKeys.List, cancellationToken);
        if (cached != null)
            return Result.Ok(cached);

        var list = await _db.FilterDefinitions
            .AsNoTracking()
            .OrderBy(x => x.Code)
            .ToListAsync(cancellationToken);
        var ids = list.Select(x => x.Id).ToList();
        var conditions = await _db.FilterConditions
            .AsNoTracking()
            .Where(c => ids.Contains(c.FilterDefinitionId))
            .OrderBy(c => c.FilterDefinitionId).ThenBy(c => c.ConditionOrder)
            .ToListAsync(cancellationToken);
        var conditionMap = conditions.GroupBy(c => c.FilterDefinitionId).ToDictionary(g => g.Key, g => g.Select(MapConditionToDto).ToList());
        var dtos = list.Select(f => new FilterDefinitionDto
        {
            Id = f.Id,
            Code = f.Code,
            Name = f.Name,
            LogicalOperator = f.LogicalOperator,
            DataSourceId = f.DataSourceId,
            Conditions = conditionMap.GetValueOrDefault(f.Id, new List<FilterConditionDto>()),
            CreatedAt = f.CreatedAt,
            CreatedBy = f.CreatedBy
        }).ToList();
        await _cache.SetAsync(FilterDefinitionCacheKeys.List, dtos, CacheTtl, cancellationToken);
        return Result.Ok(dtos);
    }

    public async Task<Result<FilterDefinitionDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var key = FilterDefinitionCacheKeys.Id(id);
        var cached = await _cache.GetAsync<FilterDefinitionDto>(key, cancellationToken);
        if (cached != null)
            return Result.Ok<FilterDefinitionDto?>(cached);

        var entity = await _db.FilterDefinitions.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Ok<FilterDefinitionDto?>(null);
        var conditions = await _db.FilterConditions
            .AsNoTracking()
            .Where(c => c.FilterDefinitionId == id)
            .OrderBy(c => c.ConditionOrder)
            .Select(c => MapConditionToDto(c))
            .ToListAsync(cancellationToken);
        var dto = new FilterDefinitionDto
        {
            Id = entity.Id,
            Code = entity.Code,
            Name = entity.Name,
            LogicalOperator = entity.LogicalOperator,
            DataSourceId = entity.DataSourceId,
            Conditions = conditions,
            CreatedAt = entity.CreatedAt,
            CreatedBy = entity.CreatedBy
        };
        await _cache.SetAsync(key, dto, CacheTtl, cancellationToken);
        return Result.Ok<FilterDefinitionDto?>(dto);
    }

    public async Task<Result<IReadOnlyDictionary<int, FilterDefinitionDto>>> GetByIdsAsync(IReadOnlyList<int> ids, CancellationToken cancellationToken = default)
    {
        if (ids == null || ids.Count == 0)
            return Result.Ok<IReadOnlyDictionary<int, FilterDefinitionDto>>(new Dictionary<int, FilterDefinitionDto>());
        var distinctIds = ids.Distinct().ToList();
        var list = await _db.FilterDefinitions
            .AsNoTracking()
            .Where(x => distinctIds.Contains(x.Id))
            .ToListAsync(cancellationToken);
        var filterIds = list.Select(x => x.Id).ToList();
        var conditionEntities = await _db.FilterConditions
            .AsNoTracking()
            .Where(c => filterIds.Contains(c.FilterDefinitionId))
            .OrderBy(c => c.FilterDefinitionId).ThenBy(c => c.ConditionOrder)
            .ToListAsync(cancellationToken);
        var conditionMap = conditionEntities.GroupBy(c => c.FilterDefinitionId).ToDictionary(g => g.Key, g => g.Select(MapConditionToDto).ToList());
        var dict = list.ToDictionary(f => f.Id, f => new FilterDefinitionDto
        {
            Id = f.Id,
            Code = f.Code,
            Name = f.Name,
            LogicalOperator = f.LogicalOperator,
            DataSourceId = f.DataSourceId,
            Conditions = conditionMap.GetValueOrDefault(f.Id, new List<FilterConditionDto>()),
            CreatedAt = f.CreatedAt,
            CreatedBy = f.CreatedBy
        });
        return Result.Ok<IReadOnlyDictionary<int, FilterDefinitionDto>>(dict);
    }

    public async Task<Result<FilterDefinitionDto>> CreateAsync(CreateFilterDefinitionRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var exists = await _db.FilterDefinitions.AnyAsync(x => x.Code == request.Code.Trim(), cancellationToken);
        if (exists)
            return Result.Fail<FilterDefinitionDto>("CONFLICT", "Mã bộ lọc đã tồn tại.");
        var entity = new FilterDefinition
        {
            Code = request.Code.Trim(),
            Name = request.Name.Trim(),
            LogicalOperator = request.LogicalOperator == "OR" ? "OR" : "AND",
            DataSourceId = request.DataSourceId,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FilterDefinitions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        var order = 0;
        foreach (var c in request.Conditions ?? new List<CreateFilterConditionItem>())
        {
            _db.FilterConditions.Add(new FilterCondition
            {
                FilterDefinitionId = entity.Id,
                ConditionOrder = c.ConditionOrder,
                Field = c.Field.Trim(),
                Operator = c.Operator.Trim(),
                ValueType = c.ValueType ?? "Literal",
                Value = c.Value?.Trim(),
                Value2 = c.Value2?.Trim(),
                DataType = c.DataType?.Trim(),
                CreatedAt = DateTime.UtcNow,
                CreatedBy = createdBy
            });
            order++;
        }
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(null, cancellationToken);
        return await GetByIdAsync(entity.Id, cancellationToken) is { IsSuccess: true, Data: { } d }
            ? Result.Ok(d)
            : Result.Ok(new FilterDefinitionDto { Id = entity.Id, Code = entity.Code, Name = entity.Name, LogicalOperator = entity.LogicalOperator, DataSourceId = entity.DataSourceId, CreatedAt = entity.CreatedAt, CreatedBy = entity.CreatedBy });
    }

    public async Task<Result<FilterDefinitionDto>> UpdateAsync(int id, UpdateFilterDefinitionRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FilterDefinitions.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<FilterDefinitionDto>("NOT_FOUND", "Bộ lọc không tồn tại.");
        entity.Name = request.Name.Trim();
        entity.LogicalOperator = request.LogicalOperator == "OR" ? "OR" : "AND";
        entity.DataSourceId = request.DataSourceId;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        var existingIds = (request.Conditions ?? new List<UpdateFilterConditionItem>()).Where(c => c.Id > 0).Select(c => c.Id).ToHashSet();
        var toDelete = await _db.FilterConditions.Where(c => c.FilterDefinitionId == id && !existingIds.Contains(c.Id)).ToListAsync(cancellationToken);
        foreach (var c in toDelete)
            _db.FilterConditions.Remove(c);
        foreach (var item in request.Conditions ?? new List<UpdateFilterConditionItem>())
        {
            if (item.Id > 0)
            {
                var cond = await _db.FilterConditions.FirstOrDefaultAsync(c => c.Id == item.Id && c.FilterDefinitionId == id, cancellationToken);
                if (cond != null)
                {
                    cond.ConditionOrder = item.ConditionOrder;
                    cond.Field = item.Field.Trim();
                    cond.Operator = item.Operator.Trim();
                    cond.ValueType = item.ValueType ?? "Literal";
                    cond.Value = item.Value?.Trim();
                    cond.Value2 = item.Value2?.Trim();
                    cond.DataType = item.DataType?.Trim();
                }
            }
            else
            {
                _db.FilterConditions.Add(new FilterCondition
                {
                    FilterDefinitionId = id,
                    ConditionOrder = item.ConditionOrder,
                    Field = item.Field.Trim(),
                    Operator = item.Operator.Trim(),
                    ValueType = item.ValueType ?? "Literal",
                    Value = item.Value?.Trim(),
                    Value2 = item.Value2?.Trim(),
                    DataType = item.DataType?.Trim(),
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = updatedBy
                });
            }
        }
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);
        return await GetByIdAsync(id, cancellationToken) is { IsSuccess: true, Data: { } d }
            ? Result.Ok(d)
            : Result.Fail<FilterDefinitionDto>("ERROR", "Không load lại bộ lọc.");
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FilterDefinitions.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Bộ lọc không tồn tại.");
        var used = await _db.FormPlaceholderOccurrences.AnyAsync(o => o.FilterDefinitionId == id, cancellationToken);
        if (used)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa bộ lọc đang được vị trí placeholder tham chiếu.");
        _db.FilterDefinitions.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);
        return Result.Ok<object>(new { });
    }

    private async Task InvalidateCacheAsync(int? id = null, CancellationToken cancellationToken = default)
    {
        await _cache.RemoveAsync(FilterDefinitionCacheKeys.List, cancellationToken);
        if (id.HasValue)
            await _cache.RemoveAsync(FilterDefinitionCacheKeys.Id(id.Value), cancellationToken);
    }

    private static FilterConditionDto MapConditionToDto(FilterCondition c) => new()
    {
        Id = c.Id,
        FilterDefinitionId = c.FilterDefinitionId,
        ConditionOrder = c.ConditionOrder,
        Field = c.Field,
        Operator = c.Operator,
        ValueType = c.ValueType,
        Value = c.Value,
        Value2 = c.Value2,
        DataType = c.DataType
    };
}
