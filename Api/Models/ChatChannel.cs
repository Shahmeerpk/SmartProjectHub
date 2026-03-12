namespace Api.Models;

public class ChatChannel
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public string ChannelType { get; set; } = string.Empty; // 'Private', 'University', 'Global'
    public int? ProjectId { get; set; }
    public int? UniversityId { get; set; }
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
    public string? Department { get; set; }
}