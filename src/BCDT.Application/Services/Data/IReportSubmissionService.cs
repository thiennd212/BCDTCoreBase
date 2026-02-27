using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;

namespace BCDT.Application.Services.Data;

public interface IReportSubmissionService
{
    Task<Result<ReportSubmissionDto?>> GetByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<Result<List<ReportSubmissionDto>>> GetListAsync(int? formDefinitionId, int? organizationId, int? reportingPeriodId, string? status, bool includeDeleted, CancellationToken cancellationToken = default);
    Task<Result<PagedResultDto<ReportSubmissionDto>>> GetListPagedAsync(int? formDefinitionId, int? organizationId, int? reportingPeriodId, string? status, bool includeDeleted, int pageSize, int pageNumber, CancellationToken cancellationToken = default);
    Task<Result<ReportSubmissionDto>> CreateAsync(CreateReportSubmissionRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<BulkCreateSubmissionsResultDto>> BulkCreateAsync(BulkCreateSubmissionsRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<ReportSubmissionDto>> UpdateAsync(long id, UpdateReportSubmissionRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(long id, int deletedBy, CancellationToken cancellationToken = default);
}
