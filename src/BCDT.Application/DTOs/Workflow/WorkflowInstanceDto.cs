namespace BCDT.Application.DTOs.Workflow;

public class WorkflowInstanceDto
{
    public int Id { get; set; }
    public long SubmissionId { get; set; }
    public int WorkflowDefinitionId { get; set; }
    public string? WorkflowDefinitionCode { get; set; }
    public byte CurrentStep { get; set; }
    public string Status { get; set; } = string.Empty;
    public DateTime StartedAt { get; set; }
    public DateTime? CompletedAt { get; set; }
    public int CreatedBy { get; set; }
}
