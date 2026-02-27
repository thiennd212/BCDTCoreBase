using BCDT.Api.Common;
using BCDT.Application.DTOs.ReportingPeriod;
using BCDT.Application.Services;
using BCDT.Application.Services.ReportingPeriod;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/reporting-periods")]
[Authorize]
[Produces("application/json")]
public class ReportingPeriodsController : ControllerBase
{
    private readonly IReportingPeriodService _service;
    private readonly ICurrentUserService _currentUserService;

    public ReportingPeriodsController(IReportingPeriodService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    /// <summary>Danh sách kỳ báo cáo. Query: frequencyId, year, status, isCurrent.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<ReportingPeriodDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(
        [FromQuery] int? frequencyId,
        [FromQuery] int? year,
        [FromQuery] string? status,
        [FromQuery] bool? isCurrent,
        CancellationToken cancellationToken = default)
    {
        var result = await _service.GetListAsync(frequencyId, year, status, isCurrent, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<ReportingPeriodDto>>(result.Data!));
    }

    /// <summary>Kỳ báo cáo hiện tại theo frequencyId (vd. MONTHLY=3).</summary>
    [HttpGet("current")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportingPeriodDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetCurrent([FromQuery] int? frequencyId, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetCurrentAsync(frequencyId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Chưa có kỳ hiện tại."));
        return Ok(new ApiSuccessResponse<ReportingPeriodDto>(result.Data));
    }

    /// <summary>Chi tiết kỳ báo cáo theo Id.</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportingPeriodDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Kỳ báo cáo không tồn tại."));
        return Ok(new ApiSuccessResponse<ReportingPeriodDto>(result.Data));
    }

    /// <summary>Tạo kỳ báo cáo mới. 409 nếu trùng periodCode trong cùng frequency.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportingPeriodDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateReportingPeriodRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<ReportingPeriodDto>(result.Data!));
    }

    /// <summary>Cập nhật kỳ báo cáo. 404 nếu không tồn tại.</summary>
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportingPeriodDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateReportingPeriodRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<ReportingPeriodDto>(result.Data!));
    }

    /// <summary>Xóa kỳ báo cáo. 409 nếu đã có submission gắn kỳ.</summary>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.DeleteAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(result.Data!));
    }
}
