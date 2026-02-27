namespace BCDT.Application.DTOs.Data;

public class ReportDynamicIndicatorItemDto
{
    public long Id { get; set; }
    public int FormDynamicRegionId { get; set; }
    public int RowOrder { get; set; }
    public int? IndicatorId { get; set; }
    public string IndicatorName { get; set; } = string.Empty;
    public string? IndicatorValue { get; set; }
    public string? DataType { get; set; }
}
