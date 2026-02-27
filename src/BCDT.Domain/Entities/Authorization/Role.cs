namespace BCDT.Domain.Entities.Authorization;

/// <summary>Vai trò (BCDT_Role). Code: SYSTEM_ADMIN, FORM_ADMIN, UNIT_ADMIN, DATA_ENTRY, VIEWER.</summary>
public class Role
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public int Level { get; set; }
    public bool IsSystem { get; set; }
    public bool IsActive { get; set; } = true;
}
