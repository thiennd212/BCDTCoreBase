namespace BCDT.Application.DTOs.Data;

public class PutDynamicIndicatorsRequest
{
    public List<DynamicIndicatorItemRequest> Items { get; set; } = new();
}

public class DynamicIndicatorItemRequest
{
    public int FormDynamicRegionId { get; set; }
    public int RowOrder { get; set; }
    public int? IndicatorId { get; set; }
    public string IndicatorName { get; set; } = string.Empty;
    public string? IndicatorValue { get; set; }
    public string? DataType { get; set; }
}
