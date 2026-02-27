namespace BCDT.Application.DTOs.Data;

public class BulkCreateSubmissionsRequest
{
    public int FormDefinitionId { get; set; }
    public int FormVersionId { get; set; }
    public int ReportingPeriodId { get; set; }
    public List<int> OrganizationIds { get; set; } = new();
}
