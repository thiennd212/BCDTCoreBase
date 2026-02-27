using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Cache;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

internal static class DataSourceCacheKeys
{
    public const string List = "ds:list";
    public static string Id(int id) => $"ds:id:{id}";
}

public class DataSourceService : IDataSourceService
{
    private static readonly TimeSpan CacheTtl = TimeSpan.FromMinutes(10);
    private readonly AppDbContext _db;
    private readonly ICacheService _cache;

    public DataSourceService(AppDbContext db, ICacheService cache)
    {
        _db = db;
        _cache = cache;
    }

    public async Task<Result<List<DataSourceDto>>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var cached = await _cache.GetAsync<List<DataSourceDto>>(DataSourceCacheKeys.List, cancellationToken);
        if (cached != null)
            return Result.Ok(cached);

        var list = await _db.DataSources
            .AsNoTracking()
            .OrderBy(x => x.Code)
            .Select(x => MapToDto(x))
            .ToListAsync(cancellationToken);
        await _cache.SetAsync(DataSourceCacheKeys.List, list, CacheTtl, cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<DataSourceDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var key = DataSourceCacheKeys.Id(id);
        var cached = await _cache.GetAsync<DataSourceDto>(key, cancellationToken);
        if (cached != null)
            return Result.Ok<DataSourceDto?>(cached);

        var entity = await _db.DataSources.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Ok<DataSourceDto?>(null);
        var dto = MapToDto(entity);
        await _cache.SetAsync(key, dto, CacheTtl, cancellationToken);
        return Result.Ok<DataSourceDto?>(dto);
    }

    public async Task<Result<List<DataSourceColumnDto>>> GetColumnsAsync(int id, CancellationToken cancellationToken = default)
    {
        var ds = await _db.DataSources.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (ds == null)
            return Result.Fail<List<DataSourceColumnDto>>("NOT_FOUND", "Nguồn dữ liệu không tồn tại.");
        if (ds.SourceType != "Table" && ds.SourceType != "View")
            return Result.Ok(new List<DataSourceColumnDto>()); // Catalog/API: trả rỗng hoặc mở rộng sau
        var tableName = (ds.SourceRef ?? "").Trim();
        if (string.IsNullOrEmpty(tableName) || !System.Text.RegularExpressions.Regex.IsMatch(tableName, @"^[a-zA-Z0-9_]+$"))
            return Result.Ok(new List<DataSourceColumnDto>());
        try
        {
            var sql = "SELECT COLUMN_NAME AS Name, DATA_TYPE AS DataType FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_SCHEMA = 'dbo' AND TABLE_NAME = {0} ORDER BY ORDINAL_POSITION";
            var columns = await _db.Database.SqlQueryRaw<DataSourceColumnDto>(sql, tableName).ToListAsync(cancellationToken);
            return Result.Ok(columns);
        }
        catch
        {
            return Result.Ok(new List<DataSourceColumnDto>());
        }
    }

    public async Task<Result<DataSourceDto>> CreateAsync(CreateDataSourceRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var exists = await _db.DataSources.AnyAsync(x => x.Code == request.Code.Trim(), cancellationToken);
        if (exists)
            return Result.Fail<DataSourceDto>("CONFLICT", "Mã nguồn dữ liệu đã tồn tại.");
        var entity = new DataSource
        {
            Code = request.Code.Trim(),
            Name = request.Name.Trim(),
            SourceType = request.SourceType ?? "Table",
            SourceRef = request.SourceRef?.Trim(),
            IndicatorCatalogId = request.IndicatorCatalogId,
            DisplayColumn = request.DisplayColumn?.Trim(),
            ValueColumn = request.ValueColumn?.Trim(),
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.DataSources.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(null, cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<DataSourceDto>> UpdateAsync(int id, UpdateDataSourceRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.DataSources.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<DataSourceDto>("NOT_FOUND", "Nguồn dữ liệu không tồn tại.");
        entity.Name = request.Name.Trim();
        entity.SourceType = request.SourceType ?? "Table";
        entity.SourceRef = request.SourceRef?.Trim();
        entity.IndicatorCatalogId = request.IndicatorCatalogId;
        entity.DisplayColumn = request.DisplayColumn?.Trim();
        entity.ValueColumn = request.ValueColumn?.Trim();
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.DataSources.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Nguồn dữ liệu không tồn tại.");
        var usedByFilter = await _db.FilterDefinitions.AnyAsync(f => f.DataSourceId == id, cancellationToken);
        if (usedByFilter)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa nguồn đang được bộ lọc tham chiếu.");
        var usedByOccurrence = await _db.FormPlaceholderOccurrences.AnyAsync(o => o.DataSourceId == id, cancellationToken);
        if (usedByOccurrence)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa nguồn đang được vị trí placeholder tham chiếu.");
        _db.DataSources.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        await InvalidateCacheAsync(id, cancellationToken);
        return Result.Ok<object>(new { });
    }

    private async Task InvalidateCacheAsync(int? id = null, CancellationToken cancellationToken = default)
    {
        await _cache.RemoveAsync(DataSourceCacheKeys.List, cancellationToken);
        if (id.HasValue)
            await _cache.RemoveAsync(DataSourceCacheKeys.Id(id.Value), cancellationToken);
    }

    private static DataSourceDto MapToDto(DataSource x) => new()
    {
        Id = x.Id,
        Code = x.Code,
        Name = x.Name,
        SourceType = x.SourceType,
        SourceRef = x.SourceRef,
        IndicatorCatalogId = x.IndicatorCatalogId,
        DisplayColumn = x.DisplayColumn,
        ValueColumn = x.ValueColumn,
        IsActive = x.IsActive,
        CreatedAt = x.CreatedAt,
        CreatedBy = x.CreatedBy
    };
}
