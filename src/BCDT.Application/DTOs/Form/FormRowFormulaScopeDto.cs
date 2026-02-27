namespace BCDT.Application.DTOs.Form;

public class FormRowFormulaScopeDto
{
    public int Id { get; set; }
    public int FormRowId { get; set; }
    public int FormColumnId { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}

public class CreateFormRowFormulaScopeRequest
{
    public int FormColumnId { get; set; }
}
