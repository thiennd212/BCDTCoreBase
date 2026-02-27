namespace BCDT.Application.DTOs.Form;

public class CreateFormPlaceholderColumnOccurrenceRequest
{
    public int FormDynamicColumnRegionId { get; set; }
    public int ExcelColStart { get; set; }
    public int? FilterDefinitionId { get; set; }
    public int DisplayOrder { get; set; }
    public int? MaxColumns { get; set; }
}
