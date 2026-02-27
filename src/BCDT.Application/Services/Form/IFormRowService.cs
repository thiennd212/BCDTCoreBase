using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormRowService
{
    Task<Result<List<FormRowDto>>> GetBySheetIdAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<List<FormRowTreeDto>>> GetBySheetIdAsTreeAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<FormRowDto?>> GetByIdAsync(int formDefinitionId, int sheetId, int rowId, CancellationToken cancellationToken = default);
    Task<Result<FormRowDto>> CreateAsync(int formDefinitionId, int sheetId, CreateFormRowRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormRowDto>> UpdateAsync(int formDefinitionId, int sheetId, int rowId, UpdateFormRowRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, int rowId, CancellationToken cancellationToken = default);
}
