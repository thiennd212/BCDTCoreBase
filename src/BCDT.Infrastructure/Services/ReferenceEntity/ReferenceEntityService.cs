using BCDT.Application.Common;
using BCDT.Application.DTOs.ReferenceEntity;
using BCDT.Application.Services.ReferenceEntity;
using BCDT.Domain.Entities.ReferenceData;
using BCDT.Infrastructure.Persistence;
using RefEntity = BCDT.Domain.Entities.ReferenceData.ReferenceEntity;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.ReferenceEntity;

public class ReferenceEntityService : IReferenceEntityService
{
    private readonly AppDbContext _db;

    public ReferenceEntityService(AppDbContext db) => _db = db;

    public async Task<Result<ReferenceEntityDto?>> GetByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReferenceEntities
            .AsNoTracking()
            .Where(e => e.Id == id && !e.IsDeleted)
            .Select(e => new { Entity = e, TypeCode = _db.ReferenceEntityTypes.Where(t => t.Id == e.EntityTypeId).Select(t => t.Code).FirstOrDefault() })
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Ok<ReferenceEntityDto?>(null);
        var dto = MapToDto(entity.Entity, entity.TypeCode, null);
        if (entity.Entity.ParentId.HasValue)
        {
            var parentName = await _db.ReferenceEntities
                .AsNoTracking()
                .Where(e => e.Id == entity.Entity.ParentId.Value)
                .Select(e => e.Name)
                .FirstOrDefaultAsync(cancellationToken);
            dto.ParentName = parentName;
        }
        return Result.Ok<ReferenceEntityDto?>(dto);
    }

    public async Task<Result<List<ReferenceEntityDto>>> GetListAsync(int? entityTypeId, long? parentId, bool includeInactive, bool all = false, CancellationToken cancellationToken = default)
    {
        var query = _db.ReferenceEntities.AsNoTracking().Where(e => !e.IsDeleted);
        if (!includeInactive)
            query = query.Where(e => e.IsActive);
        if (entityTypeId.HasValue)
            query = query.Where(e => e.EntityTypeId == entityTypeId.Value);
        if (!all)
        {
            if (parentId.HasValue)
                query = query.Where(e => e.ParentId == parentId.Value);
            else
                query = query.Where(e => e.ParentId == null);
        }

        var items = await query
            .OrderBy(e => e.DisplayOrder)
            .ThenBy(e => e.Code)
            .Join(_db.ReferenceEntityTypes.AsNoTracking(), e => e.EntityTypeId, t => t.Id, (e, t) => new { Entity = e, TypeCode = t.Code })
            .ToListAsync(cancellationToken);

        var parentIds = items.Select(x => x.Entity.ParentId).Where(x => x.HasValue).Select(x => x!.Value).Distinct().ToList();
        var parentNames = parentIds.Count > 0
            ? await _db.ReferenceEntities.AsNoTracking().Where(p => parentIds.Contains(p.Id)).Select(p => new { p.Id, p.Name }).ToDictionaryAsync(x => x.Id, x => x.Name, cancellationToken)
            : new Dictionary<long, string>();

        var dtos = items.Select(x =>
        {
            var parentName = x.Entity.ParentId.HasValue && parentNames.TryGetValue(x.Entity.ParentId.Value, out var pn) ? pn : null;
            return MapToDto(x.Entity, x.TypeCode, parentName);
        }).ToList();
        return Result.Ok(dtos);
    }

    public async Task<Result<ReferenceEntityDto>> CreateAsync(CreateReferenceEntityRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        if (!await _db.ReferenceEntityTypes.AnyAsync(t => t.Id == request.EntityTypeId, cancellationToken))
            return Result.Fail<ReferenceEntityDto>("NOT_FOUND", "Loại thực thể tham chiếu không tồn tại.");
        if (await _db.ReferenceEntities.AnyAsync(e => e.EntityTypeId == request.EntityTypeId && e.Code == request.Code && !e.IsDeleted, cancellationToken))
            return Result.Fail<ReferenceEntityDto>("CONFLICT", "Mã đã tồn tại trong cùng loại.");
        if (request.ParentId.HasValue)
        {
            var parent = await _db.ReferenceEntities.FirstOrDefaultAsync(e => e.Id == request.ParentId.Value && !e.IsDeleted, cancellationToken);
            if (parent == null)
                return Result.Fail<ReferenceEntityDto>("NOT_FOUND", "Bản ghi cha không tồn tại.");
            if (parent.EntityTypeId != request.EntityTypeId)
                return Result.Fail<ReferenceEntityDto>("VALIDATION_FAILED", "Cha phải cùng loại thực thể.");
        }

        var entity = new RefEntity
        {
            EntityTypeId = request.EntityTypeId,
            Code = request.Code,
            Name = request.Name,
            ParentId = request.ParentId,
            OrganizationId = request.OrganizationId,
            DisplayOrder = request.DisplayOrder,
            IsActive = request.IsActive,
            ValidFrom = request.ValidFrom,
            ValidTo = request.ValidTo,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy,
            IsDeleted = false
        };
        _db.ReferenceEntities.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);

        var typeCode = await _db.ReferenceEntityTypes.Where(t => t.Id == entity.EntityTypeId).Select(t => t.Code).FirstAsync(cancellationToken);
        return Result.Ok(MapToDto(entity, typeCode, null));
    }

    public async Task<Result<ReferenceEntityDto>> UpdateAsync(long id, UpdateReferenceEntityRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReferenceEntities.FirstOrDefaultAsync(e => e.Id == id && !e.IsDeleted, cancellationToken);
        if (entity == null)
            return Result.Fail<ReferenceEntityDto>("NOT_FOUND", "Bản ghi không tồn tại.");
        if (request.ParentId.HasValue)
        {
            if (request.ParentId.Value == id)
                return Result.Fail<ReferenceEntityDto>("VALIDATION_FAILED", "Không thể chọn chính nó làm cha.");
            var parent = await _db.ReferenceEntities.FirstOrDefaultAsync(e => e.Id == request.ParentId.Value && !e.IsDeleted, cancellationToken);
            if (parent == null)
                return Result.Fail<ReferenceEntityDto>("NOT_FOUND", "Bản ghi cha không tồn tại.");
            if (parent.EntityTypeId != entity.EntityTypeId)
                return Result.Fail<ReferenceEntityDto>("VALIDATION_FAILED", "Cha phải cùng loại thực thể.");
            if (await IsDescendantAsync(request.ParentId.Value, id, cancellationToken))
                return Result.Fail<ReferenceEntityDto>("VALIDATION_FAILED", "Không thể chọn con làm cha (tham chiếu vòng).");
        }

        entity.Name = request.Name;
        entity.ParentId = request.ParentId;
        entity.OrganizationId = request.OrganizationId;
        entity.DisplayOrder = request.DisplayOrder;
        entity.IsActive = request.IsActive;
        entity.ValidFrom = request.ValidFrom;
        entity.ValidTo = request.ValidTo;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);

        var typeCode = await _db.ReferenceEntityTypes.Where(t => t.Id == entity.EntityTypeId).Select(t => t.Code).FirstAsync(cancellationToken);
        string? parentName = null;
        if (entity.ParentId.HasValue)
            parentName = await _db.ReferenceEntities.AsNoTracking().Where(e => e.Id == entity.ParentId.Value).Select(e => e.Name).FirstOrDefaultAsync(cancellationToken);
        return Result.Ok(MapToDto(entity, typeCode, parentName));
    }

    public async Task<Result<object>> DeleteAsync(long id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReferenceEntities.FirstOrDefaultAsync(e => e.Id == id && !e.IsDeleted, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Bản ghi không tồn tại.");
        if (await _db.ReferenceEntities.AnyAsync(e => e.ParentId == id && !e.IsDeleted, cancellationToken))
            return Result.Fail<object>("CONFLICT", "Có bản ghi con, không thể xóa.");
        entity.IsDeleted = true;
        entity.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(null!);
    }

    private async Task<bool> IsDescendantAsync(long ancestorId, long nodeId, CancellationToken cancellationToken)
    {
        var current = ancestorId;
        var visited = new HashSet<long>();
        while (true)
        {
            if (visited.Contains(current)) return false;
            visited.Add(current);
            var parentId = await _db.ReferenceEntities.Where(e => e.Id == current && !e.IsDeleted).Select(e => e.ParentId).FirstOrDefaultAsync(cancellationToken);
            if (!parentId.HasValue) return false;
            if (parentId.Value == nodeId) return true;
            current = parentId.Value;
        }
    }

    private static ReferenceEntityDto MapToDto(RefEntity e, string? typeCode, string? parentName) => new()
    {
        Id = e.Id,
        EntityTypeId = e.EntityTypeId,
        EntityTypeCode = typeCode,
        Code = e.Code,
        Name = e.Name,
        ParentId = e.ParentId,
        ParentName = parentName,
        OrganizationId = e.OrganizationId,
        DisplayOrder = e.DisplayOrder,
        IsActive = e.IsActive,
        ValidFrom = e.ValidFrom,
        ValidTo = e.ValidTo,
        CreatedAt = e.CreatedAt
    };
}
