using Api.Models.Dtos;

namespace Api.Services;

public interface IAuthService
{
    Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken ct = default);
    Task<LoginResponse?> RegisterAsync(RegisterRequest request, CancellationToken ct = default);
    Task<bool> LogoutAsync(int userId, string? refreshToken, CancellationToken ct = default);
    Task<LoginResponse?> RefreshTokensAsync(string refreshToken, CancellationToken ct = default);
}
