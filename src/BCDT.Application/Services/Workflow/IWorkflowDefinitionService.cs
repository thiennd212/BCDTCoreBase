using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;

namespace BCDT.Application.Services.Workflow;

public interface IWorkflowDefinitionService
{
    Task<Result<WorkflowDefinitionDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<WorkflowDefinitionDto?>> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<Result<List<WorkflowDefinitionDto>>> GetListAsync(bool includeInactive, CancellationToken cancellationToken = default);
    Task<Result<WorkflowDefinitionDto>> CreateAsync(CreateWorkflowDefinitionRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<WorkflowDefinitionDto>> UpdateAsync(int id, UpdateWorkflowDefinitionRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default);
}
