using BCDT.Application.Common;
using BCDT.Application.DTOs.ReportingPeriod;

namespace BCDT.Application.Services.ReportingPeriod;

public interface IReportingPeriodService
{
    Task<Result<List<ReportingPeriodDto>>> GetListAsync(int? frequencyId, int? year, string? status, bool? isCurrent, CancellationToken cancellationToken = default);
    Task<Result<ReportingPeriodDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<ReportingPeriodDto?>> GetCurrentAsync(int? frequencyId, CancellationToken cancellationToken = default);
    Task<Result<ReportingPeriodDto>> CreateAsync(CreateReportingPeriodRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<ReportingPeriodDto>> UpdateAsync(int id, UpdateReportingPeriodRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<PeriodSummaryExportDto>> GetSummaryExportAsync(int periodId, CancellationToken cancellationToken = default);
}
