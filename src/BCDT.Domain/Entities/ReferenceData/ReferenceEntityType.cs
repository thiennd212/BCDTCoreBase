namespace BCDT.Domain.Entities.ReferenceData;

/// <summary>Loại thực thể tham chiếu (BCDT_ReferenceEntityType).</summary>
public class ReferenceEntityType
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string? TableName { get; set; }
    public string? ApiEndpoint { get; set; }
    public string? DisplayTemplate { get; set; }
    public string? SearchColumns { get; set; }
    public string? OrderByColumn { get; set; }
    public bool IsSystem { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
