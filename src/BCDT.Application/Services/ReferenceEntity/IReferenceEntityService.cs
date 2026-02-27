using BCDT.Application.Common;
using BCDT.Application.DTOs.ReferenceEntity;

namespace BCDT.Application.Services.ReferenceEntity;

public interface IReferenceEntityService
{
    Task<Result<ReferenceEntityDto?>> GetByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<Result<List<ReferenceEntityDto>>> GetListAsync(int? entityTypeId, long? parentId, bool includeInactive, bool all = false, CancellationToken cancellationToken = default);
    Task<Result<ReferenceEntityDto>> CreateAsync(CreateReferenceEntityRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<ReferenceEntityDto>> UpdateAsync(long id, UpdateReferenceEntityRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(long id, CancellationToken cancellationToken = default);
}
