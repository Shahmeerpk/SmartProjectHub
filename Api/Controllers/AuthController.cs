using System.Security.Claims;
using Api.Models.Dtos;
using Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class AuthController : ControllerBase
{
    private readonly IAuthService _authService;

    public AuthController(IAuthService authService)
    {
        _authService = authService;
    }

    /// <summary>Login for Students and Teachers. Returns JWT access + refresh token.</summary>
    [HttpPost("login")]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken ct)
    {
        var result = await _authService.LoginAsync(request, ct);
        if (result == null)
            return Unauthorized(new { message = "Invalid email or password." });
        return Ok(result);
    }

    /// <summary>Register a new Student or Teacher.</summary>
    [HttpPost("register")]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken ct)
    {
        if (request.Role != "Student" && request.Role != "Teacher")
            return BadRequest(new { message = "Role must be Student or Teacher." });
        var result = await _authService.RegisterAsync(request, ct);
        if (result == null)
            return BadRequest(new { message = "Email already registered." });
        return Ok(result);
    }

    /// <summary>Logout: revoke refresh token. Optional body with refreshToken.</summary>
    [HttpPost("logout")]
    [Authorize]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest? body, CancellationToken ct)
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();
        await _authService.LogoutAsync(userId, body?.RefreshToken, ct);
        return Ok(new { message = "Logged out successfully." });
    }

    /// <summary>Get new access token using refresh token.</summary>
    [HttpPost("refresh")]
    [ProducesResponseType(typeof(LoginResponse), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status401Unauthorized)]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request, CancellationToken ct)
    {
        if (string.IsNullOrWhiteSpace(request.RefreshToken))
            return Unauthorized(new { message = "Refresh token required." });
        var result = await _authService.RefreshTokensAsync(request.RefreshToken, ct);
        if (result == null)
            return Unauthorized(new { message = "Invalid or expired refresh token." });
        return Ok(result);
    }
}

public class RefreshRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}
