using BCDT.Application.DTOs.Auth;

namespace BCDT.Application.Services;

public interface IAuthService
{
    Task<Common.Result<LoginResponse>> LoginAsync(LoginRequest request, string? ipAddress = null, CancellationToken cancellationToken = default);
    Task<Common.Result<RefreshResponse>> RefreshAsync(RefreshRequest request, CancellationToken cancellationToken = default);
    Task<Common.Result<object>> LogoutAsync(RefreshRequest request, string? ipAddress = null, CancellationToken cancellationToken = default);
    Task<UserInfoDto?> GetUserInfoAsync(int userId, CancellationToken cancellationToken = default);
    /// <summary>Danh sách vai trò của user hiện tại (để chuyển vai trò trên FE).</summary>
    Task<List<UserRoleItemDto>> GetMyRolesAsync(int userId, CancellationToken cancellationToken = default);
    /// <summary>Đổi mật khẩu cho user hiện tại (cần xác thực mật khẩu cũ).</summary>
    Task<Common.Result<object>> ChangePasswordAsync(int userId, ChangePasswordRequest request, CancellationToken cancellationToken = default);
}
