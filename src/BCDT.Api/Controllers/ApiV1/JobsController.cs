using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Infrastructure.Jobs;
using Hangfire;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

/// <summary>Perf-13: API enqueue background job và lấy trạng thái. Client poll GET /jobs/{jobId} cho đến khi Succeeded/Failed.</summary>
[ApiController]
[Route("api/v1/jobs")]
[Authorize]
[Produces("application/json")]
public class JobsController : ControllerBase
{
    private readonly IBackgroundJobClient _backgroundJobClient;

    public JobsController(IBackgroundJobClient backgroundJobClient)
    {
        _backgroundJobClient = backgroundJobClient;
    }

    /// <summary>Đẩy job tính tổng hợp (aggregate) cho một submission vào hàng đợi. Trả về jobId để client poll GET /jobs/{jobId}.</summary>
    [HttpPost("aggregate-submission")]
    [ProducesResponseType(typeof(ApiSuccessResponse<JobEnqueuedResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiErrorResponse), StatusCodes.Status400BadRequest)]
    public IActionResult EnqueueAggregateSubmission([FromBody] AggregateSubmissionRequest request)
    {
        if (request?.SubmissionId <= 0)
            return BadRequest(new ApiErrorResponse("VALIDATION_FAILED", "SubmissionId phải là số dương."));

        var jobId = _backgroundJobClient.Enqueue<AggregateSubmissionJob>(j => j.ExecuteAsync(request!.SubmissionId, CancellationToken.None));
        return Ok(new ApiSuccessResponse<JobEnqueuedResponse>(new JobEnqueuedResponse { JobId = jobId }));
    }

    /// <summary>Lấy trạng thái job. State: Enqueued, Processing, Succeeded, Failed. Client poll cho đến khi Succeeded hoặc Failed.</summary>
    [HttpGet("{jobId}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<JobStatusResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public IActionResult GetJobStatus(string jobId)
    {
        if (string.IsNullOrWhiteSpace(jobId))
            return NotFound();

        var monitoring = JobStorage.Current.GetMonitoringApi();
        var details = monitoring.JobDetails(jobId);
        if (details == null)
            return NotFound();

        var state = details.History?.Count > 0 ? details.History[^1].StateName : "Unknown";
        return Ok(new ApiSuccessResponse<JobStatusResponse>(new JobStatusResponse
        {
            JobId = jobId,
            State = state,
            CreatedAt = details.CreatedAt
        }));
    }
}

public class AggregateSubmissionRequest
{
    public long SubmissionId { get; set; }
}

public class JobEnqueuedResponse
{
    public string JobId { get; set; } = "";
}

public class JobStatusResponse
{
    public string JobId { get; set; } = "";
    public string State { get; set; } = "";
    public DateTime? CreatedAt { get; set; }
}
