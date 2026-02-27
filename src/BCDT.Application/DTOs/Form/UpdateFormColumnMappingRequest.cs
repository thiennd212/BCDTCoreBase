namespace BCDT.Application.DTOs.Form;

public class UpdateFormColumnMappingRequest
{
    public string TargetColumnName { get; set; } = string.Empty;
    public int TargetColumnIndex { get; set; }
    public string? AggregateFunction { get; set; }
}
