namespace BCDT.Domain.Entities.Form;

/// <summary>Chọn cột áp dụng row formula (BCDT_FormRowFormulaScope).
/// Khi FormRow.Formula != null: nếu có records → inject chỉ vào cột được chọn; không có → inject tất cả cột IsEditable Number/Formula.</summary>
public class FormRowFormulaScope
{
    public int Id { get; set; }
    public int FormRowId { get; set; }
    public int FormColumnId { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
