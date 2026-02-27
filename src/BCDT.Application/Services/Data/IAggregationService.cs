using BCDT.Application.Common;

namespace BCDT.Application.Services.Data;

public interface IAggregationService
{
    /// <summary>Tính lại ReportSummary từ ReportDataRow cho một submission.</summary>
    Task<Result<object>> AggregateSubmissionAsync(long submissionId, CancellationToken cancellationToken = default);
}
