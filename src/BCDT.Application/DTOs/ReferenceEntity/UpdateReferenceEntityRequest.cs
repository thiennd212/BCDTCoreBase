namespace BCDT.Application.DTOs.ReferenceEntity;

public class UpdateReferenceEntityRequest
{
    public string Name { get; set; } = string.Empty;
    public long? ParentId { get; set; }
    public int? OrganizationId { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public DateOnly? ValidFrom { get; set; }
    public DateOnly? ValidTo { get; set; }
}
