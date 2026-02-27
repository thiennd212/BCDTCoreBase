namespace BCDT.Application.DTOs.User;

public class UpdateUserRequest
{
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public bool IsActive { get; set; }
    public string? NewPassword { get; set; }
    public List<int> RoleIds { get; set; } = new();
    public List<int> OrganizationIds { get; set; } = new();
    public int? PrimaryOrganizationId { get; set; }
    /// <summary>Danh sách cặp (vai trò, đơn vị). Nếu có thì dùng thay cho RoleIds/OrganizationIds.</summary>
    public List<UserRoleOrgInputDto>? RoleOrgAssignments { get; set; }
}
