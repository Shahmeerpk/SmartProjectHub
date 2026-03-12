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

    [HttpPost("login")]
    public async Task<IActionResult> Login([FromBody] LoginRequest request, CancellationToken ct)
    {
        try 
        {
            var result = await _authService.LoginAsync(request, ct);
            if (result == null)
                return Unauthorized(new { message = "Invalid email or password." });
            return Ok(result);
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = "Login Error: " + (ex.InnerException?.Message ?? ex.Message) });
        }
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterRequest request, CancellationToken ct)
    {
        try
        {
            if (request.Role != "Student" && request.Role != "Teacher" && request.Role != "HOD")
                return BadRequest(new { message = "Role must be Student, Teacher, or HOD." });
            
            var result = await _authService.RegisterAsync(request, ct);
            if (result == null)
                return BadRequest(new { message = "This email is already registered. Please use another one." });
            
            return Ok(result);
        }
        catch (Exception ex)
        {
            var errorMsg = ex.InnerException?.Message ?? ex.Message;
            
            if (errorMsg.Contains("UNIQUE KEY") || errorMsg.Contains("duplicate"))
                return BadRequest(new { message = "Database Error: This Roll Number is already registered!" });
                
            return BadRequest(new { message = $"Database Error: {errorMsg}" });
        }
    }

    [HttpPost("logout")]
    [Authorize]
    public async Task<IActionResult> Logout([FromBody] LogoutRequest? body, CancellationToken ct)
    {
        var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
            return Unauthorized();
        await _authService.LogoutAsync(userId, body?.RefreshToken, ct);
        return Ok(new { message = "Logged out successfully." });
    }

    [HttpPost("refresh")]
    public async Task<IActionResult> Refresh([FromBody] RefreshRequest request, CancellationToken ct)
    {
        var result = await _authService.RefreshTokensAsync(request.RefreshToken, ct);
        if (result == null)
            return Unauthorized(new { message = "Invalid or expired refresh token." });
        return Ok(result);
    }

    // 🔥 NAYA: DP Upload karne ka function ab yahan class ke ANDAR hai 🔥
    [HttpPost("profile-picture")]
    [Authorize]
    public async Task<IActionResult> UploadProfilePicture(IFormFile file, [FromServices] IWebHostEnvironment env, [FromServices] Api.Data.AppDbContext db, CancellationToken ct)
    {
        try 
        {
            if (file == null || file.Length == 0) return BadRequest(new { message = "No image selected." });
            
            var userIdClaim = User.FindFirstValue(ClaimTypes.NameIdentifier);
            if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId)) return Unauthorized();

            var user = await db.Users.FindAsync(new object[] { userId }, ct);
            if (user == null) return NotFound(new { message = "User not found." });

            var webRoot = env.WebRootPath ?? Path.Combine(Directory.GetCurrentDirectory(), "wwwroot");
            var uploadsFolder = Path.Combine(webRoot, "uploads", "profiles");
            if (!Directory.Exists(uploadsFolder)) Directory.CreateDirectory(uploadsFolder);

            var ext = Path.GetExtension(file.FileName);
            var uniqueFileName = $"user_{userId}_{Guid.NewGuid().ToString().Substring(0,6)}{ext}";
            var filePath = Path.Combine(uploadsFolder, uniqueFileName);

            using (var stream = new FileStream(filePath, FileMode.Create))
            {
                await file.CopyToAsync(stream, ct);
            }

            user.ProfilePictureUrl = $"/uploads/profiles/{uniqueFileName}";
            await db.SaveChangesAsync(ct);

            return Ok(new { profilePictureUrl = user.ProfilePictureUrl });
        }
        catch (Exception ex)
        {
            return BadRequest(new { message = "Upload failed: " + ex.Message });
        }
    }
}

// Yeh class sab se aakhir mein honi chahiye
public class RefreshRequest
{
    public string RefreshToken { get; set; } = string.Empty;
}