using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;

namespace BCDT.Application.Services.Data;

public interface IReportPresentationService
{
    Task<Result<ReportPresentationDto?>> GetByIdAsync(long id, CancellationToken cancellationToken = default);
    Task<Result<ReportPresentationDto?>> GetBySubmissionIdAsync(long submissionId, CancellationToken cancellationToken = default);
    Task<Result<ReportPresentationDto>> CreateAsync(CreateReportPresentationRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<ReportPresentationDto>> UpdateAsync(long id, UpdateReportPresentationRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<ReportPresentationDto>> UpsertBySubmissionIdAsync(long submissionId, CreateReportPresentationRequest request, int userId, CancellationToken cancellationToken = default);
}
