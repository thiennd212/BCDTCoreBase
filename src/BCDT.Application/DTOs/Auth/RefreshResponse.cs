namespace BCDT.Application.DTOs.Auth;

public class RefreshResponse
{
    public string AccessToken { get; set; } = string.Empty;
    public int ExpiresIn { get; set; }
    public string? RefreshToken { get; set; }
    public UserInfoDto? User { get; set; }
}
