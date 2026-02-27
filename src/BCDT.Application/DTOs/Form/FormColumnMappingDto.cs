namespace BCDT.Application.DTOs.Form;

public class FormColumnMappingDto
{
    public int Id { get; set; }
    public int FormColumnId { get; set; }
    public string TargetColumnName { get; set; } = string.Empty;
    public int TargetColumnIndex { get; set; }
    public string? AggregateFunction { get; set; }
    public DateTime CreatedAt { get; set; }
}
