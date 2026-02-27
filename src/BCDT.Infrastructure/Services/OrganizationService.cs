using BCDT.Application.Common;
using BCDT.Application.DTOs.Organization;
using BCDT.Application.Services.Organization;
using BCDT.Domain.Entities.Organization;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class OrganizationService : IOrganizationService
{
    private readonly AppDbContext _db;

    public OrganizationService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<Result<OrganizationDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Organizations
            .AsNoTracking()
            .Where(o => o.Id == id && !o.IsDeleted)
            .Select(o => new { Org = o, TypeCode = _db.OrganizationTypes.Where(t => t.Id == o.OrganizationTypeId).Select(t => t.Code).FirstOrDefault() })
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Ok<OrganizationDto?>(null);
        return Result.Ok<OrganizationDto?>(MapToDto(entity.Org, entity.TypeCode));
    }

    public async Task<Result<List<OrganizationDto>>> GetListAsync(int? parentId, int? organizationTypeId, bool includeInactive, bool all = false, CancellationToken cancellationToken = default)
    {
        var query = _db.Organizations.AsNoTracking().Where(o => !o.IsDeleted);
        if (!includeInactive)
            query = query.Where(o => o.IsActive);
        if (!all)
        {
            if (parentId.HasValue)
                query = query.Where(o => o.ParentId == parentId.Value);
            else
                query = query.Where(o => o.ParentId == null);
        }
        if (organizationTypeId.HasValue)
            query = query.Where(o => o.OrganizationTypeId == organizationTypeId.Value);

        var list = await query
            .OrderBy(o => o.DisplayOrder).ThenBy(o => o.Code)
            .Join(_db.OrganizationTypes.AsNoTracking(), o => o.OrganizationTypeId, t => t.Id, (o, t) => new { Org = o, TypeCode = t.Code })
            .Select(x => MapToDto(x.Org, x.TypeCode))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<OrganizationDto>> CreateAsync(CreateOrganizationRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var typeExists = await _db.OrganizationTypes.AnyAsync(t => t.Id == request.OrganizationTypeId, cancellationToken);
        if (!typeExists)
            return Result.Fail<OrganizationDto>("NOT_FOUND", "OrganizationType không tồn tại.");
        if (await _db.Organizations.AnyAsync(o => o.Code == request.Code && !o.IsDeleted, cancellationToken))
            return Result.Fail<OrganizationDto>("CONFLICT", "Code đơn vị đã tồn tại.");

        int level;
        if (request.ParentId.HasValue)
        {
            var parent = await _db.Organizations.FirstOrDefaultAsync(o => o.Id == request.ParentId.Value && !o.IsDeleted, cancellationToken);
            if (parent == null)
                return Result.Fail<OrganizationDto>("NOT_FOUND", "Đơn vị cha không tồn tại.");
            level = parent.Level + 1;
        }
        else
            level = 1;

        var entity = new Organization
        {
            Code = request.Code,
            Name = request.Name,
            ShortName = request.ShortName,
            OrganizationTypeId = request.OrganizationTypeId,
            ParentId = request.ParentId,
            TreePath = "/", // temporary, update below
            Level = level,
            Address = request.Address,
            Phone = request.Phone,
            Email = request.Email,
            TaxCode = request.TaxCode,
            IsActive = request.IsActive,
            DisplayOrder = request.DisplayOrder,
            IsDeleted = false
        };
        _db.Organizations.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        entity.TreePath = request.ParentId.HasValue
            ? (await _db.Organizations.Where(o => o.Id == request.ParentId.Value).Select(o => o.TreePath).FirstAsync(cancellationToken)) + entity.Id + "/"
            : "/" + entity.Id + "/";
        await _db.SaveChangesAsync(cancellationToken);

        var typeCode = await _db.OrganizationTypes.Where(t => t.Id == entity.OrganizationTypeId).Select(t => t.Code).FirstAsync(cancellationToken);
        return Result.Ok(MapToDto(entity, typeCode));
    }

    public async Task<Result<OrganizationDto>> UpdateAsync(int id, UpdateOrganizationRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Organizations.FirstOrDefaultAsync(o => o.Id == id && !o.IsDeleted, cancellationToken);
        if (entity == null)
            return Result.Fail<OrganizationDto>("NOT_FOUND", "Đơn vị không tồn tại.");
        if (await _db.Organizations.AnyAsync(o => o.Code == request.Code && o.Id != id && !o.IsDeleted, cancellationToken))
            return Result.Fail<OrganizationDto>("CONFLICT", "Code đơn vị đã tồn tại.");
        var typeExists = await _db.OrganizationTypes.AnyAsync(t => t.Id == request.OrganizationTypeId, cancellationToken);
        if (!typeExists)
            return Result.Fail<OrganizationDto>("NOT_FOUND", "OrganizationType không tồn tại.");
        if (request.ParentId.HasValue && request.ParentId.Value == id)
            return Result.Fail<OrganizationDto>("VALIDATION_FAILED", "Đơn vị không thể là cha của chính nó.");
        if (request.ParentId.HasValue)
        {
            var parent = await _db.Organizations.FirstOrDefaultAsync(o => o.Id == request.ParentId.Value && !o.IsDeleted, cancellationToken);
            if (parent == null)
                return Result.Fail<OrganizationDto>("NOT_FOUND", "Đơn vị cha không tồn tại.");
            if (parent.TreePath.StartsWith(entity.TreePath) && parent.Id != entity.ParentId)
                return Result.Fail<OrganizationDto>("VALIDATION_FAILED", "Không thể chọn đơn vị con làm cha.");
        }

        entity.Code = request.Code;
        entity.Name = request.Name;
        entity.ShortName = request.ShortName;
        entity.OrganizationTypeId = request.OrganizationTypeId;
        entity.ParentId = request.ParentId;
        entity.Level = request.ParentId.HasValue
            ? (await _db.Organizations.Where(o => o.Id == request.ParentId.Value).Select(o => o.Level).FirstAsync(cancellationToken)) + 1
            : 1;
        entity.TreePath = request.ParentId.HasValue
            ? (await _db.Organizations.Where(o => o.Id == request.ParentId.Value).Select(o => o.TreePath).FirstAsync(cancellationToken)) + entity.Id + "/"
            : "/" + entity.Id + "/";
        entity.Address = request.Address;
        entity.Phone = request.Phone;
        entity.Email = request.Email;
        entity.TaxCode = request.TaxCode;
        entity.IsActive = request.IsActive;
        entity.DisplayOrder = request.DisplayOrder;
        await _db.SaveChangesAsync(cancellationToken);

        var typeCode = await _db.OrganizationTypes.Where(t => t.Id == entity.OrganizationTypeId).Select(t => t.Code).FirstAsync(cancellationToken);
        return Result.Ok(MapToDto(entity, typeCode));
    }

    public async Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Organizations.FirstOrDefaultAsync(o => o.Id == id && !o.IsDeleted, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Đơn vị không tồn tại.");
        var hasChildren = await _db.Organizations.AnyAsync(o => o.ParentId == id && !o.IsDeleted, cancellationToken);
        if (hasChildren)
            return Result.Fail<object>("CONFLICT", "Không thể xóa đơn vị còn đơn vị con.");
        entity.IsDeleted = true;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(null!);
    }


    private static OrganizationDto MapToDto(Organization o, string? typeCode) => new()
    {
        Id = o.Id,
        Code = o.Code,
        Name = o.Name,
        ShortName = o.ShortName,
        OrganizationTypeId = o.OrganizationTypeId,
        OrganizationTypeCode = typeCode,
        ParentId = o.ParentId,
        TreePath = o.TreePath,
        Level = o.Level,
        Address = o.Address,
        Phone = o.Phone,
        Email = o.Email,
        TaxCode = o.TaxCode,
        IsActive = o.IsActive,
        DisplayOrder = o.DisplayOrder
    };
}
