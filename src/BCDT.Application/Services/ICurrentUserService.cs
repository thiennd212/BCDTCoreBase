namespace BCDT.Application.Services;

/// <summary>Prod-10 (R6): Abstraction lấy UserId từ request hiện tại. Thay thế GetCurrentUserId/GetUserId trùng lặp trong controller.</summary>
public interface ICurrentUserService
{
    /// <summary>UserId từ claim NameIdentifier; null nếu chưa đăng nhập hoặc claim không hợp lệ.</summary>
    int? GetUserId();
}
