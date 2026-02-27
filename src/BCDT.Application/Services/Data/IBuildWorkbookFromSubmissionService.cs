using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;

namespace BCDT.Application.Services.Data;

/// <summary>Xây workbook (dữ liệu hàng cột) từ cấu trúc biểu mẫu và ReportDataRow theo submission/đơn vị.</summary>
public interface IBuildWorkbookFromSubmissionService
{
    /// <summary>Trả về workbook simple format (sheets với rows theo ExcelColumn) từ form + ReportDataRow. Nếu chưa có DataRow thì trả về cấu trúc theo form với ít nhất một dòng trống.</summary>
    Task<Result<WorkbookFromSubmissionDto>> BuildAsync(long submissionId, CancellationToken cancellationToken = default);
}
