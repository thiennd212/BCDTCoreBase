namespace BCDT.Domain.Entities.Form;

/// <summary>Nguồn dữ liệu cho lọc động (BCDT_DataSource). P8a.</summary>
public class DataSource
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string SourceType { get; set; } = string.Empty; // Catalog | Table | View | API
    public string? SourceRef { get; set; }
    public int? IndicatorCatalogId { get; set; }
    public string? DisplayColumn { get; set; }
    public string? ValueColumn { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
