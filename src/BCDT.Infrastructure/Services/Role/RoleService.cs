using BCDT.Application.Common;
using BCDT.Application.DTOs.Role;
using BCDT.Application.Services.Role;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Role;

/// <summary>Service quản lý vai trò (Role)</summary>
public class RoleService : IRoleService
{
    private readonly AppDbContext _db;

    public RoleService(AppDbContext db) => _db = db;

    public async Task<Result<List<RoleDto>>> GetAllAsync(bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var query = _db.Roles.AsNoTracking();
        if (!includeInactive)
            query = query.Where(x => x.IsActive);

        var roles = await query.OrderBy(x => x.Level).ThenBy(x => x.Code).ToListAsync(cancellationToken);

        // Count users per role
        var roleIds = roles.Select(r => r.Id).ToList();
        var userCounts = await _db.UserRoles
            .Where(ur => roleIds.Contains(ur.RoleId) && ur.IsActive)
            .GroupBy(ur => ur.RoleId)
            .Select(g => new { RoleId = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.RoleId, x => x.Count, cancellationToken);

        var list = roles.Select(x => MapToDto(x, userCounts.GetValueOrDefault(x.Id, 0))).ToList();
        return Result.Ok(list);
    }

    public async Task<Result<RoleDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Roles.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null) return Result.Ok<RoleDto?>(null);

        var userCount = await _db.UserRoles.CountAsync(ur => ur.RoleId == id && ur.IsActive, cancellationToken);
        return Result.Ok<RoleDto?>(MapToDto(entity, userCount));
    }

    public async Task<Result<RoleDto>> CreateAsync(CreateRoleRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        // Validate Code unique
        var codeNormalized = request.Code.Trim().ToUpperInvariant();
        var exists = await _db.Roles.AnyAsync(x => x.Code == codeNormalized, cancellationToken);
        if (exists)
            return Result.Fail<RoleDto>("CONFLICT", "Mã vai trò đã tồn tại.");

        var entity = new Domain.Entities.Authorization.Role
        {
            Code = codeNormalized,
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            Level = request.Level,
            IsSystem = false, // New roles are not system roles
            IsActive = request.IsActive
        };

        _db.Roles.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity, 0));
    }

    public async Task<Result<RoleDto>> UpdateAsync(int id, UpdateRoleRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Roles.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<RoleDto>("NOT_FOUND", "Vai trò không tồn tại.");

        // Cannot modify system roles
        if (entity.IsSystem)
            return Result.Fail<RoleDto>("FORBIDDEN", "Không thể sửa vai trò hệ thống.");

        entity.Name = request.Name.Trim();
        entity.Description = request.Description?.Trim();
        entity.Level = request.Level;
        entity.IsActive = request.IsActive;

        await _db.SaveChangesAsync(cancellationToken);

        var userCount = await _db.UserRoles.CountAsync(ur => ur.RoleId == id && ur.IsActive, cancellationToken);
        return Result.Ok(MapToDto(entity, userCount));
    }

    public async Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Roles.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Vai trò không tồn tại.");

        // Cannot delete system roles
        if (entity.IsSystem)
            return Result.Fail<object>("FORBIDDEN", "Không thể xóa vai trò hệ thống.");

        // Check if role is being used by users
        var hasUsers = await _db.UserRoles.AnyAsync(ur => ur.RoleId == id && ur.IsActive, cancellationToken);
        if (hasUsers)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa vai trò đang được gán cho người dùng.");

        // Delete associated role permissions
        var rolePermissions = await _db.RolePermissions.Where(rp => rp.RoleId == id).ToListAsync(cancellationToken);
        if (rolePermissions.Any())
        {
            _db.RolePermissions.RemoveRange(rolePermissions);
        }

        _db.Roles.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static RoleDto MapToDto(Domain.Entities.Authorization.Role x, int userCount) => new()
    {
        Id = x.Id,
        Code = x.Code,
        Name = x.Name,
        Description = x.Description,
        Level = x.Level,
        IsSystem = x.IsSystem,
        IsActive = x.IsActive,
        CreatedAt = null, // Role entity doesn't have CreatedAt yet
        UserCount = userCount
    };
}
