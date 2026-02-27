using BCDT.Application.Common;
using BCDT.Application.DTOs.ReportingPeriod;

namespace BCDT.Application.Services.ReportingPeriod;

public interface IReportingFrequencyService
{
    Task<Result<List<ReportingFrequencyDto>>> GetListAsync(bool includeInactive, CancellationToken cancellationToken = default);
    Task<Result<ReportingFrequencyDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<ReportingFrequencyDto>> CreateAsync(CreateReportingFrequencyRequest request, CancellationToken cancellationToken = default);
    Task<Result<ReportingFrequencyDto>> UpdateAsync(int id, UpdateReportingFrequencyRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
