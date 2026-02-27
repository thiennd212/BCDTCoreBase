using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormDataBindingService
{
    Task<Result<FormDataBindingDto?>> GetByColumnIdAsync(int formColumnId, CancellationToken cancellationToken = default);
    Task<Result<FormDataBindingDto>> CreateAsync(int formColumnId, CreateFormDataBindingRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormDataBindingDto>> UpdateAsync(int formColumnId, UpdateFormDataBindingRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formColumnId, CancellationToken cancellationToken = default);
}
