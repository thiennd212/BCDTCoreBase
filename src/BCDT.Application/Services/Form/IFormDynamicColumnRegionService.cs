using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormDynamicColumnRegionService
{
    Task<Result<List<FormDynamicColumnRegionDto>>> GetBySheetIdAsync(int formId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<FormDynamicColumnRegionDto?>> GetByIdAsync(int formId, int sheetId, int regionId, CancellationToken cancellationToken = default);
    Task<Result<FormDynamicColumnRegionDto>> CreateAsync(int formId, int sheetId, CreateFormDynamicColumnRegionRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormDynamicColumnRegionDto>> UpdateAsync(int formId, int sheetId, int regionId, UpdateFormDynamicColumnRegionRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formId, int sheetId, int regionId, CancellationToken cancellationToken = default);
}
