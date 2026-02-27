using System.Security.Claims;
using BCDT.Application.Common.Authorization;
using BCDT.Infrastructure.Persistence;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Authorization;

/// <summary>Checks that the current user has the required permission (BCDT_Permission.Code) via BCDT_UserRole and BCDT_RolePermission.</summary>
public class PermissionAuthorizationHandler : AuthorizationHandler<PermissionRequirement>
{
    private readonly AppDbContext _db;

    public PermissionAuthorizationHandler(AppDbContext db)
    {
        _db = db;
    }

    protected override async Task HandleRequirementAsync(
        AuthorizationHandlerContext context,
        PermissionRequirement requirement)
    {
        var userIdClaim = context.User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return;

        var hasPermission = await _db.UserRoles
            .AsNoTracking()
            .Where(ur => ur.UserId == userId && ur.IsActive
                && (ur.ValidTo == null || ur.ValidTo > DateTime.UtcNow))
            .Join(_db.RolePermissions.AsNoTracking(), ur => ur.RoleId, rp => rp.RoleId, (ur, rp) => rp)
            .Join(_db.Permissions.AsNoTracking(), rp => rp.PermissionId, p => p.Id, (rp, p) => p)
            .AnyAsync(p => p.IsActive && p.Code == requirement.Permission);

        if (hasPermission)
            context.Succeed(requirement);
    }
}
