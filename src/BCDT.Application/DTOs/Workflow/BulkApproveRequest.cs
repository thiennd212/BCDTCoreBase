namespace BCDT.Application.DTOs.Workflow;

public class BulkApproveRequest
{
    public List<int> WorkflowInstanceIds { get; set; } = new();
    public string? Comments { get; set; }
}
