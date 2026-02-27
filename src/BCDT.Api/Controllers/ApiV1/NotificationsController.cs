using BCDT.Api.Common;
using BCDT.Application.DTOs.Notification;
using BCDT.Application.Services;
using BCDT.Application.Services.Notification;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/notifications")]
[Authorize]
[Produces("application/json")]
public class NotificationsController : ControllerBase
{
    private readonly INotificationService _notificationService;
    private readonly ICurrentUserService _currentUserService;

    public NotificationsController(INotificationService notificationService, ICurrentUserService currentUserService)
    {
        _notificationService = notificationService;
        _currentUserService = currentUserService;
    }

    /// <summary>Danh sách thông báo của user đăng nhập.</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<NotificationDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] bool unreadOnly = false, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId();
        if (userId == null)
            return Unauthorized(new ApiErrorResponse("UNAUTHORIZED", "Không xác định được user."));
        var result = await _notificationService.GetListForUserAsync(userId.Value, unreadOnly, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<NotificationDto>>(result.Data!));
    }

    /// <summary>Đánh dấu đã đọc.</summary>
    [HttpPatch("{id:long}/read")]
    [ProducesResponseType(typeof(ApiSuccessResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> MarkRead(long id, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId();
        if (userId == null)
            return Unauthorized(new ApiErrorResponse("UNAUTHORIZED", "Không xác định được user."));
        var result = await _notificationService.MarkReadAsync(id, userId.Value, cancellationToken);
        if (!result.IsSuccess)
            return NotFound(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<object>(result.Data!));
    }

    /// <summary>Đánh dấu tất cả đã đọc.</summary>
    [HttpPatch("read-all")]
    [ProducesResponseType(typeof(ApiSuccessResponse<object>), StatusCodes.Status200OK)]
    public async Task<IActionResult> MarkAllRead(CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId();
        if (userId == null)
            return Unauthorized(new ApiErrorResponse("UNAUTHORIZED", "Không xác định được user."));
        var result = await _notificationService.MarkAllReadAsync(userId.Value, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<object>(result.Data!));
    }

    /// <summary>Ẩn thông báo.</summary>
    [HttpPatch("{id:long}/dismiss")]
    [ProducesResponseType(typeof(ApiSuccessResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Dismiss(long id, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId();
        if (userId == null)
            return Unauthorized(new ApiErrorResponse("UNAUTHORIZED", "Không xác định được user."));
        var result = await _notificationService.DismissAsync(id, userId.Value, cancellationToken);
        if (!result.IsSuccess)
            return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<object>(result.Data!));
    }

    /// <summary>Số thông báo chưa đọc.</summary>
    [HttpGet("unread-count")]
    [ProducesResponseType(typeof(ApiSuccessResponse<int>), StatusCodes.Status200OK)]
    public async Task<IActionResult> UnreadCount(CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId();
        if (userId == null)
            return Unauthorized(new ApiErrorResponse("UNAUTHORIZED", "Không xác định được user."));
        var result = await _notificationService.GetUnreadCountAsync(userId.Value, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<int>(result.Data));
    }

    /// <summary>Tạo thông báo (nội bộ / test). UserId trong body hoặc current user.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<NotificationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateNotificationRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId();
        if (userId == null)
            return Unauthorized(new ApiErrorResponse("UNAUTHORIZED", "Không xác định được user."));
        if (request.UserId <= 0)
            request.UserId = userId.Value;
        var result = await _notificationService.CreateAsync(request, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<NotificationDto>(result.Data!));
    }
}
