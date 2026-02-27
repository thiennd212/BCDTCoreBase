namespace BCDT.Domain.Entities.Workflow;

/// <summary>Approval history (BCDT_WorkflowApproval). Action: Approve, Reject, RequestRevision, Skip.</summary>
public class WorkflowApproval
{
    public int Id { get; set; }
    public int WorkflowInstanceId { get; set; }
    public byte StepOrder { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? Comments { get; set; }
    public int ApproverId { get; set; }
    public DateTime ApprovedAt { get; set; }
    public string? IpAddress { get; set; }
    public string? SignatureId { get; set; }
}
