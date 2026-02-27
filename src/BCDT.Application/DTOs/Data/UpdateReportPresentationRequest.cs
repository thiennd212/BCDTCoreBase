namespace BCDT.Application.DTOs.Data;

public class UpdateReportPresentationRequest
{
    public string WorkbookJson { get; set; } = string.Empty;
    public string WorkbookHash { get; set; } = string.Empty;
    public int FileSize { get; set; }
    public byte SheetCount { get; set; }
}
