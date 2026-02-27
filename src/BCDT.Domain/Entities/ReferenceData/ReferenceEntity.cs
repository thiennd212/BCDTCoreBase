namespace BCDT.Domain.Entities.ReferenceData;

/// <summary>Thực thể tham chiếu (BCDT_ReferenceEntity). Phân cấp qua ParentId.</summary>
public class ReferenceEntity
{
    public long Id { get; set; }
    public int EntityTypeId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public long? ParentId { get; set; }
    public int? OrganizationId { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateOnly? ValidFrom { get; set; }
    public DateOnly? ValidTo { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsDeleted { get; set; }

    public ReferenceEntityType? EntityType { get; set; }
    public ReferenceEntity? Parent { get; set; }
    public ICollection<ReferenceEntity> Children { get; set; } = new List<ReferenceEntity>();
}
