namespace BCDT.Domain.Entities.Form;

/// <summary>Vị trí placeholder dòng trên template (BCDT_FormPlaceholderOccurrence). Một dòng = một occurrence. P8a.</summary>
public class FormPlaceholderOccurrence
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
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
