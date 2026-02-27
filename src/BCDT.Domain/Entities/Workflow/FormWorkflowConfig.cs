namespace BCDT.Domain.Entities.Workflow;

/// <summary>Form ↔ Workflow mapping (BCDT_FormWorkflowConfig). OrganizationTypeId null = all org types.</summary>
public class FormWorkflowConfig
{
    public int Id { get; set; }
    public int FormDefinitionId { get; set; }
    public int WorkflowDefinitionId { get; set; }
    public int? OrganizationTypeId { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
