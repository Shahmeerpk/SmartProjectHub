using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Api.Data;     // AppDbContext yahan se aayega
using Api.Models;   // ChatChannels ka model yahan se aayega

namespace Api.Controllers  // <-- Asli Fix yahan hai! Project ka naam 'Api' hai.
{
    [Route("api/[controller]")]
    [ApiController]
    public class ChatController : ControllerBase
    {
        private readonly AppDbContext _context;

        public ChatController(AppDbContext context)
        {
            _context = context;
        }

        // GET: api/chat/channels
        [HttpGet("channels")]
        public async Task<IActionResult> GetChannels()
        {
            var channels = await _context.ChatChannels.ToListAsync();
            return Ok(channels);
        }
        // GET: api/chat/{channelId}/messages
        [HttpGet("{channelId}/messages")]
        public async Task<IActionResult> GetMessages(int channelId)
        {
            // Database se is kamre ke saare purane messages uthao
            var messages = await _context.ChatMessages
                .Where(m => m.ChannelId == channelId)
                .OrderBy(m => m.CreatedAt) // Purane pehle, naye baad mein
                .Select(m => new {
                    userId = m.UserId.ToString(),
                    text = m.Content
                })
                .ToListAsync();

            return Ok(messages);
        }
    }
}