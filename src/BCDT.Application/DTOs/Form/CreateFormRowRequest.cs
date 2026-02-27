namespace BCDT.Application.DTOs.Form;

public class CreateFormRowRequest
{
    public string? RowCode { get; set; }
    public string? RowName { get; set; }
    public int ExcelRowStart { get; set; }
    public int? ExcelRowEnd { get; set; }
    public string RowType { get; set; } = "Data";
    public bool IsRepeating { get; set; }
    public int? ReferenceEntityTypeId { get; set; }
    public int? ParentId { get; set; }
    public int? FormDynamicRegionId { get; set; }
    public int DisplayOrder { get; set; }
    public int? Height { get; set; }
    public bool IsEditable { get; set; } = true;
    public bool IsRequired { get; set; }
    public string? Formula { get; set; }
    public int? IndicatorId { get; set; }
}
