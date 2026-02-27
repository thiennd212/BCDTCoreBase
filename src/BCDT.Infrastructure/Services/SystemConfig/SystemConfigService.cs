using BCDT.Application.Common;
using BCDT.Application.DTOs.SystemConfig;
using BCDT.Application.Services.SystemConfig;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.SystemConfig;

public class SystemConfigService : ISystemConfigService
{
    private readonly AppDbContext _db;

    public SystemConfigService(AppDbContext db) => _db = db;

    public async Task<Result<List<SystemConfigDto>>> GetAllAsync(CancellationToken cancellationToken = default)
    {
        var list = await _db.SystemConfigs
            .AsNoTracking()
            .OrderBy(c => c.ConfigKey)
            .ToListAsync(cancellationToken);
        return Result.Ok(list.Select(MapToDto).ToList());
    }

    public async Task<Result<SystemConfigDto?>> GetByKeyAsync(string key, CancellationToken cancellationToken = default)
    {
        var entity = await _db.SystemConfigs
            .AsNoTracking()
            .FirstOrDefaultAsync(c => c.ConfigKey == key, cancellationToken);
        return Result.Ok<SystemConfigDto?>(entity != null ? MapToDto(entity) : null);
    }

    public async Task<Result<SystemConfigDto>> UpdateAsync(string key, UpdateSystemConfigRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.SystemConfigs.FirstOrDefaultAsync(c => c.ConfigKey == key, cancellationToken);
        if (entity == null)
            return Result.Fail<SystemConfigDto>("NOT_FOUND", "Không tìm thấy cấu hình.");

        entity.ConfigValue = request.ConfigValue;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok(MapToDto(entity));
    }

    private static SystemConfigDto MapToDto(Domain.Entities.SystemConfig c) => new()
    {
        Id = c.Id,
        ConfigKey = c.ConfigKey,
        ConfigValue = c.ConfigValue,
        DataType = c.DataType,
        Description = c.Description,
        IsEncrypted = c.IsEncrypted,
        UpdatedAt = c.UpdatedAt,
        UpdatedBy = c.UpdatedBy
    };
}
