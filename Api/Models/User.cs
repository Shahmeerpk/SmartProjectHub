namespace Api.Models;

public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string PasswordSalt { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Role { get; set; } = "Student"; // Student | Teacher
    public int UniversityId { get; set; }
    public string? Department { get; set; } // NAYI LINE
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }

    public University? University { get; set; }
    public string? RollNumber { get; set; } // Yeh line baqi properties ke sath dal dein
}
