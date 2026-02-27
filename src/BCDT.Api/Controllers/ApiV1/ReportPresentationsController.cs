using BCDT.Api.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.Services;
using BCDT.Application.Services.Data;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/report-presentations")]
[Authorize]
[Produces("application/json")]
public class ReportPresentationsController : ControllerBase
{
    private readonly IReportPresentationService _presentationService;
    private readonly ICurrentUserService _currentUserService;

    public ReportPresentationsController(IReportPresentationService presentationService, ICurrentUserService currentUserService)
    {
        _presentationService = presentationService;
        _currentUserService = currentUserService;
    }

    /// <summary>Lấy presentation theo Id (primary key).</summary>
    [HttpGet("{id:long}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportPresentationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(long id, CancellationToken cancellationToken = default)
    {
        var result = await _presentationService.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Presentation không tồn tại."));
        return Ok(new ApiSuccessResponse<ReportPresentationDto>(result.Data));
    }

    /// <summary>Cập nhật presentation theo Id.</summary>
    [HttpPut("{id:long}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportPresentationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateReportPresentationRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _presentationService.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<ReportPresentationDto>(result.Data!));
    }
}
