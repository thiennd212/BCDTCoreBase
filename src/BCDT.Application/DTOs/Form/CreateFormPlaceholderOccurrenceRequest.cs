namespace BCDT.Application.DTOs.Form;

public class CreateFormPlaceholderOccurrenceRequest
{
    public int FormDynamicRegionId { get; set; }
    public int ExcelRowStart { get; set; }
    public int? FilterDefinitionId { get; set; }
    public int? DataSourceId { get; set; }
    public int DisplayOrder { get; set; }
    public int? MaxRows { get; set; }
}
