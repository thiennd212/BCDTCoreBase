namespace BCDT.Domain.Entities.Workflow;

/// <summary>Workflow template (BCDT_WorkflowDefinition). TotalSteps 1-5.</summary>
public class WorkflowDefinition
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public byte TotalSteps { get; set; }
    public bool IsDefault { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
