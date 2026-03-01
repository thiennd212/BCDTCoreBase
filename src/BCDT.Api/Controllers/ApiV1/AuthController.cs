using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Auth;
using BCDT.Application.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Http;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/auth")]
[Produces("application/json")]
public class AuthController : ControllerBase
{
    private const string RefreshTokenCookieName = "bc_refresh_token";

    private readonly IAuthService _authService;
    private readonly ILogger<AuthController> _logger;

    public AuthController(IAuthService authService, ILogger<AuthController> logger)
    {
        _authService = authService;
        _logger = logger;
    }

    private static CookieOptions BuildRefreshCookieOptions(DateTimeOffset expires) =>
        new()
        {
            HttpOnly = true,
            Secure = true,
            SameSite = SameSiteMode.Strict,
            Path = "/api/v1/auth",
            Expires = expires
        };

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

        var loginData = result.Data!;
        if (!string.IsNullOrEmpty(loginData.RefreshToken))
        {
            Response.Cookies.Append(
                RefreshTokenCookieName,
                loginData.RefreshToken,
                BuildRefreshCookieOptions(DateTimeOffset.UtcNow.AddDays(7)));
        }

        _logger.LogInformation("Login success userId {UserId}", loginData.User.Id);
        return Ok(new ApiSuccessResponse<LoginResponse>(loginData));
    }

    /// <summary>Làm mới access_token bằng refresh_token.</summary>
    [HttpPost("refresh")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiSuccessResponse<RefreshResponse>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiErrorResponse), StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request, CancellationToken cancellationToken)
    {
        var refreshToken = Request.Cookies[RefreshTokenCookieName] ?? request?.RefreshToken;
        if (string.IsNullOrWhiteSpace(refreshToken))
        {
            return BadRequest(new ApiErrorResponse("MISSING_REFRESH_TOKEN", "Refresh token is required."));
        }

        var refreshRequest = new RefreshRequest { RefreshToken = refreshToken };
        var result = await _authService.RefreshAsync(refreshRequest, cancellationToken);
        if (!result.IsSuccess)
            return Unauthorized(new ApiErrorResponse(result.Code, result.Message));

        var refreshData = result.Data!;
        if (!string.IsNullOrEmpty(refreshData.RefreshToken))
        {
            Response.Cookies.Append(
                RefreshTokenCookieName,
                refreshData.RefreshToken,
                BuildRefreshCookieOptions(DateTimeOffset.UtcNow.AddDays(7)));
        }

        return Ok(new ApiSuccessResponse<RefreshResponse>(refreshData));
    }

    /// <summary>Đăng xuất: thu hồi refresh_token.</summary>
    [HttpPost("logout")]
    [AllowAnonymous]
    [ProducesResponseType(typeof(ApiSuccessResponse<object>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Logout([FromBody] RefreshRequest request, CancellationToken cancellationToken)
    {
        var refreshToken = Request.Cookies[RefreshTokenCookieName] ?? request?.RefreshToken;
        var logoutRequest = new RefreshRequest { RefreshToken = refreshToken ?? string.Empty };

        var ip = HttpContext.Connection.RemoteIpAddress?.ToString();
        var result = await _authService.LogoutAsync(logoutRequest, ip, cancellationToken);

        Response.Cookies.Delete(
            RefreshTokenCookieName,
            new CookieOptions { Path = "/api/v1/auth", Secure = true, SameSite = SameSiteMode.Strict });

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
