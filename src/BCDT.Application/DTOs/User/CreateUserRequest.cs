namespace BCDT.Application.DTOs.User;

public class CreateUserRequest
{
    public string Username { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public bool IsActive { get; set; } = true;
    public List<int> RoleIds { get; set; } = new();
    public List<int> OrganizationIds { get; set; } = new();
    public int? PrimaryOrganizationId { get; set; }
    /// <summary>Danh sách cặp (vai trò, đơn vị). Nếu có thì dùng thay cho RoleIds/OrganizationIds.</summary>
    public List<UserRoleOrgInputDto>? RoleOrgAssignments { get; set; }
}
