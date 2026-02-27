using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Auth;
using BCDT.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/auth")]
[Produces("application/json")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    /// <summary>Đăng nhập: trả access_token, refresh_token và thông tin user.</summary>
    [HttpPost("login")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiSuccessResponse<LoginResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiErrorResponse), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken cancellationToken)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.LoginAsync(request, ip, cancellationToken);
        if (!result.IsSuccess)
        {
            _logger.LogWarning("Login failed for user {Username}, code {Code}", request?.Username ?? "(null)", result.Code);
            return Unauthorized(new ApiErrorResponse(result.Code, result.Message));
        }
        _logger.LogInformation("Login success userId {UserId}", result.Data!.User.Id);
        return Ok(new ApiSuccessResponse<LoginResponse>(result.Data!));
    }

    /// <summary>Làm mới access_token bằng refresh_token.</summary>
    [HttpPost("refresh")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiSuccessResponse<RefreshResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiErrorResponse), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request, CancellationToken cancellationToken)
    {
        var result = await _authService.RefreshAsync(request, cancellationToken);
        if (!result.IsSuccess)
            return Unauthorized(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<RefreshResponse>(result.Data!));
    }

    /// <summary>Đăng xuất: thu hồi refresh_token.</summary>
    [HttpPost("logout")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiSuccessResponse<object>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Logout([FromBody] RefreshRequest request, CancellationToken cancellationToken)
    {
        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.LogoutAsync(request, ip, cancellationToken);
        return Ok(new ApiSuccessResponse<object>(result.Data!));
    }

    /// <summary>Danh sách vai trò của user hiện tại (để chuyển vai trò trên FE).</summary>
    [HttpGet("me/roles")]
    [Authorize]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<UserRoleItemDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> MeRoles(CancellationToken cancellationToken)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();
        var roles = await _authService.GetMyRolesAsync(userId, cancellationToken);
        return Ok(new ApiSuccessResponse<List<UserRoleItemDto>>(roles));
    }

    /// <summary>Lấy thông tin user hiện tại từ JWT (cần Bearer token).</summary>
    [HttpGet("me")]
    [Authorize]
    [ProducesResponseType(typeof(ApiSuccessResponse<UserInfoDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Me(CancellationToken cancellationToken)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();
        var userInfo = await _authService.GetUserInfoAsync(userId, cancellationToken);
        if (userInfo == null)
            return Unauthorized();
        return Ok(new ApiSuccessResponse<UserInfoDto>(userInfo));
    }

    /// <summary>Đổi mật khẩu cho user hiện tại.</summary>
    [HttpPost("change-password")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request, CancellationToken cancellationToken)
    {
        var userIdClaim = User.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();
        var result = await _authService.ChangePasswordAsync(userId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "UNAUTHORIZED")
                return Unauthorized(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<object>(null!));
    }
}
