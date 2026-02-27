using Microsoft.AspNetCore.Authorization;

namespace BCDT.Application.Common.Authorization;

/// <summary>Authorization requirement: user must have the given permission (BCDT_Permission.Code) via RolePermission.</summary>
public class PermissionRequirement : IAuthorizationRequirement
{
    public string Permission { get; }

    public PermissionRequirement(string permission)
    {
        Permission = permission;
    }
}
