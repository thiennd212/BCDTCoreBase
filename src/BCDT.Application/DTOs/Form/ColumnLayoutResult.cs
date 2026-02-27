namespace BCDT.Application.DTOs.Form;

/// <summary>Kết quả tính layout cột của sheet tại runtime. Mỗi slot ứng với một cột Excel (kể cả cột động từ datasource).</summary>
public class ColumnLayoutResult
{
    public List<ColumnSlot> Slots { get; set; } = new();
}

/// <summary>Một slot cột trong layout. FormColumnId != null → cột tĩnh; null → cột động từ datasource.</summary>
public class ColumnSlot
{
    /// <summary>Ký tự cột Excel ("A", "B", ...). Tính tại runtime theo vị trí trong layout.</summary>
    public string ExcelColumn { get; set; } = string.Empty;
    /// <summary>Id FormColumn nếu là cột tĩnh, null nếu là cột động.</summary>
    public int? FormColumnId { get; set; }
    /// <summary>Nhãn cột động (tên datasource row). Null nếu là cột tĩnh.</summary>
    public string? DynamicLabel { get; set; }
    /// <summary>Có thể nhập dữ liệu không. Kế thừa từ FormColumn.IsEditable hoặc true với cột động.</summary>
    public bool IsEditable { get; set; } = true;
    /// <summary>Thứ tự trong layout tổng. Dùng để sort khi build layout.</summary>
    public int LayoutOrder { get; set; }
    /// <summary>ColumnCode của FormColumn tĩnh (dùng cho placeholder {COL_X} trong formula). Null nếu là cột động.</summary>
    public string? ColumnCode { get; set; }
}
