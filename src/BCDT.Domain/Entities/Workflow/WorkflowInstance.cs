namespace BCDT.Domain.Entities.Workflow;

/// <summary>Running workflow instance (BCDT_WorkflowInstance). Status: Pending, Approved, Rejected, Cancelled.</summary>
public class WorkflowInstance
{
    public int Id { get; set; }
    public long SubmissionId { get; set; }
    public int WorkflowDefinitionId { get; set; }
    public byte CurrentStep { get; set; } = 1;
    public string Status { get; set; } = "Pending";
    public DateTime StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public int CreatedBy { get; set; }
}
