namespace BCDT.Domain.Entities.Authorization;

/// <summary>Gán quyền cho vai trò (BCDT_RolePermission)</summary>
public class RolePermission
{
    public int Id { get; set; }
    /// <summary>Id vai trò</summary>
    public int RoleId { get; set; }
    /// <summary>Id quyền</summary>
    public int PermissionId { get; set; }
    /// <summary>Thời điểm tạo</summary>
    public DateTime CreatedAt { get; set; }
    /// <summary>Người tạo (UserId)</summary>
    public int CreatedBy { get; set; }
    
    // Navigation properties
    public virtual Role? Role { get; set; }
    public virtual Permission? Permission { get; set; }
}
