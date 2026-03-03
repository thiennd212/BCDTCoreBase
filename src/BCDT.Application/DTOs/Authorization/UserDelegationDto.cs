namespace BCDT.Application.DTOs.Authorization;

public class UserDelegationDto
{
    public int Id { get; set; }
    public int FromUserId { get; set; }
    public int ToUserId { get; set; }
    /// <summary>Full | Partial</summary>
    public string DelegationType { get; set; } = "Full";
    /// <summary>JSON array permission codes (chỉ khi Partial).</summary>
    public string? Permissions { get; set; }
    public int? OrganizationId { get; set; }
    public string? Reason { get; set; }
    public DateTime ValidFrom { get; set; }
    public DateTime ValidTo { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? RevokedAt { get; set; }
    public int? RevokedBy { get; set; }
    public string? RevokedReason { get; set; }
}

public class CreateUserDelegationRequest
{
    public int FromUserId { get; set; }
    public int ToUserId { get; set; }
    /// <summary>Full | Partial</summary>
    public string DelegationType { get; set; } = "Full";
    /// <summary>JSON array permission codes. Bắt buộc khi DelegationType = Partial.</summary>
    public string? Permissions { get; set; }
    public int? OrganizationId { get; set; }
    public string? Reason { get; set; }
    public DateTime ValidFrom { get; set; }
    public DateTime ValidTo { get; set; }
}

public class RevokeUserDelegationRequest
{
    public string? RevokedReason { get; set; }
}
