using BCDT.Application.Common;
using BCDT.Application.DTOs.Notification;
using BCDT.Application.Services.Notification;
using BCDT.Domain.Entities.Notification;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Notification;

public class NotificationService : INotificationService
{
    private readonly AppDbContext _db;

    public NotificationService(AppDbContext db) => _db = db;

    public async Task<Result<List<NotificationDto>>> GetListForUserAsync(int userId, bool unreadOnly, CancellationToken cancellationToken = default)
    {
        var query = _db.Notifications
            .AsNoTracking()
            .Where(n => n.UserId == userId);
        if (unreadOnly)
            query = query.Where(n => !n.IsRead && !n.IsDismissed);
        var list = await query
            .OrderByDescending(n => n.CreatedAt)
            .Select(n => MapToDto(n))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<NotificationDto?>> GetByIdAsync(long id, int userId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Notifications
            .AsNoTracking()
            .Where(n => n.Id == id && n.UserId == userId)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Ok<NotificationDto?>(null);
        return Result.Ok<NotificationDto?>(MapToDto(entity));
    }

    public async Task<Result<NotificationDto>> CreateAsync(CreateNotificationRequest request, CancellationToken cancellationToken = default)
    {
        var entity = new Domain.Entities.Notification.Notification
        {
            UserId = request.UserId,
            Type = request.Type,
            Title = request.Title,
            Message = request.Message,
            Priority = request.Priority,
            EntityType = request.EntityType,
            EntityId = request.EntityId,
            ActionUrl = request.ActionUrl,
            Channels = request.Channels,
            IsRead = false,
            IsDismissed = false,
            CreatedAt = DateTime.UtcNow
        };
        _db.Notifications.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> MarkReadAsync(long id, int userId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Notifications
            .Where(n => n.Id == id && n.UserId == userId)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Thông báo không tồn tại hoặc không thuộc user.");
        entity.IsRead = true;
        entity.ReadAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    public async Task<Result<object>> MarkAllReadAsync(int userId, CancellationToken cancellationToken = default)
    {
        var unread = await _db.Notifications
            .Where(n => n.UserId == userId && !n.IsRead && !n.IsDismissed)
            .ToListAsync(cancellationToken);
        foreach (var n in unread)
        {
            n.IsRead = true;
            n.ReadAt = DateTime.UtcNow;
        }
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { count = unread.Count });
    }

    public async Task<Result<object>> DismissAsync(long id, int userId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Notifications
            .Where(n => n.Id == id && n.UserId == userId)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Thông báo không tồn tại hoặc không thuộc user.");
        entity.IsDismissed = true;
        entity.DismissedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    public async Task<Result<int>> GetUnreadCountAsync(int userId, CancellationToken cancellationToken = default)
    {
        var count = await _db.Notifications
            .CountAsync(n => n.UserId == userId && !n.IsRead && !n.IsDismissed, cancellationToken);
        return Result.Ok(count);
    }

    private static NotificationDto MapToDto(Domain.Entities.Notification.Notification n)
    {
        return new NotificationDto
        {
            Id = n.Id,
            UserId = n.UserId,
            Type = n.Type,
            Title = n.Title,
            Message = n.Message,
            Priority = n.Priority,
            EntityType = n.EntityType,
            EntityId = n.EntityId,
            ActionUrl = n.ActionUrl,
            Channels = n.Channels,
            IsRead = n.IsRead,
            ReadAt = n.ReadAt,
            CreatedAt = n.CreatedAt,
            ExpiresAt = n.ExpiresAt
        };
    }
}
