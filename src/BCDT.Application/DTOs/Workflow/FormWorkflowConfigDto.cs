namespace BCDT.Application.DTOs.Workflow;

public class FormWorkflowConfigDto
{
    public int Id { get; set; }
    public int FormDefinitionId { get; set; }
    public string? FormDefinitionCode { get; set; }
    public int WorkflowDefinitionId { get; set; }
    public string? WorkflowDefinitionCode { get; set; }
    public int? OrganizationTypeId { get; set; }
    public string? OrganizationTypeCode { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
