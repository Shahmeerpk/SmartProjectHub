using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Security.Cryptography;
using System.Text;
using Api.Data;
using Api.Models;
using Api.Models.Dtos;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

namespace Api.Services;

public class AuthService : IAuthService
{
    private readonly AppDbContext _db;
    private readonly IConfiguration _config;

    public AuthService(AppDbContext db, IConfiguration config)
    {
        _db = db;
        _config = config;
    }

    public async Task<LoginResponse?> LoginAsync(LoginRequest request, CancellationToken ct = default)
    {
        var user = await _db.Users
            .Include(u => u.University)
            .FirstOrDefaultAsync(u => u.Email == request.Email && u.IsActive, ct);
        if (user == null) return null;

        if (!BCrypt.Net.BCrypt.Verify(request.Password, user.PasswordHash))
            return null;

        user.LastLoginAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);

        return await BuildLoginResponseAsync(user, ct);
    }

    public async Task<LoginResponse?> RegisterAsync(RegisterRequest request, CancellationToken ct = default)
    {
        if (await _db.Users.AnyAsync(u => u.Email == request.Email, ct))
            return null;

        var salt = BCrypt.Net.BCrypt.GenerateSalt();
        var hash = BCrypt.Net.BCrypt.HashPassword(request.Password, salt);

        var user = new User
        {
            Email = request.Email,
            PasswordHash = hash,
            PasswordSalt = salt,
            FullName = request.FullName,
            Role = request.Role,
            UniversityId = request.UniversityId,
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        _db.Users.Add(user);
        await _db.SaveChangesAsync(ct);
        await _db.Entry(user).Reference(u => u.University).LoadAsync(ct);

        return await BuildLoginResponseAsync(user, ct);
    }

    public async Task<bool> LogoutAsync(int userId, string? refreshToken, CancellationToken ct = default)
    {
        if (!string.IsNullOrWhiteSpace(refreshToken))
        {
            var token = await _db.RefreshTokens
                .FirstOrDefaultAsync(t => t.Token == refreshToken && t.UserId == userId && t.RevokedAt == null, ct);
            if (token != null)
            {
                token.RevokedAt = DateTime.UtcNow;
                await _db.SaveChangesAsync(ct);
            }
        }
        return true;
    }

    public async Task<LoginResponse?> RefreshTokensAsync(string refreshToken, CancellationToken ct = default)
    {
        var token = await _db.RefreshTokens
            .Include(t => t.User!)
            .ThenInclude(u => u.University)
            .FirstOrDefaultAsync(t => t.Token == refreshToken && t.RevokedAt == null && t.ExpiresAt > DateTime.UtcNow, ct);
        if (token?.User == null || !token.User.IsActive) return null;

        _db.RefreshTokens.Remove(token);
        await _db.SaveChangesAsync(ct);

        return await BuildLoginResponseAsync(token.User, ct);
    }

    private async Task<LoginResponse> BuildLoginResponseAsync(User user, CancellationToken ct)
    {
        var accessToken = GenerateAccessToken(user);
        var refreshToken = await SaveRefreshTokenAsync(user.Id, ct);
        var expiresMinutes = int.Parse(_config["Jwt:AccessTokenExpirationMinutes"] ?? "60");

        return new LoginResponse
        {
            AccessToken = accessToken,
            RefreshToken = refreshToken,
            ExpiresAt = DateTime.UtcNow.AddMinutes(expiresMinutes),
            User = new UserDto
            {
                Id = user.Id,
                Email = user.Email,
                FullName = user.FullName,
                Role = user.Role,
                UniversityId = user.UniversityId,
                UniversityName = user.University?.Name
            }
        };
    }

    private string GenerateAccessToken(User user)
    {
        var secret = _config["Jwt:Secret"] ?? throw new InvalidOperationException("Jwt:Secret not set");
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secret));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);
        var expiresMinutes = int.Parse(_config["Jwt:AccessTokenExpirationMinutes"] ?? "60");

        var claims = new[]
        {
            new Claim(ClaimTypes.NameIdentifier, user.Id.ToString()),
            new Claim(ClaimTypes.Email, user.Email),
            new Claim(ClaimTypes.Name, user.FullName),
            new Claim(ClaimTypes.Role, user.Role),
            new Claim("UniversityId", user.UniversityId.ToString())
        };

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"],
            audience: _config["Jwt:Audience"],
            claims: claims,
            expires: DateTime.UtcNow.AddMinutes(expiresMinutes),
            signingCredentials: creds
        );
        return new JwtSecurityTokenHandler().WriteToken(token);
    }

    private async Task<string> SaveRefreshTokenAsync(int userId, CancellationToken ct)
    {
        var token = Convert.ToBase64String(RandomNumberGenerator.GetBytes(64));
        var days = int.Parse(_config["Jwt:RefreshTokenExpirationDays"] ?? "7");
        _db.RefreshTokens.Add(new RefreshToken
        {
            UserId = userId,
            Token = token,
            ExpiresAt = DateTime.UtcNow.AddDays(days),
            CreatedAt = DateTime.UtcNow
        });
        await _db.SaveChangesAsync(ct);
        return token;
    }
}
