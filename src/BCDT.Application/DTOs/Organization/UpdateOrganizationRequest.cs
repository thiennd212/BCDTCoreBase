namespace BCDT.Application.DTOs.Organization;

public class UpdateOrganizationRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? ShortName { get; set; }
    public int OrganizationTypeId { get; set; }
    public int? ParentId { get; set; }
    public string? Address { get; set; }
    public string? Phone { get; set; }
    public string? Email { get; set; }
    public string? TaxCode { get; set; }
    public bool IsActive { get; set; }
    public int DisplayOrder { get; set; }
}
