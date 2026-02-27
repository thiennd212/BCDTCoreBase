namespace BCDT.Application.DTOs.Data;

public class CreateReportSubmissionRequest
{
    public int FormDefinitionId { get; set; }
    public int FormVersionId { get; set; }
    public int OrganizationId { get; set; }
    public int ReportingPeriodId { get; set; }
    public string Status { get; set; } = "Draft";
}
