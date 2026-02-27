using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFilterDefinitionService
{
    Task<Result<List<FilterDefinitionDto>>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Result<FilterDefinitionDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    /// <summary>Load nhiều FilterDefinition + Condition theo list id (1–2 query) – dùng cho batch trong request (Perf-8).</summary>
    Task<Result<IReadOnlyDictionary<int, FilterDefinitionDto>>> GetByIdsAsync(IReadOnlyList<int> ids, CancellationToken cancellationToken = default);
    Task<Result<FilterDefinitionDto>> CreateAsync(CreateFilterDefinitionRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FilterDefinitionDto>> UpdateAsync(int id, UpdateFilterDefinitionRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
