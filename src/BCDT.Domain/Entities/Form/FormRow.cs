namespace BCDT.Domain.Entities.Form;

/// <summary>Hàng trong sheet (BCDT_FormRow). RowType: Header, Data, Total, Static. Phân cấp qua ParentRowId.</summary>
public class FormRow
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public string? RowCode { get; set; }
    public string? RowName { get; set; }
    public int ExcelRowStart { get; set; }
    public int? ExcelRowEnd { get; set; }
    public string RowType { get; set; } = "Data"; // Header, Data, Total, Static
    public bool IsRepeating { get; set; }
    public int? ReferenceEntityTypeId { get; set; }
    public int? ParentRowId { get; set; }
    public int? FormDynamicRegionId { get; set; }
    public int DisplayOrder { get; set; }
    public int? Height { get; set; }
    /// <summary>Hàng có cho phép nhập dữ liệu không. false = Fortune Sheet cell read-only.</summary>
    public bool IsEditable { get; set; } = true;
    /// <summary>Bắt buộc nhập dữ liệu cho hàng này.</summary>
    public bool IsRequired { get; set; }
    /// <summary>Công thức cấp hàng (placeholder-based). Kết hợp với FormRowFormulaScope để xác định cột áp dụng.</summary>
    public string? Formula { get; set; }
    /// <summary>Liên kết tới Indicator trong danh mục dùng chung. null = hàng tự định nghĩa.</summary>
    public int? IndicatorId { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
