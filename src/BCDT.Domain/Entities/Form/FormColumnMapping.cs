namespace BCDT.Domain.Entities.Form;

/// <summary>Mapping cột Excel → cột lưu (BCDT_FormColumnMapping). Một FormColumn tương ứng một mapping.</summary>
public class FormColumnMapping
{
    public int Id { get; set; }
    public int FormColumnId { get; set; }
    public string TargetColumnName { get; set; } = string.Empty;
    public byte TargetColumnIndex { get; set; }
    public string? AggregateFunction { get; set; }
    public DateTime CreatedAt { get; set; }
}
