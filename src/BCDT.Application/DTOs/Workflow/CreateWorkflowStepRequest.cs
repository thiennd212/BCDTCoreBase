namespace BCDT.Application.DTOs.Workflow;

public class CreateWorkflowStepRequest
{
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
