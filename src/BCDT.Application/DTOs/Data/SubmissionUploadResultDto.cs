namespace BCDT.Application.DTOs.Data;

/// <summary>Kết quả sau khi upload Excel cho submission.</summary>
public class SubmissionUploadResultDto
{
    public long SubmissionId { get; set; }
    public int DataRowCount { get; set; }
    public int SheetCount { get; set; }
    public bool PresentationUpdated { get; set; }
    public string? Message { get; set; }
}
