using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormCellFormulaService
{
    Task<Result<List<FormCellFormulaDto>>> GetBySheetIdAsync(int formDefinitionId, int sheetId, CancellationToken ct = default);
    Task<Result<FormCellFormulaDto>> UpsertAsync(int formDefinitionId, int sheetId, CreateFormCellFormulaRequest request, int userId, CancellationToken ct = default);
    Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, int id, CancellationToken ct = default);
}
