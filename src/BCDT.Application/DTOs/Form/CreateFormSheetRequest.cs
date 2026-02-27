namespace BCDT.Application.DTOs.Form;

public class CreateFormSheetRequest
{
    public int SheetIndex { get; set; }
    public string SheetName { get; set; } = string.Empty;
    public string? DisplayName { get; set; }
    public string? Description { get; set; }
    public bool IsDataSheet { get; set; } = true;
    public bool IsVisible { get; set; } = true;
    public int DisplayOrder { get; set; }
    /// <summary>Hàng bắt đầu dữ liệu (1-based). Để trống = tự động từ header cột.</summary>
    public int? DataStartRow { get; set; }
}
