namespace BCDT.Application.DTOs.Permission;

/// <summary>DTO cho quyền (Permission)</summary>
public class PermissionDto
{
    public int Id { get; set; }
    /// <summary>Mã quyền</summary>
    public string Code { get; set; } = string.Empty;
    /// <summary>Tên hiển thị</summary>
    public string Name { get; set; } = string.Empty;
    /// <summary>Module (nhóm quyền)</summary>
    public string Module { get; set; } = string.Empty;
    /// <summary>Action (hành động)</summary>
    public string Action { get; set; } = string.Empty;
    /// <summary>Mô tả</summary>
    public string? Description { get; set; }
    /// <summary>Trạng thái hoạt động</summary>
    public bool IsActive { get; set; }
}

/// <summary>DTO nhóm quyền theo module</summary>
public class PermissionGroupDto
{
    /// <summary>Tên module</summary>
    public string Module { get; set; } = string.Empty;
    /// <summary>Danh sách quyền trong module</summary>
    public List<PermissionDto> Permissions { get; set; } = new();
}

/// <summary>Request gán quyền cho vai trò</summary>
public class SetRolePermissionsRequest
{
    /// <summary>Danh sách Id quyền cần gán</summary>
    public List<int> PermissionIds { get; set; } = new();
}

/// <summary>Response danh sách quyền của vai trò</summary>
public class RolePermissionsDto
{
    /// <summary>Id vai trò</summary>
    public int RoleId { get; set; }
    /// <summary>Tên vai trò</summary>
    public string RoleName { get; set; } = string.Empty;
    /// <summary>Danh sách Id quyền đã gán</summary>
    public List<int> PermissionIds { get; set; } = new();
}

/// <summary>Request tạo quyền mới</summary>
public class CreatePermissionRequest
{
    /// <summary>Mã quyền (unique)</summary>
    public string Code { get; set; } = string.Empty;
    /// <summary>Tên hiển thị</summary>
    public string Name { get; set; } = string.Empty;
    /// <summary>Module (nhóm quyền)</summary>
    public string Module { get; set; } = string.Empty;
    /// <summary>Action (hành động)</summary>
    public string Action { get; set; } = string.Empty;
    /// <summary>Mô tả</summary>
    public string? Description { get; set; }
    /// <summary>Trạng thái hoạt động</summary>
    public bool IsActive { get; set; } = true;
}

/// <summary>Request cập nhật quyền</summary>
public class UpdatePermissionRequest
{
    /// <summary>Tên hiển thị</summary>
    public string Name { get; set; } = string.Empty;
    /// <summary>Module (nhóm quyền)</summary>
    public string Module { get; set; } = string.Empty;
    /// <summary>Action (hành động)</summary>
    public string Action { get; set; } = string.Empty;
    /// <summary>Mô tả</summary>
    public string? Description { get; set; }
    /// <summary>Trạng thái hoạt động</summary>
    public bool IsActive { get; set; } = true;
}
