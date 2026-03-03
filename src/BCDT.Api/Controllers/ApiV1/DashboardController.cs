using BCDT.Api.Common;
using BCDT.Application.DTOs.Dashboard;
using BCDT.Application.Services;
using BCDT.Application.Services.Dashboard;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/dashboard")]
[Authorize]
[Produces("application/json")]
public class DashboardController : ControllerBase
{
    private readonly IDashboardService _service;
    private readonly ICurrentUserService _currentUserService;

    public DashboardController(IDashboardService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    /// <summary>Thống kê admin. Query: periodId (tùy chọn, lọc theo kỳ báo cáo).</summary>
    [HttpGet("admin/stats")]
    [ProducesResponseType(typeof(ApiSuccessResponse<DashboardAdminStatsDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAdminStats([FromQuery] int? periodId = null, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId();
        var result = await _service.GetAdminStatsAsync(userId, periodId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<DashboardAdminStatsDto>(result.Data!));
    }

    [HttpGet("user/tasks")]
    [ProducesResponseType(typeof(ApiSuccessResponse<DashboardUserTasksDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetUserTasks(CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId();
        if (!userId.HasValue)
            return Unauthorized(new ApiErrorResponse("UNAUTHORIZED", "Không xác định được user."));
        var result = await _service.GetUserTasksAsync(userId.Value, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<DashboardUserTasksDto>(result.Data!));
    }
}
