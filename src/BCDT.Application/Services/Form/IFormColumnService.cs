using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormColumnService
{
    Task<Result<List<FormColumnDto>>> GetBySheetIdAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<List<FormColumnTreeDto>>> GetBySheetIdAsTreeAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<FormColumnDto?>> GetByIdAsync(int formDefinitionId, int sheetId, int columnId, CancellationToken cancellationToken = default);
    Task<Result<FormColumnDto>> CreateAsync(int formDefinitionId, int sheetId, CreateFormColumnRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormColumnDto>> UpdateAsync(int formDefinitionId, int sheetId, int columnId, UpdateFormColumnRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, int columnId, CancellationToken cancellationToken = default);
}
