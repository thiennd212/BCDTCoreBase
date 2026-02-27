namespace BCDT.Application.Services;

public interface IJwtService
{
    string GenerateAccessToken(int userId, string username, IEnumerable<string>? roles = null);
    string GenerateRefreshToken();
}
