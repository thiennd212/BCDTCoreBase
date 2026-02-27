namespace BCDT.Application.DTOs.Form;

public class FormPlaceholderOccurrenceDto
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int FormDynamicRegionId { get; set; }
    public int ExcelRowStart { get; set; }
    public int? FilterDefinitionId { get; set; }
    public int? DataSourceId { get; set; }
    public int DisplayOrder { get; set; }
    public int? MaxRows { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
