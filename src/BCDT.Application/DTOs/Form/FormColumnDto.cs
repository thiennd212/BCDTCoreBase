namespace BCDT.Application.DTOs.Form;

public class FormColumnDto
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int? ParentId { get; set; }
    public int IndicatorId { get; set; }
    public string ColumnCode { get; set; } = string.Empty;
    public string ColumnName { get; set; } = string.Empty;
    public string? ColumnGroupName { get; set; }
    public string? ColumnGroupLevel2 { get; set; }
    public string? ColumnGroupLevel3 { get; set; }
    public string? ColumnGroupLevel4 { get; set; }
    public string? ExcelColumn { get; set; }
    public int LayoutOrder { get; set; }
    public string DataType { get; set; } = "Text";
    public bool IsRequired { get; set; }
    public bool IsEditable { get; set; }
    public bool IsHidden { get; set; }
    public string? DefaultValue { get; set; }
    public string? Formula { get; set; }
    public string? ValidationRule { get; set; }
    public string? ValidationMessage { get; set; }
    public int DisplayOrder { get; set; }
    public int? Width { get; set; }
    public string? Format { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
