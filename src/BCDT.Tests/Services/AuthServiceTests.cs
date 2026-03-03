using BCDT.Application.DTOs.Auth;
using BCDT.Application.Services;
using BCDT.Domain.Entities.Authentication;
using BCDT.Infrastructure.Persistence;
using BCDT.Infrastructure.Services;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Options;
using Moq;
using Xunit;

namespace BCDT.Tests.Services;

public class AuthServiceTests
{
    private static AppDbContext CreateContext()
    {
        var options = new DbContextOptionsBuilder<AppDbContext>()
            .UseInMemoryDatabase(databaseName: Guid.NewGuid().ToString())
            .Options;
        return new AppDbContext(options);
    }

    private static (Mock<IJwtService> jwtMock, IOptions<JwtOptions> jwtOptions) CreateJwtMocks()
    {
        var mock = new Mock<IJwtService>();
        mock.Setup(x => x.GenerateAccessToken(It.IsAny<int>(), It.IsAny<string>(), It.IsAny<IEnumerable<string>?>()))
            .Returns("access-token");
        mock.Setup(x => x.GenerateRefreshToken()).Returns("refresh-token");
        var options = Options.Create(new JwtOptions
        {
            SecretKey = "test-key",
            Issuer = "test",
            Audience = "test",
            ExpiryMinutes = 60
        });
        return (mock, options);
    }

    [Fact]
    public async Task LoginAsync_UserNotFound_ReturnsUnauthorized()
    {
        await using var db = CreateContext();
        var (jwtMock, jwtOptions) = CreateJwtMocks();
        var sut = new AuthService(db, jwtMock.Object, jwtOptions);

        var result = await sut.LoginAsync(new LoginRequest { Username = "nobody", Password = "any" });

        Assert.False(result.IsSuccess);
        Assert.Equal("UNAUTHORIZED", result.Code);
    }

    [Fact]
    public async Task LoginAsync_WrongPassword_ReturnsUnauthorized()
    {
        await using var db = CreateContext();
        db.Users.Add(new User
        {
            Id = 1,
            Username = "u1",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("correct"),
            IsActive = true,
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        var (jwtMock, jwtOptions) = CreateJwtMocks();
        var sut = new AuthService(db, jwtMock.Object, jwtOptions);

        var result = await sut.LoginAsync(new LoginRequest { Username = "u1", Password = "wrong" });

        Assert.False(result.IsSuccess);
        Assert.Equal("UNAUTHORIZED", result.Code);
    }

    [Fact]
    public async Task LoginAsync_Success_ReturnsAccessAndRefreshToken()
    {
        await using var db = CreateContext();
        db.Users.Add(new User
        {
            Id = 1,
            Username = "u1",
            PasswordHash = BCrypt.Net.BCrypt.HashPassword("pass"),
            IsActive = true,
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        var (jwtMock, jwtOptions) = CreateJwtMocks();
        var sut = new AuthService(db, jwtMock.Object, jwtOptions);

        var result = await sut.LoginAsync(new LoginRequest { Username = "u1", Password = "pass" });

        Assert.True(result.IsSuccess);
        Assert.NotNull(result.Data);
        Assert.Equal("access-token", result.Data.AccessToken);
        Assert.Equal("refresh-token", result.Data.RefreshToken);
        Assert.NotNull(result.Data.User);
        Assert.Equal(1, result.Data.User.Id);
    }

    [Fact]
    public async Task RefreshAsync_TokenNotFound_ReturnsUnauthorized()
    {
        await using var db = CreateContext();
        var (jwtMock, jwtOptions) = CreateJwtMocks();
        var sut = new AuthService(db, jwtMock.Object, jwtOptions);

        var result = await sut.RefreshAsync(new RefreshRequest { RefreshToken = "invalid-token" });

        Assert.False(result.IsSuccess);
        Assert.Equal("UNAUTHORIZED", result.Code);
    }

    [Fact]
    public async Task RefreshAsync_RevokedToken_ReturnsUnauthorized()
    {
        await using var db = CreateContext();
        db.Users.Add(new User
        {
            Id = 1,
            Username = "u1",
            IsActive = true,
            IsDeleted = false,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = 1
        });
        await db.SaveChangesAsync();
        db.RefreshTokens.Add(new RefreshToken
        {
            UserId = 1,
            Token = "revoked-token",
            ExpiresAt = DateTime.UtcNow.AddDays(1),
            CreatedAt = DateTime.UtcNow,
            RevokedAt = DateTime.UtcNow
        });
        await db.SaveChangesAsync();
        var (jwtMock, jwtOptions) = CreateJwtMocks();
        var sut = new AuthService(db, jwtMock.Object, jwtOptions);

        var result = await sut.RefreshAsync(new RefreshRequest { RefreshToken = "revoked-token" });

        Assert.False(result.IsSuccess);
        Assert.Equal("UNAUTHORIZED", result.Code);
    }
}
