using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;

namespace BCDT.Application.Services.Workflow;

public interface IWorkflowStepService
{
    Task<Result<List<WorkflowStepDto>>> GetByDefinitionIdAsync(int workflowDefinitionId, CancellationToken cancellationToken = default);
    Task<Result<WorkflowStepDto?>> GetByIdAsync(int workflowDefinitionId, int stepId, CancellationToken cancellationToken = default);
    Task<Result<WorkflowStepDto>> CreateAsync(int workflowDefinitionId, CreateWorkflowStepRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<WorkflowStepDto>> UpdateAsync(int workflowDefinitionId, int stepId, UpdateWorkflowStepRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int workflowDefinitionId, int stepId, int deletedBy, CancellationToken cancellationToken = default);
}
