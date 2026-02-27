namespace BCDT.Application.DTOs.ReferenceEntity;

public class ReferenceEntityDto
{
    public long Id { get; set; }
    public int EntityTypeId { get; set; }
    public string? EntityTypeCode { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public long? ParentId { get; set; }
    public string? ParentName { get; set; }
    public int? OrganizationId { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public DateOnly? ValidFrom { get; set; }
    public DateOnly? ValidTo { get; set; }
    public DateTime CreatedAt { get; set; }
}
