namespace BCDT.Application.DTOs.Form;

public class CreateFormCellFormulaRequest
{
    public int FormColumnId { get; set; }
    public int FormRowId { get; set; }
    public string? Formula { get; set; }
    public bool? IsEditable { get; set; }
}
