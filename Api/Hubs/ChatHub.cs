using Api.Data;
using Api.Models;
using Microsoft.AspNetCore.SignalR;

namespace Api.Hubs;

public class ChatHub : Hub
{
    private readonly AppDbContext _context;

    public ChatHub(AppDbContext context)
    {
        _context = context;
    }

    public async Task JoinChannel(int channelId)
    {
        await Groups.AddToGroupAsync(Context.ConnectionId, $"Channel_{channelId}");
        await Clients.Group($"Channel_{channelId}").SendAsync("ReceiveSystemMessage", "🤖 System: A user joined the chat.");
    }

   public async Task SendMessage(int channelId, int userId, string content)
    {
        var chatMessage = new ChatMessage 
        {
            ChannelId = channelId,
            UserId = userId,
            Content = content,
            CreatedAt = DateTime.UtcNow
        };
        _context.ChatMessages.Add(chatMessage);
        await _context.SaveChangesAsync();

        // 🔥 NAYA: Message bhejne walay ki detail nikalo
        var user = await _context.Users.FindAsync(userId);
        var senderName = user?.FullName ?? "Unknown";
        var dpUrl = user?.ProfilePictureUrl;

        // 🔥 Ab 2 ke bajaye 4 cheezein SignalR se jayengi!
        await Clients.Group($"Channel_{channelId}").SendAsync("ReceiveMessage", userId, content, senderName, dpUrl);
    }

    public async Task LeaveChannel(int channelId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Channel_{channelId}");
    }
}