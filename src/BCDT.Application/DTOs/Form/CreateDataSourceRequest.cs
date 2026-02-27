namespace BCDT.Application.DTOs.Form;

public class CreateDataSourceRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string SourceType { get; set; } = "Table"; // Catalog | Table | View | API
    public string? SourceRef { get; set; }
    public int? IndicatorCatalogId { get; set; }
    public string? DisplayColumn { get; set; }
    public string? ValueColumn { get; set; }
    public bool IsActive { get; set; } = true;
}
