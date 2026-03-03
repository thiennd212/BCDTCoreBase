using BCDT.Application.Common;
using BCDT.Application.DTOs.Auth;
using BCDT.Application.Services;
using BCDT.Domain.Entities.Authentication;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    private readonly IJwtService _jwtService;
    private readonly JwtOptions _jwtOptions;
    private const int RefreshTokenExpiryDays = 7;

    public AuthService(AppDbContext db, IJwtService jwtService, Microsoft.Extensions.Options.IOptions<JwtOptions> jwtOptions)
    {
        _db = db;
        _jwtService = jwtService;
        _jwtOptions = jwtOptions.Value;
    }

    private async Task<List<string>> GetUserRoleCodesAsync(int userId, CancellationToken cancellationToken)
    {
        return await _db.UserRoles
            .AsNoTracking()
            .Where(ur => ur.UserId == userId && ur.IsActive)
            .Join(_db.Roles.AsNoTracking(), ur => ur.RoleId, r => r.Id, (ur, r) => r.Code)
            .ToListAsync(cancellationToken);
    }

    public async Task<Result<LoginResponse>> LoginAsync(LoginRequest request, string? ipAddress = null, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users
            .AsNoTracking()
            .FirstOrDefaultAsync(u => u.Username == request.Username && !u.IsDeleted && u.IsActive, cancellationToken);

        if (user == null || string.IsNullOrEmpty(user.PasswordHash))
            return Result.Fail<LoginResponse>("UNAUTHORIZED", "Sai tên đăng nhập hoặc mật khẩu.");

        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return Result.Fail<LoginResponse>("UNAUTHORIZED", "Sai tên đăng nhập hoặc mật khẩu.");

        var roleCodes = await GetUserRoleCodesAsync(user.Id, cancellationToken);
        var accessToken = _jwtService.GenerateAccessToken(user.Id, user.Username, roleCodes);
        var refreshTokenValue = _jwtService.GenerateRefreshToken();
        var expiresAt = DateTime.UtcNow.AddDays(RefreshTokenExpiryDays);

        var refreshToken = new RefreshToken
        {
            UserId = user.Id,
            Token = refreshTokenValue,
            ExpiresAt = expiresAt,
            CreatedByIp = ipAddress
        };
        _db.RefreshTokens.Add(refreshToken);
        await _db.SaveChangesAsync(cancellationToken);

        var expiresInSeconds = _jwtOptions.ExpiryMinutes * 60;
        return Result.Ok(new LoginResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshTokenValue,
            ExpiresIn = expiresInSeconds,
            User = new UserInfoDto
            {
                Id = user.Id,
                Username = user.Username,
                Email = user.Email,
                FullName = user.FullName,
                IsActive = user.IsActive
            }
        });
    }

    public async Task<Result<RefreshResponse>> RefreshAsync(RefreshRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.RefreshTokens
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Token == request.RefreshToken && r.RevokedAt == null && r.ExpiresAt > DateTime.UtcNow, cancellationToken);

        if (entity == null)
            return Result.Fail<RefreshResponse>("UNAUTHORIZED", "Refresh token không hợp lệ hoặc đã hết hạn.");

        var user = entity.User;
        if (!user.IsActive || user.IsDeleted)
            return Result.Fail<RefreshResponse>("UNAUTHORIZED", "Tài khoản không còn hoạt động.");

        // Refresh token rotation: revoke old, issue new
        var newRefreshTokenValue = _jwtService.GenerateRefreshToken();
        var expiresAt = DateTime.UtcNow.AddDays(RefreshTokenExpiryDays);

        entity.RevokedAt = DateTime.UtcNow;
        entity.ReplacedByToken = newRefreshTokenValue;

        var newRefreshToken = new RefreshToken
        {
            UserId = user.Id,
            Token = newRefreshTokenValue,
            ExpiresAt = expiresAt,
            CreatedByIp = null
        };
        _db.RefreshTokens.Add(newRefreshToken);
        await _db.SaveChangesAsync(cancellationToken);

        var roleCodes = await GetUserRoleCodesAsync(user.Id, cancellationToken);
        var accessToken = _jwtService.GenerateAccessToken(user.Id, user.Username, roleCodes);
        var expiresInSeconds = _jwtOptions.ExpiryMinutes * 60;

        return Result.Ok(new RefreshResponse
        {
            AccessToken = accessToken,
            ExpiresIn = expiresInSeconds,
            RefreshToken = newRefreshTokenValue,
            User = new UserInfoDto { Id = user.Id, Username = user.Username, Email = user.Email, FullName = user.FullName, IsActive = user.IsActive }
        });
    }

    public async Task<Result<object>> LogoutAsync(RefreshRequest request, string? ipAddress = null, CancellationToken cancellationToken = default)
    {
        var entity = await _db.RefreshTokens
            .Include(r => r.User)
            .FirstOrDefaultAsync(r => r.Token == request.RefreshToken && r.RevokedAt == null, cancellationToken);
        if (entity != null)
        {
            entity.RevokedAt = DateTime.UtcNow;
            entity.RevokedByIp = ipAddress;
            var user = entity.User;
            if (user != null)
            {
                user.LastLogoutAt = DateTime.UtcNow;
            }
            await _db.SaveChangesAsync(cancellationToken);
        }
        return Result.Ok<object>(null!);
    }

    public async Task<UserInfoDto?> GetUserInfoAsync(int userId, CancellationToken cancellationToken = default)
    {
        var user = await _db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == userId && !u.IsDeleted && u.IsActive, cancellationToken);
        if (user == null) return null;
        return new UserInfoDto { Id = user.Id, Username = user.Username, Email = user.Email, FullName = user.FullName, IsActive = user.IsActive };
    }

    public async Task<List<UserRoleItemDto>> GetMyRolesAsync(int userId, CancellationToken cancellationToken = default)
    {
        var list = await (
            from ur in _db.UserRoles.AsNoTracking().Where(ur => ur.UserId == userId && ur.IsActive)
            join r in _db.Roles.AsNoTracking() on ur.RoleId equals r.Id
            where r.IsActive
            join o in _db.Organizations.AsNoTracking() on ur.OrganizationId equals o.Id into orgJoin
            from o in orgJoin.DefaultIfEmpty()
            orderby r.Name, o != null ? o.Name : ""
            select new UserRoleItemDto
            {
                Id = r.Id,
                Code = r.Code,
                Name = r.Name,
                OrganizationId = ur.OrganizationId,
                OrganizationName = o != null ? o.Name : null
            }
        ).ToListAsync(cancellationToken);
        return list;
    }

    public async Task<Result<object>> ChangePasswordAsync(int userId, ChangePasswordRequest request, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(request.NewPassword) || request.NewPassword.Length < 6)
            return Result.Fail<object>("VALIDATION_FAILED", "Mật khẩu mới tối thiểu 6 ký tự.");

        var user = await _db.Users.FirstOrDefaultAsync(u => u.Id == userId && !u.IsDeleted && u.IsActive, cancellationToken);
        if (user == null)
            return Result.Fail<object>("NOT_FOUND", "Người dùng không tồn tại.");

        if (string.IsNullOrEmpty(user.PasswordHash) || !BCrypt.Net.BCrypt.Verify(request.CurrentPassword, user.PasswordHash))
            return Result.Fail<object>("UNAUTHORIZED", "Mật khẩu hiện tại không đúng.");

        user.PasswordHash = BCrypt.Net.BCrypt.HashPassword(request.NewPassword);
        user.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok<object>(null!);
    }
}
