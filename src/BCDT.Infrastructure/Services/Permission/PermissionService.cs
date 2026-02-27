using BCDT.Application.Common;
using BCDT.Application.DTOs.Permission;
using BCDT.Application.Services.Permission;
using BCDT.Domain.Entities.Authorization;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Permission;

/// <summary>Service quản lý quyền (Permission)</summary>
public class PermissionService : IPermissionService
{
    private readonly AppDbContext _db;

    public PermissionService(AppDbContext db) => _db = db;

    public async Task<Result<List<PermissionGroupDto>>> GetAllPermissionsAsync(CancellationToken cancellationToken = default)
    {
        var permissions = await _db.Permissions
            .AsNoTracking()
            .Where(p => p.IsActive)
            .OrderBy(p => p.Module)
            .ThenBy(p => p.Action)
            .ThenBy(p => p.Code)
            .ToListAsync(cancellationToken);

        var grouped = permissions
            .GroupBy(p => p.Module)
            .Select(g => new PermissionGroupDto
            {
                Module = g.Key,
                Permissions = g.Select(MapToDto).ToList()
            })
            .ToList();

        return Result.Ok(grouped);
    }

    public async Task<Result<List<PermissionDto>>> GetAllFlatAsync(CancellationToken cancellationToken = default)
    {
        var permissions = await _db.Permissions
            .AsNoTracking()
            .OrderBy(p => p.Module)
            .ThenBy(p => p.Action)
            .ThenBy(p => p.Code)
            .ToListAsync(cancellationToken);

        return Result.Ok(permissions.Select(MapToDto).ToList());
    }

    public async Task<Result<PermissionDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var permission = await _db.Permissions
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        
        if (permission == null)
            return Result.Ok<PermissionDto?>(null);
        
        return Result.Ok<PermissionDto?>(MapToDto(permission));
    }

    public async Task<Result<PermissionDto>> CreateAsync(CreatePermissionRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        // Check code unique
        if (await _db.Permissions.AnyAsync(p => p.Code == request.Code, cancellationToken))
            return Result.Fail<PermissionDto>("CONFLICT", "Mã quyền đã tồn tại.");

        var permission = new Domain.Entities.Authorization.Permission
        {
            Code = request.Code,
            Name = request.Name,
            Module = request.Module,
            Action = request.Action,
            Description = request.Description,
            IsActive = request.IsActive
        };

        _db.Permissions.Add(permission);
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok(MapToDto(permission));
    }

    public async Task<Result<PermissionDto>> UpdateAsync(int id, UpdatePermissionRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var permission = await _db.Permissions.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (permission == null)
            return Result.Fail<PermissionDto>("NOT_FOUND", "Quyền không tồn tại.");

        permission.Name = request.Name;
        permission.Module = request.Module;
        permission.Action = request.Action;
        permission.Description = request.Description;
        permission.IsActive = request.IsActive;

        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok(MapToDto(permission));
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var permission = await _db.Permissions.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (permission == null)
            return Result.Fail<object>("NOT_FOUND", "Quyền không tồn tại.");

        // Check if permission is assigned to any role
        var isUsed = await _db.RolePermissions.AnyAsync(rp => rp.PermissionId == id, cancellationToken);
        if (isUsed)
            return Result.Fail<object>("CONFLICT", "Quyền đang được gán cho vai trò, không thể xóa.");

        _db.Permissions.Remove(permission);
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok<object>(null!);
    }

    public async Task<Result<RolePermissionsDto>> GetPermissionsByRoleIdAsync(int roleId, CancellationToken cancellationToken = default)
    {
        var role = await _db.Roles.AsNoTracking().FirstOrDefaultAsync(r => r.Id == roleId, cancellationToken);
        if (role == null)
            return Result.Fail<RolePermissionsDto>("NOT_FOUND", "Vai trò không tồn tại.");

        var permissionIds = await _db.RolePermissions
            .AsNoTracking()
            .Where(rp => rp.RoleId == roleId)
            .Select(rp => rp.PermissionId)
            .ToListAsync(cancellationToken);

        return Result.Ok(new RolePermissionsDto
        {
            RoleId = role.Id,
            RoleName = role.Name,
            PermissionIds = permissionIds
        });
    }

    public async Task<Result<RolePermissionsDto>> SetRolePermissionsAsync(int roleId, List<int> permissionIds, int grantedBy, CancellationToken cancellationToken = default)
    {
        var role = await _db.Roles.FirstOrDefaultAsync(r => r.Id == roleId, cancellationToken);
        if (role == null)
            return Result.Fail<RolePermissionsDto>("NOT_FOUND", "Vai trò không tồn tại.");

        // Validate permission IDs exist
        var validPermissionIds = await _db.Permissions
            .Where(p => permissionIds.Contains(p.Id) && p.IsActive)
            .Select(p => p.Id)
            .ToListAsync(cancellationToken);

        var invalidIds = permissionIds.Except(validPermissionIds).ToList();
        if (invalidIds.Any())
            return Result.Fail<RolePermissionsDto>("VALIDATION_FAILED", $"Quyền không tồn tại: {string.Join(", ", invalidIds)}");

        // Get current role permissions
        var currentPermissions = await _db.RolePermissions
            .Where(rp => rp.RoleId == roleId)
            .ToListAsync(cancellationToken);

        var currentIds = currentPermissions.Select(rp => rp.PermissionId).ToHashSet();
        var newIds = permissionIds.ToHashSet();

        // Permissions to remove (hard delete since no IsActive column)
        var toRemove = currentPermissions.Where(rp => !newIds.Contains(rp.PermissionId)).ToList();
        if (toRemove.Any())
        {
            _db.RolePermissions.RemoveRange(toRemove);
        }

        // Permissions to add
        var toAdd = newIds.Except(currentIds);
        var now = DateTime.UtcNow;
        foreach (var permId in toAdd)
        {
            _db.RolePermissions.Add(new RolePermission
            {
                RoleId = roleId,
                PermissionId = permId,
                CreatedAt = now,
                CreatedBy = grantedBy
            });
        }

        await _db.SaveChangesAsync(cancellationToken);

        // Return updated permissions
        var updatedPermissionIds = await _db.RolePermissions
            .AsNoTracking()
            .Where(rp => rp.RoleId == roleId)
            .Select(rp => rp.PermissionId)
            .ToListAsync(cancellationToken);

        return Result.Ok(new RolePermissionsDto
        {
            RoleId = role.Id,
            RoleName = role.Name,
            PermissionIds = updatedPermissionIds
        });
    }

    private static PermissionDto MapToDto(Domain.Entities.Authorization.Permission p) => new()
    {
        Id = p.Id,
        Code = p.Code,
        Name = p.Name,
        Module = p.Module,
        Action = p.Action,
        Description = p.Description,
        IsActive = p.IsActive
    };
}
