namespace BCDT.Application.DTOs.Workflow;

public class WorkflowStepDto
{
    public int Id { get; set; }
    public int WorkflowDefinitionId { get; set; }
    public byte StepOrder { get; set; }
    public string StepName { get; set; } = string.Empty;
    public string? StepDescription { get; set; }
    public int? ApproverRoleId { get; set; }
    public string? ApproverRoleCode { get; set; }
    public int? ApproverUserId { get; set; }
    public bool CanReject { get; set; }
    public bool CanRequestRevision { get; set; }
    public int? AutoApproveAfterDays { get; set; }
    public bool NotifyOnPending { get; set; }
    public bool NotifyOnApprove { get; set; }
    public bool NotifyOnReject { get; set; }
    public bool IsActive { get; set; }
}
