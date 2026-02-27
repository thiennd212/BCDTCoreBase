namespace BCDT.Application.DTOs.Role;

/// <summary>DTO cho vai trò (Role)</summary>
public class RoleDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int Level { get; set; }
    public bool IsSystem { get; set; }
    public bool IsActive { get; set; }
    public DateTime? CreatedAt { get; set; }
    /// <summary>Số lượng user đang có vai trò này</summary>
    public int UserCount { get; set; }
}

/// <summary>Request tạo vai trò mới</summary>
public class CreateRoleRequest
{
    /// <summary>Mã vai trò (unique, vd: DATA_ENTRY)</summary>
    public string Code { get; set; } = string.Empty;
    /// <summary>Tên vai trò</summary>
    public string Name { get; set; } = string.Empty;
    /// <summary>Mô tả</summary>
    public string? Description { get; set; }
    /// <summary>Cấp độ vai trò (1=cao nhất)</summary>
    public int Level { get; set; } = 100;
    /// <summary>Trạng thái hoạt động</summary>
    public bool IsActive { get; set; } = true;
}

/// <summary>Request cập nhật vai trò</summary>
public class UpdateRoleRequest
{
    /// <summary>Tên vai trò</summary>
    public string Name { get; set; } = string.Empty;
    /// <summary>Mô tả</summary>
    public string? Description { get; set; }
    /// <summary>Cấp độ vai trò</summary>
    public int Level { get; set; }
    /// <summary>Trạng thái hoạt động</summary>
    public bool IsActive { get; set; } = true;
}
