using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;

namespace BCDT.Application.Services.Data;

public interface ISubmissionDynamicIndicatorService
{
    Task<Result<List<ReportDynamicIndicatorItemDto>>> GetBySubmissionIdAsync(long submissionId, CancellationToken cancellationToken = default);
    Task<Result<object>> PutAsync(long submissionId, PutDynamicIndicatorsRequest request, int userId, CancellationToken cancellationToken = default);
}
