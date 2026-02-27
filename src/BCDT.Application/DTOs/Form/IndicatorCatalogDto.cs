namespace BCDT.Application.DTOs.Form;

public class IndicatorCatalogDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Scope { get; set; } = "Global";
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public int IndicatorCount { get; set; }
}
