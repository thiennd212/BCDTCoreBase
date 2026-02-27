namespace BCDT.Application.DTOs.Form;

public class DataSourceDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string SourceType { get; set; } = string.Empty;
    public string? SourceRef { get; set; }
    public int? IndicatorCatalogId { get; set; }
    public string? DisplayColumn { get; set; }
    public string? ValueColumn { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
