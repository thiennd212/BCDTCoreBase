using BCDT.Application.Common;
using BCDT.Application.DTOs.Authorization;
using BCDT.Application.DTOs.Notification;
using BCDT.Application.Services.Authorization;
using BCDT.Application.Services.Notification;
using BCDT.Domain.Entities.Authorization;
using BCDT.Infrastructure.Jobs;
using BCDT.Infrastructure.Persistence;
using Hangfire;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Authorization;

public class UserDelegationService : IUserDelegationService
{
    private readonly AppDbContext _db;
    private readonly INotificationService _notificationService;
    private readonly IBackgroundJobClient _backgroundJobs;

    public UserDelegationService(AppDbContext db, INotificationService notificationService, IBackgroundJobClient backgroundJobs)
    {
        _db = db;
        _notificationService = notificationService;
        _backgroundJobs = backgroundJobs;
    }

    public async Task<Result<List<UserDelegationDto>>> GetListAsync(int? fromUserId, int? toUserId, bool activeOnly, CancellationToken cancellationToken = default)
    {
        var query = _db.UserDelegations.AsNoTracking();
        if (fromUserId.HasValue)
            query = query.Where(d => d.FromUserId == fromUserId.Value);
        if (toUserId.HasValue)
            query = query.Where(d => d.ToUserId == toUserId.Value);
        if (activeOnly)
            query = query.Where(d => d.IsActive && d.ValidFrom <= DateTime.UtcNow && d.ValidTo >= DateTime.UtcNow);

        var list = await query
            .OrderByDescending(d => d.CreatedAt)
            .Select(d => MapToDto(d,
                _db.Users.Where(u => u.Id == d.FromUserId).Select(u => u.FullName).FirstOrDefault(),
                _db.Users.Where(u => u.Id == d.ToUserId).Select(u => u.FullName).FirstOrDefault()))
            .ToListAsync(cancellationToken);

        return Result.Ok(list);
    }

    public async Task<Result<UserDelegationDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.UserDelegations.AsNoTracking()
            .FirstOrDefaultAsync(d => d.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<UserDelegationDto?>("NOT_FOUND", "Ủy quyền không tồn tại.");
        var fromName = await _db.Users.Where(u => u.Id == entity.FromUserId).Select(u => u.FullName).FirstOrDefaultAsync(cancellationToken);
        var toName = await _db.Users.Where(u => u.Id == entity.ToUserId).Select(u => u.FullName).FirstOrDefaultAsync(cancellationToken);
        return Result.Ok<UserDelegationDto?>(MapToDto(entity, fromName, toName));
    }

    public async Task<Result<UserDelegationDto>> CreateAsync(CreateUserDelegationRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        if (request.FromUserId == request.ToUserId)
            return Result.Fail<UserDelegationDto>("VALIDATION_FAILED", "Không thể ủy quyền cho chính mình.");

        if (request.ValidTo <= request.ValidFrom)
            return Result.Fail<UserDelegationDto>("VALIDATION_FAILED", "ValidTo phải lớn hơn ValidFrom.");

        if (request.DelegationType != "Full" && request.DelegationType != "Partial")
            return Result.Fail<UserDelegationDto>("VALIDATION_FAILED", "DelegationType phải là Full hoặc Partial.");

        if (request.DelegationType == "Partial" && string.IsNullOrWhiteSpace(request.Permissions))
            return Result.Fail<UserDelegationDto>("VALIDATION_FAILED", "Permissions bắt buộc khi DelegationType = Partial.");

        var fromExists = await _db.Users.AnyAsync(u => u.Id == request.FromUserId && u.IsActive, cancellationToken);
        if (!fromExists)
            return Result.Fail<UserDelegationDto>("NOT_FOUND", "Người ủy quyền không tồn tại hoặc không hoạt động.");

        var toExists = await _db.Users.AnyAsync(u => u.Id == request.ToUserId && u.IsActive, cancellationToken);
        if (!toExists)
            return Result.Fail<UserDelegationDto>("NOT_FOUND", "Người được ủy quyền không tồn tại hoặc không hoạt động.");

        // Kiểm tra trùng: cùng From-To-Org đang active và thời gian overlap
        var overlap = await _db.UserDelegations.AnyAsync(d =>
            d.FromUserId == request.FromUserId &&
            d.ToUserId == request.ToUserId &&
            d.OrganizationId == request.OrganizationId &&
            d.IsActive &&
            d.ValidFrom < request.ValidTo &&
            d.ValidTo > request.ValidFrom,
            cancellationToken);
        if (overlap)
            return Result.Fail<UserDelegationDto>("CONFLICT", "Đã có ủy quyền active cho cặp người dùng này trong khoảng thời gian trùng.");

        var entity = new UserDelegation
        {
            FromUserId = request.FromUserId,
            ToUserId = request.ToUserId,
            DelegationType = request.DelegationType,
            Permissions = request.DelegationType == "Partial" ? request.Permissions : null,
            OrganizationId = request.OrganizationId,
            Reason = request.Reason,
            ValidFrom = request.ValidFrom,
            ValidTo = request.ValidTo,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };

        _db.UserDelegations.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        var fromName = await _db.Users.Where(u => u.Id == entity.FromUserId).Select(u => u.FullName).FirstOrDefaultAsync(cancellationToken);
        var toName = await _db.Users.Where(u => u.Id == entity.ToUserId).Select(u => u.FullName).FirstOrDefaultAsync(cancellationToken);

        // Thông báo cho người được ủy quyền (ToUser)
        await NotifyUserAsync(entity.ToUserId, "Delegation", entity.Id.ToString(),
            "Bạn được ủy quyền",
            $"{fromName ?? $"Người dùng #{entity.FromUserId}"} đã ủy quyền cho bạn từ {entity.ValidFrom:dd/MM/yyyy} đến {entity.ValidTo:dd/MM/yyyy}.",
            cancellationToken);

        return Result.Ok(MapToDto(entity, fromName, toName));
    }

