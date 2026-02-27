using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormColumnMappingService
{
    Task<Result<FormColumnMappingDto?>> GetByColumnIdAsync(int formColumnId, CancellationToken cancellationToken = default);
    Task<Result<FormColumnMappingDto>> CreateAsync(int formColumnId, CreateFormColumnMappingRequest request, CancellationToken cancellationToken = default);
    Task<Result<FormColumnMappingDto>> UpdateAsync(int formColumnId, UpdateFormColumnMappingRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formColumnId, CancellationToken cancellationToken = default);
}
