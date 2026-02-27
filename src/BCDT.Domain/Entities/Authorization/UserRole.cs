namespace BCDT.Domain.Entities.Authorization;

/// <summary>Gán vai trò cho user (BCDT_UserRole). Có thể theo đơn vị (OrganizationId).</summary>
public class UserRole
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int RoleId { get; set; }
    public int? OrganizationId { get; set; }
    public DateTime ValidFrom { get; set; }
    public DateTime? ValidTo { get; set; }
    public bool IsActive { get; set; } = true;
    public int GrantedBy { get; set; }
    public DateTime GrantedAt { get; set; }
}
