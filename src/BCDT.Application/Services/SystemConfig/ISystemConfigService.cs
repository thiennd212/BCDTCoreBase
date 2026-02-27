using BCDT.Application.Common;
using BCDT.Application.DTOs.SystemConfig;

namespace BCDT.Application.Services.SystemConfig;

public interface ISystemConfigService
{
    Task<Result<List<SystemConfigDto>>> GetAllAsync(CancellationToken cancellationToken = default);
    Task<Result<SystemConfigDto?>> GetByKeyAsync(string key, CancellationToken cancellationToken = default);
    Task<Result<SystemConfigDto>> UpdateAsync(string key, UpdateSystemConfigRequest request, int updatedBy, CancellationToken cancellationToken = default);
}
