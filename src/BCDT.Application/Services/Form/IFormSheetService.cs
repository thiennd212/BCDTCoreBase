using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormSheetService
{
    Task<Result<List<FormSheetDto>>> GetByFormIdAsync(int formDefinitionId, CancellationToken cancellationToken = default);
    Task<Result<FormSheetDto?>> GetByIdAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<FormSheetDto>> CreateAsync(int formDefinitionId, CreateFormSheetRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormSheetDto>> UpdateAsync(int formDefinitionId, int sheetId, UpdateFormSheetRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default);
}
