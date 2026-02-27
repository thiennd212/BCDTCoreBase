namespace BCDT.Application.DTOs.Workflow;

public class CreateFormWorkflowConfigRequest
{
    public int FormDefinitionId { get; set; }
    public int WorkflowDefinitionId { get; set; }
    public int? OrganizationTypeId { get; set; }
    public bool IsActive { get; set; } = true;
}
