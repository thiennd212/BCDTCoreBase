namespace BCDT.Domain.Entities.Form;

/// <summary>Sheet trong workbook (BCDT_FormSheet). FormDefinition → FormSheet.</summary>
public class FormSheet
{
    public int Id { get; set; }
    public int FormDefinitionId { get; set; }
    public byte SheetIndex { get; set; }
    public string SheetName { get; set; } = string.Empty;
    public string? DisplayName { get; set; }
    public string? Description { get; set; }
    public bool IsDataSheet { get; set; } = true;
    public bool IsVisible { get; set; } = true;
    public int DisplayOrder { get; set; }
    /// <summary>Hàng bắt đầu dữ liệu (1-based). Null = dùng mặc định từ template hoặc 2.</summary>
    public int? DataStartRow { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
