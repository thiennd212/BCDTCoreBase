namespace BCDT.Domain.Entities.Form;

/// <summary>Vị trí placeholder cột trên template (BCDT_FormPlaceholderColumnOccurrence). Một cột = một occurrence; khi gen mở rộng thành 0..N cột. P8e.</summary>
public class FormPlaceholderColumnOccurrence
{
    public int Id { get; set; }
    public int FormSheetId { get; set; }
    public int FormDynamicColumnRegionId { get; set; }
    public int ExcelColStart { get; set; }
    public int? FilterDefinitionId { get; set; }
    public int DisplayOrder { get; set; }
    /// <summary>Thứ tự trong layout tổng của sheet. Dùng chung namespace với FormColumn.LayoutOrder để interleave và gán A/B/C... tại runtime.</summary>
    public int LayoutOrder { get; set; }
    public int? MaxColumns { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
