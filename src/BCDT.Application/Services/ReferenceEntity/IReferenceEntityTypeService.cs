using BCDT.Application.Common;
using BCDT.Application.DTOs.ReferenceEntity;

namespace BCDT.Application.Services.ReferenceEntity;

public interface IReferenceEntityTypeService
{
    Task<Result<List<ReferenceEntityTypeDto>>> GetListAsync(bool includeInactive = false, CancellationToken cancellationToken = default);
    Task<Result<ReferenceEntityTypeDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<ReferenceEntityTypeDto>> CreateAsync(CreateReferenceEntityTypeRequest request, CancellationToken cancellationToken = default);
    Task<Result<ReferenceEntityTypeDto>> UpdateAsync(int id, UpdateReferenceEntityTypeRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
