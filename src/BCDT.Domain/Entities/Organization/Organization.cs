namespace BCDT.Domain.Entities.Organization;

/// <summary>Đơn vị (BCDT_Organization). Cây 5 cấp: ParentId, TreePath, Level.</summary>
public class Organization
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? ShortName { get; set; }
    public int OrganizationTypeId { get; set; }
    public int? ParentId { get; set; }
    public string TreePath { get; set; } = string.Empty;
    public int Level { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? TaxCode { get; set; }
    public bool IsActive { get; set; } = true;
    public int DisplayOrder { get; set; }
    public bool IsDeleted { get; set; }
}
