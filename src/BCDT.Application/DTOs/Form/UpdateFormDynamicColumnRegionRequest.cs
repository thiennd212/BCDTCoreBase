namespace BCDT.Application.DTOs.Form;

public class UpdateFormDynamicColumnRegionRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string ColumnSourceType { get; set; } = string.Empty;
    public string? ColumnSourceRef { get; set; }
    public string? LabelColumn { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
}
