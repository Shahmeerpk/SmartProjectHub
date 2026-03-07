using System.ComponentModel.DataAnnotations;

namespace Api.Models.Dtos;

public class RegisterRequest
{
    [Required, EmailAddress]
    public string Email { get; set; } = string.Empty;

    [Required, MinLength(6)]
    public string Password { get; set; } = string.Empty;

    [Required, MaxLength(200)]
    public string FullName { get; set; } = string.Empty;

    [Required]
    public string Role { get; set; } = "Student"; // Student | Teacher

    public int UniversityId { get; set; }
}
