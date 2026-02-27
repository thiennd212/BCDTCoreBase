using BCDT.Application.Common;
using BCDT.Application.DTOs.Authorization;

namespace BCDT.Application.Services.Authorization;

public interface IUserDelegationService
{
    Task<Result<List<UserDelegationDto>>> GetListAsync(int? fromUserId, int? toUserId, bool activeOnly, CancellationToken cancellationToken = default);
    Task<Result<UserDelegationDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<UserDelegationDto>> CreateAsync(CreateUserDelegationRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<UserDelegationDto>> RevokeAsync(int id, RevokeUserDelegationRequest request, int revokedBy, CancellationToken cancellationToken = default);
}
