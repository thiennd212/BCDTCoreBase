using BCDT.Api.Common;
using BCDT.Application.DTOs.Authorization;
using BCDT.Application.Services;
using BCDT.Application.Services.Authorization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/user-delegations")]
[Authorize]
[Produces("application/json")]
public class UserDelegationsController : ControllerBase
{
    private readonly IUserDelegationService _service;
    private readonly ICurrentUserService _currentUserService;

    public UserDelegationsController(IUserDelegationService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    /// <summary>Danh sách ủy quyền. Query: fromUserId, toUserId, activeOnly (chỉ còn hiệu lực).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<UserDelegationDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(
        [FromQuery] int? fromUserId,
        [FromQuery] int? toUserId,
        [FromQuery] bool activeOnly = false,
        CancellationToken cancellationToken = default)
    {
        var result = await _service.GetListAsync(fromUserId, toUserId, activeOnly, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<UserDelegationDto>>(result.Data!));
    }

    /// <summary>Chi tiết ủy quyền theo Id.</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<UserDelegationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return NotFound(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<UserDelegationDto>(result.Data!));
    }

    /// <summary>
    /// Tạo ủy quyền tạm thời. DelegationType: Full | Partial.
    /// Khi Partial, Permissions là JSON array permission codes (vd ["Form.Edit","Submission.Submit"]).
    /// </summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<UserDelegationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateUserDelegationRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<UserDelegationDto>(result.Data!));
    }

    /// <summary>Thu hồi ủy quyền (soft-revoke: đặt IsActive=false, ghi RevokedAt/RevokedBy/RevokedReason).</summary>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<UserDelegationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Revoke(int id, [FromBody] RevokeUserDelegationRequest? request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.RevokeAsync(id, request ?? new RevokeUserDelegationRequest(), userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<UserDelegationDto>(result.Data!));
    }
}
