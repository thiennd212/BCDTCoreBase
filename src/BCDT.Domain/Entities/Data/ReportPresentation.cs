namespace BCDT.Domain.Entities.Data;

/// <summary>Layer 1: Full Excel workbook state as JSON (BCDT_ReportPresentation). One per submission.</summary>
public class ReportPresentation
{
    public long Id { get; set; }
    public long SubmissionId { get; set; }
    public string WorkbookJson { get; set; } = string.Empty;
    public string WorkbookHash { get; set; } = string.Empty;
    public int FileSize { get; set; }
    public byte SheetCount { get; set; }
    public DateTime LastModifiedAt { get; set; }
    public int LastModifiedBy { get; set; }
}
