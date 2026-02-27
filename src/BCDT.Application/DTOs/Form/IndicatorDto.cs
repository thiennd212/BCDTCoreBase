namespace BCDT.Application.DTOs.Form;

public class IndicatorDto
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
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }

    /// <summary>Chỉ tiêu con (tree mode)</summary>
    public List<IndicatorDto>? Children { get; set; }
}
