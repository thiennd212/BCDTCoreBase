namespace BCDT.Domain.Entities.Authorization;

/// <summary>Phân quyền menu theo vai trò (BCDT_RoleMenu)</summary>
public class RoleMenu
{
    public int Id { get; set; }
    public int RoleId { get; set; }
    public int MenuId { get; set; }
    public bool CanView { get; set; }
    public bool CanCreate { get; set; }
    public bool CanEdit { get; set; }
    public bool CanDelete { get; set; }
    public bool CanExport { get; set; }
    public bool CanApprove { get; set; }

    // Navigation
    public Role? Role { get; set; }
    public Menu? Menu { get; set; }
}
