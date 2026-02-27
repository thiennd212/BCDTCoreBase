namespace BCDT.Application.DTOs.User;

/// <summary>Một cặp (vai trò, đơn vị) gán cho user – dùng trả về từ API.</summary>
public class UserRoleOrgItemDto
{
    public int RoleId { get; set; }
    public string RoleCode { get; set; } = string.Empty;
    public string RoleName { get; set; } = string.Empty;
    public int? OrganizationId { get; set; }
    public string? OrganizationCode { get; set; }
    public string? OrganizationName { get; set; }
}
