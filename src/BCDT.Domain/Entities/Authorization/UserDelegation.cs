namespace BCDT.Domain.Entities.Authorization;

/// <summary>Ủy quyền tạm thời giữa 2 user (BCDT_UserDelegation). DelegationType: Full, Partial.</summary>
public class UserDelegation
{
    public int Id { get; set; }
    /// <summary>Người ủy quyền.</summary>
    public int FromUserId { get; set; }
    /// <summary>Người được ủy quyền.</summary>
    public int ToUserId { get; set; }
    /// <summary>Full = toàn bộ quyền; Partial = chỉ các quyền trong Permissions.</summary>
    public string DelegationType { get; set; } = "Full";
    /// <summary>JSON array permission codes, chỉ dùng khi DelegationType = Partial. Vd: ["Form.Edit","Submission.Submit"]</summary>
    public string? Permissions { get; set; }
    /// <summary>Scope đơn vị. Null = toàn hệ thống.</summary>
    public int? OrganizationId { get; set; }
    public string? Reason { get; set; }
    public DateTime ValidFrom { get; set; }
    public DateTime ValidTo { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? RevokedAt { get; set; }
    public int? RevokedBy { get; set; }
    public string? RevokedReason { get; set; }
}
