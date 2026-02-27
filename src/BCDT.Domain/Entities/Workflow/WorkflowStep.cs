namespace BCDT.Domain.Entities.Workflow;

/// <summary>Workflow step 1-5 (BCDT_WorkflowStep). ApproverRoleId from BCDT_Role.</summary>
public class WorkflowStep
{
    public int Id { get; set; }
    public int WorkflowDefinitionId { get; set; }
    public byte StepOrder { get; set; }
    public string StepName { get; set; } = string.Empty;
    public string? StepDescription { get; set; }
    public int? ApproverRoleId { get; set; }
    public int? ApproverUserId { get; set; }
    public bool CanReject { get; set; } = true;
    public bool CanRequestRevision { get; set; } = true;
    public int? AutoApproveAfterDays { get; set; }
    public bool NotifyOnPending { get; set; } = true;
    public bool NotifyOnApprove { get; set; } = true;
    public bool NotifyOnReject { get; set; } = true;
    public bool IsActive { get; set; } = true;
}
