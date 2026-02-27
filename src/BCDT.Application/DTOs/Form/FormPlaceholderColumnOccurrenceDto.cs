namespace BCDT.Application.DTOs.Form;

public class FormPlaceholderColumnOccurrenceDto
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int FormDynamicColumnRegionId { get; set; }
    public int ExcelColStart { get; set; }
    public int? FilterDefinitionId { get; set; }
    public int DisplayOrder { get; set; }
    public int? MaxColumns { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
