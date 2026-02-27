namespace BCDT.Application.DTOs.Form;

public class CreateFormDynamicRegionRequest
{
    public int ExcelRowStart { get; set; }
    public int? ExcelRowEnd { get; set; }
    public string ExcelColName { get; set; } = string.Empty;
    public string ExcelColValue { get; set; } = string.Empty;
    public int MaxRows { get; set; } = 100;
    public int IndicatorExpandDepth { get; set; } = 1;
    public int? IndicatorCatalogId { get; set; }
    public int DisplayOrder { get; set; }
}
