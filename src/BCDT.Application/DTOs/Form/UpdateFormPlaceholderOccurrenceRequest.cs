namespace BCDT.Application.DTOs.Form;

public class UpdateFormPlaceholderOccurrenceRequest
{
    public int FormDynamicRegionId { get; set; }
    public int ExcelRowStart { get; set; }
    public int? FilterDefinitionId { get; set; }
    public int? DataSourceId { get; set; }
    public int DisplayOrder { get; set; }
    public int? MaxRows { get; set; }
}
