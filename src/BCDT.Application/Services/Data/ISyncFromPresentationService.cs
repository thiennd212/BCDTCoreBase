using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;

namespace BCDT.Application.Services.Data;

/// <summary>Đồng bộ ReportDataRow từ WorkbookJson (presentation) đã lưu.</summary>
public interface ISyncFromPresentationService
{
    /// <summary>Đọc WorkbookJson của submission, trích giá trị theo FormColumnMapping, ghi vào ReportDataRow (xóa dữ liệu cũ).</summary>
    Task<Result<SubmissionUploadResultDto>> SyncFromPresentationAsync(long submissionId, int userId, CancellationToken cancellationToken = default);
}
