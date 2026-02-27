using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IIndicatorService
{
    Task<Result<List<IndicatorDto>>> GetByCatalogAsync(int catalogId, bool tree = false, CancellationToken cancellationToken = default);
    Task<Result<IndicatorDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    /// <summary>Lấy chỉ tiêu theo Code (toàn cục, dùng cho _SPECIAL_GENERIC).</summary>
    Task<Result<IndicatorDto?>> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<Result<IndicatorDto>> CreateAsync(CreateIndicatorRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<IndicatorDto>> UpdateAsync(int id, UpdateIndicatorRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
