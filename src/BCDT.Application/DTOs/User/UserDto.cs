namespace BCDT.Application.DTOs.User;

public class UserDto
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public bool IsActive { get; set; }
    public List<int> RoleIds { get; set; } = new();
    public List<int> OrganizationIds { get; set; } = new();
    public int? PrimaryOrganizationId { get; set; }
    /// <summary>Danh sách cặp (vai trò, đơn vị) – nguồn chính khi có; RoleIds/OrganizationIds lấy từ đây.</summary>
    public List<UserRoleOrgItemDto> RoleOrgAssignments { get; set; } = new();
}
