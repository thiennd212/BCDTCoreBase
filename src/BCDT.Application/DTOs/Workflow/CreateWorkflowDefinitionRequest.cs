namespace BCDT.Application.DTOs.Workflow;

public class CreateWorkflowDefinitionRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public byte TotalSteps { get; set; } = 1;
    public bool IsDefault { get; set; }
    public bool IsActive { get; set; } = true;
}
