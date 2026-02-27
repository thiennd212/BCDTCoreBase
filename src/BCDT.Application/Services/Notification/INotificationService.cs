using BCDT.Application.Common;
using BCDT.Application.DTOs.Notification;

namespace BCDT.Application.Services.Notification;

public interface INotificationService
{
    Task<Result<List<NotificationDto>>> GetListForUserAsync(int userId, bool unreadOnly, CancellationToken cancellationToken = default);
    Task<Result<NotificationDto?>> GetByIdAsync(long id, int userId, CancellationToken cancellationToken = default);
    Task<Result<NotificationDto>> CreateAsync(CreateNotificationRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> MarkReadAsync(long id, int userId, CancellationToken cancellationToken = default);
    Task<Result<object>> MarkAllReadAsync(int userId, CancellationToken cancellationToken = default);
    Task<Result<object>> DismissAsync(long id, int userId, CancellationToken cancellationToken = default);
    Task<Result<int>> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default);
}
