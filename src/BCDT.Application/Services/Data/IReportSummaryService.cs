using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;

namespace BCDT.Application.Services.Data;

public interface IReportSummaryService
{
    /// <summary>Lấy danh sách ReportDataRow thuộc về một ReportSummary (drill-down FR-TH-02).</summary>
    Task<Result<List<ReportDataRowDto>>> GetDetailsByIdAsync(long summaryId, CancellationToken cancellationToken = default);
}
