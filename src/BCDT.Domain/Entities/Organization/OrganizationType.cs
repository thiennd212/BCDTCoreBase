namespace BCDT.Domain.Entities.Organization;

/// <summary>Loại đơn vị (BCDT_OrganizationType). Level 1–5: Bộ, Tỉnh, Cấp 3, 4, 5.</summary>
public class OrganizationType
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int Level { get; set; }
    public int? ParentTypeId { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
}
