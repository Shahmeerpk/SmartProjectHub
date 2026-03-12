namespace Api.Models.Dtos;

public class UserDto
{
    public int Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string FullName { get; set; } = string.Empty;
    public string Role { get; set; } = string.Empty;
    public int UniversityId { get; set; }
    
    public string? UniversityName { get; set; }
    public string? Department { get; set; } // NAYI LINE
}