    public async Task<Result<UserDelegationDto>> RevokeAsync(int id, RevokeUserDelegationRequest request, int revokedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.UserDelegations.FirstOrDefaultAsync(d => d.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<UserDelegationDto>("NOT_FOUND", "Ủy quyền không tồn tại.");
        if (!entity.IsActive)
            return Result.Fail<UserDelegationDto>("CONFLICT", "Ủy quyền đã được thu hồi trước đó.");

        entity.IsActive = false;
        entity.RevokedAt = DateTime.UtcNow;
        entity.RevokedBy = revokedBy;
        entity.RevokedReason = request.RevokedReason;
        await _db.SaveChangesAsync(cancellationToken);
        var fromName = await _db.Users.Where(u => u.Id == entity.FromUserId).Select(u => u.FullName).FirstOrDefaultAsync(cancellationToken);
        var toName = await _db.Users.Where(u => u.Id == entity.ToUserId).Select(u => u.FullName).FirstOrDefaultAsync(cancellationToken);

        // Thông báo cho người được ủy quyền (ToUser) khi bị thu hồi
        await NotifyUserAsync(entity.ToUserId, "Delegation", entity.Id.ToString(),
            "Ủy quyền đã bị thu hồi",
            $"Ủy quyền từ {fromName ?? $"Người dùng #{entity.FromUserId}"} đã bị thu hồi. Lý do: {request.RevokedReason ?? "Không có."}",
            cancellationToken);

        return Result.Ok(MapToDto(entity, fromName, toName));
    }

    private async Task NotifyUserAsync(int userId, string entityType, string entityId, string title, string message, CancellationToken cancellationToken)
    {
        try
        {
            await _notificationService.CreateAsync(new CreateNotificationRequest
            {
                UserId = userId,
                Type = "System",
                Title = title,
                Message = message,
                Priority = "Normal",
                EntityType = entityType,
                EntityId = entityId,
                Channels = "InApp"
            }, cancellationToken);

            var userEmail = await _db.Users
                .Where(u => u.Id == userId)
                .Select(u => u.Email)
                .FirstOrDefaultAsync(cancellationToken);

            if (!string.IsNullOrWhiteSpace(userEmail))
                _backgroundJobs.Enqueue<NotificationDispatchJob>(j => j.ExecuteAsync(userEmail, title, message, CancellationToken.None));
        }
        catch (Exception)
        {
            // Notification failure không làm gián đoạn flow chính
        }
    }

    private static UserDelegationDto MapToDto(UserDelegation d, string? fromName = null, string? toName = null) => new()
    {
        Id = d.Id,
        FromUserId = d.FromUserId,
        FromUserName = fromName,
        ToUserId = d.ToUserId,
        ToUserName = toName,
        DelegationType = d.DelegationType,
        Permissions = d.Permissions,
        OrganizationId = d.OrganizationId,
        Reason = d.Reason,
        ValidFrom = d.ValidFrom,
        ValidTo = d.ValidTo,
        IsActive = d.IsActive,
        CreatedAt = d.CreatedAt,
        CreatedBy = d.CreatedBy,
        RevokedAt = d.RevokedAt,
        RevokedBy = d.RevokedBy,
        RevokedReason = d.RevokedReason
    };
}
