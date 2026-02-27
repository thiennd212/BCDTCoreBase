namespace BCDT.Application.DTOs.Workflow;

/// <summary>Lịch sử phê duyệt (BCDT_WorkflowApproval) – dùng cho GET workflow-instances/{id}/approvals.</summary>
public class WorkflowApprovalDto
{
    public int Id { get; set; }
    public byte StepOrder { get; set; }
    public string Action { get; set; } = string.Empty;
    public string? Comments { get; set; }
    public int ApproverId { get; set; }
    public DateTime ApprovedAt { get; set; }
}
