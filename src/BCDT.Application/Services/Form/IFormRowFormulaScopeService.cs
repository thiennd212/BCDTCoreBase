using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormRowFormulaScopeService
{
    Task<Result<List<FormRowFormulaScopeDto>>> GetByRowIdAsync(int formDefinitionId, int sheetId, int rowId, CancellationToken ct = default);
    Task<Result<FormRowFormulaScopeDto>> CreateAsync(int formDefinitionId, int sheetId, int rowId, CreateFormRowFormulaScopeRequest request, int createdBy, CancellationToken ct = default);
    Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, int rowId, int id, CancellationToken ct = default);
}
