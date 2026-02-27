namespace BCDT.Domain.Entities.Form;

/// <summary>Cột / tiêu chí trong sheet (BCDT_FormColumn). DataType: Text, Number, Date, Formula, Reference, Boolean.</summary>
public class FormColumn
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int? ParentId { get; set; }
    public int IndicatorId { get; set; }
    public string ColumnCode { get; set; } = string.Empty;
    public string ColumnName { get; set; } = string.Empty;
    /// <summary>Nhóm cột tầng 1 (header cha) cho phân cấp Excel. Cùng nhóm sẽ gộp ô ở hàng header.</summary>
    public string? ColumnGroupName { get; set; }
    /// <summary>Nhóm cột tầng 2 (header con). Null = không dùng tầng 2.</summary>
    public string? ColumnGroupLevel2 { get; set; }
    /// <summary>Nhóm cột tầng 3. Null = không dùng tầng 3.</summary>
    public string? ColumnGroupLevel3 { get; set; }
    /// <summary>Nhóm cột tầng 4. Null = không dùng tầng 4.</summary>
    public string? ColumnGroupLevel4 { get; set; }
    public string? ExcelColumn { get; set; }
    /// <summary>Thứ tự trong layout tổng của sheet. Dùng chung namespace với FormPlaceholderColumnOccurrence.LayoutOrder để sort và gán A/B/C... tại runtime.</summary>
    public int LayoutOrder { get; set; }
    public string DataType { get; set; } = "Text";
    public bool IsRequired { get; set; }
    public bool IsEditable { get; set; } = true;
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
