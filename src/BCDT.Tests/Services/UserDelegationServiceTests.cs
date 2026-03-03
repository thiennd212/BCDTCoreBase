using BCDT.Application.DTOs.Authorization;
using BCDT.Application.Services.Notification;
using BCDT.Domain.Entities.Authentication;
using BCDT.Domain.Entities.Authorization;
using BCDT.Infrastructure.Persistence;
using BCDT.Infrastructure.Services.Authorization;
using Hangfire;
using Microsoft.EntityFrameworkCore;
using Moq;
using Xunit;

namespace BCDT.Tests.Services;

public class UserDelegationServiceTests
{
    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static UserDelegationService CreateSut(AppDbContext db)
    {
        var notificationService = new Mock<INotificationService>();
        var backgroundJobs = new Mock<IBackgroundJobClient>();
        return new UserDelegationService(db, notificationService.Object, backgroundJobs.Object);
    }

    private static User MakeUser(int id, string username = "user") => new()
    {
        Id = id,
        Username = username,
        Email = $"{username}@test.com",
        FullName = username,
        IsActive = true,
    };

    private static CreateUserDelegationRequest ValidRequest(int fromId = 1, int toId = 2) => new()
    {
        FromUserId = fromId,
        ToUserId = toId,
        DelegationType = "Full",
        ValidFrom = DateTime.UtcNow.AddHours(-1),
        ValidTo = DateTime.UtcNow.AddDays(7),
    };

    // ── CreateAsync ─────────────────────────────────────────────────────────

    [Fact]
    public async Task CreateAsync_SelfDelegation_ReturnsValidationFailed()
    {
        await using var db = CreateContext();
        var sut = CreateSut(db);

        var req = ValidRequest(fromId: 1, toId: 1);
        var result = await sut.CreateAsync(req, createdBy: 99);

        Assert.False(result.IsSuccess);
        Assert.Equal("VALIDATION_FAILED", result.Code);
    }

    [Fact]
    public async Task CreateAsync_ValidToBeforeValidFrom_ReturnsValidationFailed()
    {
        await using var db = CreateContext();
        var sut = CreateSut(db);

        var req = ValidRequest();
        req.ValidTo = req.ValidFrom.AddHours(-1);
        var result = await sut.CreateAsync(req, createdBy: 99);

        Assert.False(result.IsSuccess);
        Assert.Equal("VALIDATION_FAILED", result.Code);
    }

    [Fact]
    public async Task CreateAsync_PartialMissingPermissions_ReturnsValidationFailed()
    {
        await using var db = CreateContext();
        db.Users.Add(MakeUser(1, "from"));
        db.Users.Add(MakeUser(2, "to"));
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var req = ValidRequest();
        req.DelegationType = "Partial";
        req.Permissions = null;
        var result = await sut.CreateAsync(req, createdBy: 99);

        Assert.False(result.IsSuccess);
        Assert.Equal("VALIDATION_FAILED", result.Code);
    }

    [Fact]
    public async Task CreateAsync_FromUserNotFound_ReturnsNotFound()
    {
        await using var db = CreateContext();
        db.Users.Add(MakeUser(2, "to")); // chỉ có toUser, không có fromUser
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var result = await sut.CreateAsync(ValidRequest(fromId: 1, toId: 2), createdBy: 99);

        Assert.False(result.IsSuccess);
        Assert.Equal("NOT_FOUND", result.Code);
    }

    [Fact]
    public async Task CreateAsync_OverlapConflict_ReturnsConflict()
    {
        await using var db = CreateContext();
        db.Users.Add(MakeUser(1, "from"));
        db.Users.Add(MakeUser(2, "to"));
        var existing = new UserDelegation
        {
            FromUserId = 1, ToUserId = 2, DelegationType = "Full",
            ValidFrom = DateTime.UtcNow.AddDays(-1), ValidTo = DateTime.UtcNow.AddDays(3),
            IsActive = true, CreatedAt = DateTime.UtcNow, CreatedBy = 99
        };
        db.UserDelegations.Add(existing);
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        // Tạo lần 2 với cùng khoảng thời gian overlap
        var result = await sut.CreateAsync(ValidRequest(1, 2), createdBy: 99);

        Assert.False(result.IsSuccess);
        Assert.Equal("CONFLICT", result.Code);
    }

    [Fact]
    public async Task CreateAsync_ValidRequest_CreatesAndReturnsDto()
    {
        await using var db = CreateContext();
        db.Users.Add(MakeUser(1, "from"));
        db.Users.Add(MakeUser(2, "to"));
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var result = await sut.CreateAsync(ValidRequest(1, 2), createdBy: 99);

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.Equal(1, result.Data!.FromUserId);
        Assert.Equal(2, result.Data.ToUserId);
        Assert.True(result.Data.IsActive);
        Assert.Equal(1, await db.UserDelegations.CountAsync());
    }

    // ── RevokeAsync ──────────────────────────────────────────────────────────

    [Fact]
    public async Task RevokeAsync_NotFound_ReturnsNotFound()
    {
        await using var db = CreateContext();
        var sut = CreateSut(db);

        var result = await sut.RevokeAsync(999, new RevokeUserDelegationRequest(), revokedBy: 99);

        Assert.False(result.IsSuccess);
        Assert.Equal("NOT_FOUND", result.Code);
    }

    [Fact]
    public async Task RevokeAsync_AlreadyRevoked_ReturnsConflict()
    {
        await using var db = CreateContext();
        var entity = new UserDelegation
        {
            FromUserId = 1, ToUserId = 2, DelegationType = "Full",
            ValidFrom = DateTime.UtcNow.AddDays(-1), ValidTo = DateTime.UtcNow.AddDays(3),
            IsActive = false, CreatedAt = DateTime.UtcNow, CreatedBy = 99
        };
        db.UserDelegations.Add(entity);
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var result = await sut.RevokeAsync(entity.Id, new RevokeUserDelegationRequest(), revokedBy: 99);

        Assert.False(result.IsSuccess);
        Assert.Equal("CONFLICT", result.Code);
    }

    [Fact]
    public async Task RevokeAsync_ActiveDelegation_SoftRevokes()
    {
        await using var db = CreateContext();
        var entity = new UserDelegation
        {
            FromUserId = 1, ToUserId = 2, DelegationType = "Full",
            ValidFrom = DateTime.UtcNow.AddDays(-1), ValidTo = DateTime.UtcNow.AddDays(3),
            IsActive = true, CreatedAt = DateTime.UtcNow, CreatedBy = 99
        };
        db.UserDelegations.Add(entity);
        await db.SaveChangesAsync();
        var sut = CreateSut(db);

        var result = await sut.RevokeAsync(entity.Id, new RevokeUserDelegationRequest { RevokedReason = "Test" }, revokedBy: 77);

        Assert.True(result.IsSuccess);
        Assert.False(result.Data!.IsActive);
        Assert.Equal("Test", result.Data.RevokedReason);
        Assert.Equal(77, result.Data.RevokedBy);
    }
}
