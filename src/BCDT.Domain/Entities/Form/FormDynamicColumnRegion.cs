namespace BCDT.Domain.Entities.Form;

/// <summary>Định nghĩa placeholder cột (BCDT_FormDynamicColumnRegion). Một loại cột động; có thể đặt nhiều lần qua FormPlaceholderColumnOccurrence. P8e.</summary>
public class FormDynamicColumnRegion
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string ColumnSourceType { get; set; } = string.Empty; // ByReportingPeriod | ByCatalog | ByDataSource | Fixed
    public string? ColumnSourceRef { get; set; }
    public string? LabelColumn { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
