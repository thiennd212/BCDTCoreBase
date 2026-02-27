using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;

namespace BCDT.Application.Services.Workflow;

public interface IFormWorkflowConfigService
{
    Task<Result<List<FormWorkflowConfigDto>>> GetByFormIdAsync(int formDefinitionId, CancellationToken cancellationToken = default);
    Task<Result<FormWorkflowConfigDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<FormWorkflowConfigDto>> CreateAsync(CreateFormWorkflowConfigRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default);
    Task<Result<int?>> GetWorkflowDefinitionIdForFormAsync(int formDefinitionId, int? organizationTypeId, CancellationToken cancellationToken = default);
}
