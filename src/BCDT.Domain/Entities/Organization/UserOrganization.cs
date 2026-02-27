namespace BCDT.Domain.Entities.Organization;

/// <summary>User ↔ Organization mapping (BCDT_UserOrganization).</summary>
public class UserOrganization
{
    public int Id { get; set; }
    public int UserId { get; set; }
    public int OrganizationId { get; set; }
    public bool IsPrimary { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime JoinedAt { get; set; }
    public DateTime? LeftAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
