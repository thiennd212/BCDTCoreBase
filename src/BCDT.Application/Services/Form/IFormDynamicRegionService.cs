using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormDynamicRegionService
{
    Task<Result<List<FormDynamicRegionDto>>> GetBySheetIdAsync(int formId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<FormDynamicRegionDto?>> GetByIdAsync(int formId, int sheetId, int regionId, CancellationToken cancellationToken = default);
    Task<Result<FormDynamicRegionDto>> CreateAsync(int formId, int sheetId, CreateFormDynamicRegionRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormDynamicRegionDto>> UpdateAsync(int formId, int sheetId, int regionId, UpdateFormDynamicRegionRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formId, int sheetId, int regionId, CancellationToken cancellationToken = default);
}
