using BCDT.Application.Common;
using BCDT.Application.DTOs.User;

namespace BCDT.Application.Services.User;

public interface IUserService
{
    Task<Result<UserDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<List<UserDto>>> GetListAsync(int? organizationId, bool includeInactive, CancellationToken cancellationToken = default);
    Task<Result<UserDto>> CreateAsync(CreateUserRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<UserDto>> UpdateAsync(int id, UpdateUserRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default);
}
