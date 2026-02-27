using BCDT.Application.Common;
using BCDT.Application.DTOs.Organization;

namespace BCDT.Application.Services.Organization;

public interface IOrganizationService
{
    Task<Result<OrganizationDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<List<OrganizationDto>>> GetListAsync(int? parentId, int? organizationTypeId, bool includeInactive, bool all = false, CancellationToken cancellationToken = default);
    Task<Result<OrganizationDto>> CreateAsync(CreateOrganizationRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<OrganizationDto>> UpdateAsync(int id, UpdateOrganizationRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default);
}
