using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;

namespace BCDT.Application.Services.Data;

/// <summary>Export báo cáo tổng hợp (nhiều đơn vị, một kỳ báo cáo) thành file Excel.</summary>
public interface IExportSummaryService
{
    /// <summary>Lấy tất cả ReportSummary của kỳ báo cáo, tạo file Excel (tên đơn vị + tổng chỉ tiêu).</summary>
    Task<Result<ExportSummaryFileDto>> ExportSummaryAsync(int periodId, CancellationToken cancellationToken = default);
}
