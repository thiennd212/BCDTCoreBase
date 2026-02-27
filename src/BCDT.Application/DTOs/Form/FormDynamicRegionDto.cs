namespace BCDT.Application.DTOs.Form;

public class FormDynamicRegionDto
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int ExcelRowStart { get; set; }
    public int? ExcelRowEnd { get; set; }
    public string ExcelColName { get; set; } = string.Empty;
    public string ExcelColValue { get; set; } = string.Empty;
    public int MaxRows { get; set; }
    public int IndicatorExpandDepth { get; set; }
    public int? IndicatorCatalogId { get; set; }
    public int DisplayOrder { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
