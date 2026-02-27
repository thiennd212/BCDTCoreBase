using BCDT.Application.Common;
using BCDT.Application.DTOs.ReferenceEntity;
using BCDT.Application.Services.ReferenceEntity;
using BCDT.Domain.Entities.ReferenceData;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.ReferenceEntity;

public class ReferenceEntityTypeService : IReferenceEntityTypeService
{
    private readonly AppDbContext _db;

    public ReferenceEntityTypeService(AppDbContext db) => _db = db;

    public async Task<Result<List<ReferenceEntityTypeDto>>> GetListAsync(bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var query = _db.ReferenceEntityTypes.AsNoTracking();
        if (!includeInactive)
            query = query.Where(t => t.IsActive);
        var list = await query
            .OrderBy(t => t.Code)
            .Select(t => new ReferenceEntityTypeDto
            {
                Id = t.Id,
                Code = t.Code,
                Name = t.Name,
                Description = t.Description,
                IsActive = t.IsActive
            })
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<ReferenceEntityTypeDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReferenceEntityTypes.AsNoTracking()
            .Where(t => t.Id == id)
            .Select(t => new ReferenceEntityTypeDto
            {
                Id = t.Id,
                Code = t.Code,
                Name = t.Name,
                Description = t.Description,
                IsActive = t.IsActive
            })
            .FirstOrDefaultAsync(cancellationToken);
        return Result.Ok<ReferenceEntityTypeDto?>(entity);
    }

    public async Task<Result<ReferenceEntityTypeDto>> CreateAsync(CreateReferenceEntityTypeRequest request, CancellationToken cancellationToken = default)
    {
        var code = request.Code.Trim();
        var exists = await _db.ReferenceEntityTypes.AnyAsync(t => t.Code == code, cancellationToken);
        if (exists)
            return Result.Fail<ReferenceEntityTypeDto>("CONFLICT", "Mã loại thực thể đã tồn tại.");

        var entity = new ReferenceEntityType
        {
            Code = code,
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            IsActive = request.IsActive,
            IsSystem = false,
            CreatedBy = 1
        };
        _db.ReferenceEntityTypes.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(new ReferenceEntityTypeDto
        {
            Id = entity.Id,
            Code = entity.Code,
            Name = entity.Name,
            Description = entity.Description,
            IsActive = entity.IsActive
        });
    }

    public async Task<Result<ReferenceEntityTypeDto>> UpdateAsync(int id, UpdateReferenceEntityTypeRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReferenceEntityTypes.FirstOrDefaultAsync(t => t.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<ReferenceEntityTypeDto>("NOT_FOUND", "Loại thực thể không tồn tại.");

        entity.Name = request.Name.Trim();
        entity.Description = request.Description?.Trim();
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = 1;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(new ReferenceEntityTypeDto
        {
            Id = entity.Id,
            Code = entity.Code,
            Name = entity.Name,
            Description = entity.Description,
            IsActive = entity.IsActive
        });
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReferenceEntityTypes.FirstOrDefaultAsync(t => t.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Loại thực thể không tồn tại.");

        var hasEntities = await _db.ReferenceEntities.AnyAsync(e => e.EntityTypeId == id, cancellationToken);
        if (hasEntities)
            return Result.Fail<object>("CONFLICT", "Không thể xóa loại thực thể đang có bản ghi tham chiếu.");

        _db.ReferenceEntityTypes.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }
}
