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
        // 1. Database mein message save karein
        var chatMessage = new ChatMessage 
        {
            ChannelId = channelId,
            UserId = userId,
            Content = content,
            CreatedAt = DateTime.UtcNow
        };
        _context.ChatMessages.Add(chatMessage);
        await _context.SaveChangesAsync();

        // 2. Real-time mein sab ko message bhejein
        await Clients.Group($"Channel_{channelId}").SendAsync("ReceiveMessage", userId, content);
    }

    public async Task LeaveChannel(int channelId)
    {
        await Groups.RemoveFromGroupAsync(Context.ConnectionId, $"Channel_{channelId}");
    }
}