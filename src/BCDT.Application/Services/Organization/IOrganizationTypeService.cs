using BCDT.Application.Common;
using BCDT.Application.DTOs.Organization;

namespace BCDT.Application.Services.Organization;

public interface IOrganizationTypeService
{
    Task<Result<List<OrganizationTypeDto>>> GetAllAsync(bool includeInactive = false, CancellationToken cancellationToken = default);
    Task<Result<OrganizationTypeDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<OrganizationTypeDto>> CreateAsync(CreateOrganizationTypeRequest request, CancellationToken cancellationToken = default);
    Task<Result<OrganizationTypeDto>> UpdateAsync(int id, UpdateOrganizationTypeRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
