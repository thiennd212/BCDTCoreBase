using BCDT.Application.Common;

namespace BCDT.Application.Services.Data;

public interface ISubmissionPdfService
{
    /// <summary>Generate PDF bytes for a submission (metadata + optional summary). Returns null if submission not found.</summary>
    Task<Result<byte[]?>> GeneratePdfAsync(long submissionId, CancellationToken cancellationToken = default);
}
