namespace Api.Models;

public class ChatMessage
{
    public int Id { get; set; }
    public int ChannelId { get; set; }
    public int UserId { get; set; }
    public string Content { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}