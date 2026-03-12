namespace Api.Models;

public class User
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public string PasswordSalt { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Role { get; set; } = "Student"; // Student | Teacher | HOD
    public int UniversityId { get; set; }
    
    // 🔥 YEH DONO LINES LAZMI HAIN 🔥
    public string? Department { get; set; } 
    public string? ProfilePictureUrl { get; set; } 
    
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }
    public DateTime? LastLoginAt { get; set; }

    public University? University { get; set; }
    public string? RollNumber { get; set; } 
}