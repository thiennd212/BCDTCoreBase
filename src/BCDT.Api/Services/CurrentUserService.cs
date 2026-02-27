using System.Security.Claims;
using BCDT.Application.Services;
using Microsoft.AspNetCore.Http;

namespace BCDT.Api.Services;

/// <summary>Prod-10 (R6): Lấy UserId từ HttpContext.User (JWT claim NameIdentifier).</summary>
public class CurrentUserService : ICurrentUserService
{
    private readonly IHttpContextAccessor _httpContextAccessor;

    public CurrentUserService(IHttpContextAccessor httpContextAccessor)
    {
        _httpContextAccessor = httpContextAccessor;
    }

    public int? GetUserId()
    {
        var user = _httpContextAccessor.HttpContext?.User;
        if (user?.Identity?.IsAuthenticated != true)
            return null;
        var claim = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(claim, out var id) ? id : null;
    }
}
