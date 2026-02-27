namespace BCDT.Domain.Entities.Form;

/// <summary>Chỉ tiêu master – cố định hoặc thuộc danh mục (BCDT_Indicator). R6, R10.</summary>
public class Indicator
{
    public int Id { get; set; }
    public int? IndicatorCatalogId { get; set; }
    public int? ParentId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string DataType { get; set; } = "Text";
    public string? Unit { get; set; }
    public string? FormulaTemplate { get; set; }
    public string? ValidationRule { get; set; }
    public string? DefaultValue { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
