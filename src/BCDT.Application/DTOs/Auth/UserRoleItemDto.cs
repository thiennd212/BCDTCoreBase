namespace BCDT.Application.DTOs.Auth;

/// <summary>Vai trò của user (dùng cho dropdown chuyển vai trò)</summary>
public class UserRoleItemDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    /// <summary>Đơn vị gắn với vai trò (nếu có) – dùng cho chuyển vai trò hiển thị "Vai trò (Đơn vị)".</summary>
    public int? OrganizationId { get; set; }
    public string? OrganizationName { get; set; }
}
