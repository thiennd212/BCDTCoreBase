using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IIndicatorCatalogService
{
    Task<Result<List<IndicatorCatalogDto>>> GetAllAsync(bool includeInactive = false, CancellationToken cancellationToken = default);
    Task<Result<IndicatorCatalogDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<IndicatorCatalogDto>> CreateAsync(CreateIndicatorCatalogRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<IndicatorCatalogDto>> UpdateAsync(int id, UpdateIndicatorCatalogRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
