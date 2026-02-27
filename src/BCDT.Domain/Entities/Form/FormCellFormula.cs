namespace BCDT.Domain.Entities.Form;

/// <summary>Override formula/IsEditable tại giao điểm cột × hàng (BCDT_FormCellFormula).
/// Priority inject: FormCellFormula (highest) > FormRow.Formula > FormColumn.Formula (lowest).
/// IsEditable: null = inherit; false = lock cell dù col/row IsEditable=true.</summary>
public class FormCellFormula
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int FormColumnId { get; set; }
    public int FormRowId { get; set; }
    public string? Formula { get; set; }
    public bool? IsEditable { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
