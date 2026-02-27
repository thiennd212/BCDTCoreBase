using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;

namespace BCDT.Application.Services.Data;

/// <summary>Xử lý upload file Excel cho submission: đọc theo FormColumnMapping, ghi ReportDataRow + ReportPresentation.</summary>
public interface ISubmissionExcelService
{
    /// <summary>Đọc file Excel từ stream, map theo FormDefinition (sheets/columns/mapping), ghi vào ReportDataRow và ReportPresentation.</summary>
    Task<Result<SubmissionUploadResultDto>> ProcessUploadedExcelAsync(long submissionId, Stream excelStream, int userId, CancellationToken cancellationToken = default);
}
