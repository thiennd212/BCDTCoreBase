namespace BCDT.Application.DTOs.Form;

public class UpdateFormDynamicRegionRequest
{
    public int ExcelRowStart { get; set; }
    public int? ExcelRowEnd { get; set; }
    public string ExcelColName { get; set; } = string.Empty;
    public string ExcelColValue { get; set; } = string.Empty;
    public int MaxRows { get; set; }
    public int IndicatorExpandDepth { get; set; }
    public int? IndicatorCatalogId { get; set; }
    public int DisplayOrder { get; set; }
}
