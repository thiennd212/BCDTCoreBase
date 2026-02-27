namespace BCDT.Domain.Entities.Authentication;

public class User
{
    public int Id { get; set; }
    public string Username { get; set; } = string.Empty;
    public string? PasswordHash { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string? Phone { get; set; }
    public string? Avatar { get; set; }
    public string AuthProvider { get; set; } = "BuiltIn";
    public string? ExternalId { get; set; }
    public DateTime? LastSyncFromExternalAt { get; set; }
    public int FailedLoginAttempts { get; set; }
    public DateTime? LockoutEnd { get; set; }
    public DateTime? PasswordChangedAt { get; set; }
    public bool MustChangePassword { get; set; }
    public bool TwoFactorEnabled { get; set; }
    public string? TwoFactorProvider { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime? LastLoginAt { get; set; }
    /// <summary>Thời điểm logout gần nhất; access token có iat &lt; LastLogoutAt sẽ bị từ chối.</summary>
    public DateTime? LastLogoutAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsDeleted { get; set; }
}
