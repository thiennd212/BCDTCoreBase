namespace BCDT.Domain.Entities.Form;

/// <summary>Vùng placeholder chỉ tiêu động trong sheet (BCDT_FormDynamicRegion). R4, R11.</summary>
public class FormDynamicRegion
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int ExcelRowStart { get; set; }
    public int? ExcelRowEnd { get; set; }
    public string ExcelColName { get; set; } = string.Empty;
    public string ExcelColValue { get; set; } = string.Empty;
    public int MaxRows { get; set; } = 100;
    public int IndicatorExpandDepth { get; set; } = 1;
    public int? IndicatorCatalogId { get; set; }
    public int DisplayOrder { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
