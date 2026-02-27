using BCDT.Api.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.Services.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/report-summaries")]
[Authorize]
[Produces("application/json")]
public class ReportSummariesController : ControllerBase
{
    private readonly IReportSummaryService _reportSummaryService;

    public ReportSummariesController(IReportSummaryService reportSummaryService)
    {
        _reportSummaryService = reportSummaryService;
    }

    /// <summary>Drill-down: lấy danh sách ReportDataRow thuộc ReportSummary (FR-TH-02).</summary>
    [HttpGet("{id:long}/details")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<ReportDataRowDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetDetails(long id, CancellationToken cancellationToken = default)
    {
        var result = await _reportSummaryService.GetDetailsByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == ApiErrorCodes.NotFound)
                return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<List<ReportDataRowDto>>(result.Data!));
    }
}
