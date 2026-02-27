namespace BCDT.Application.DTOs.Form;

public class FormCellFormulaDto
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
