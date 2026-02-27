namespace BCDT.Application.DTOs.Data;

public class CreateReportPresentationRequest
{
    public long SubmissionId { get; set; }
    public string WorkbookJson { get; set; } = string.Empty;
    public string WorkbookHash { get; set; } = string.Empty;
    public int FileSize { get; set; }
    public byte SheetCount { get; set; }
}
