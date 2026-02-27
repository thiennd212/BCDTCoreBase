namespace BCDT.Application.DTOs.Form;

public class FormSheetDto
{
    public int Id { get; set; }
    public int FormDefinitionId { get; set; }
    public int SheetIndex { get; set; }
    public string SheetName { get; set; } = string.Empty;
    public string? DisplayName { get; set; }
    public string? Description { get; set; }
    public bool IsDataSheet { get; set; }
    public bool IsVisible { get; set; }
    public int DisplayOrder { get; set; }
    /// <summary>Hàng bắt đầu dữ liệu (1-based). Null = dùng mặc định từ header cột.</summary>
    public int? DataStartRow { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
