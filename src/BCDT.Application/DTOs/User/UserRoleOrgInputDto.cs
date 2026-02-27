namespace BCDT.Application.DTOs.User;

/// <summary>Một cặp (vai trò, đơn vị) khi tạo/sửa user.</summary>
public class UserRoleOrgInputDto
{
    public int RoleId { get; set; }
    public int? OrganizationId { get; set; }
}
