namespace BCDT.Application.DTOs.Form;

public class UpdateFormSheetRequest
{
    public int SheetIndex { get; set; }
    public string SheetName { get; set; } = string.Empty;
    public string? DisplayName { get; set; }
    public string? Description { get; set; }
    public bool IsDataSheet { get; set; }
    public bool IsVisible { get; set; }
    public int DisplayOrder { get; set; }
    public int? DataStartRow { get; set; }
}
