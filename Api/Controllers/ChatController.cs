using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Api.Data;     
using Api.Models;   

namespace Api.Controllers
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

        // 🔥 NAYA: User ko sirf apni channels dikhani hain (Sath HOD ka Jadoo bhi) 🔥
        [HttpGet("channels/{userId}/{role}")]
        public async Task<IActionResult> GetChannels(int userId, string role)
        {
            var user = await _context.Users.FindAsync(userId);
            if (user == null) return Unauthorized();

            var allChannels = await _context.ChatChannels.ToListAsync();
            var filteredChannels = new List<ChatChannel>();

            foreach (var ch in allChannels)
            {
                if (ch.ChannelType == "Global") 
                {
                    filteredChannels.Add(ch);
                }
                else if (ch.ChannelType == "University" && ch.UniversityId == user.UniversityId) 
                {
                    filteredChannels.Add(ch);
                }
                else if (ch.ChannelType == "Private" && ch.ProjectId != null) 
                {
                    var project = await _context.Projects.Include(p => p.Student).FirstOrDefaultAsync(p => p.Id == ch.ProjectId);
                    if (project != null) 
                    {
                        // 1. Student ko sirf apne project ki chat dikhegi
                        if (role == "Student" && project.StudentId == userId) 
                        {
                            filteredChannels.Add(ch);
                        }
                        // 2. Teacher ko apni university ke private projects ki
                        else if (role == "Teacher" && project.UniversityId == user.UniversityId) 
                        {
                            filteredChannels.Add(ch);
                        }
                        // 3. 🔥 NAYA HOD FEATURE: HOD sirf apne department ki chat dekhega
                        else if (role == "HOD" && project.UniversityId == user.UniversityId && project.Student != null && project.Student.Department == user.Department)
                        {
                            filteredChannels.Add(ch);
                        }
                    }
                }
            }

            return Ok(filteredChannels);
        }

        [HttpGet("{channelId}/messages")]
        public async Task<IActionResult> GetMessages(int channelId)
        {
            var messages = await _context.ChatMessages
                .Where(m => m.ChannelId == channelId)
                .OrderBy(m => m.CreatedAt) 
                .Select(m => new {
                    userId = m.UserId.ToString(),
                    text = m.Content
                })
                .ToListAsync();

            return Ok(messages);
        }

        [HttpPost("project/{projectId}")]
        public async Task<IActionResult> GetOrCreateProjectChannel(int projectId)
        {
            var channel = await _context.ChatChannels.FirstOrDefaultAsync(c => c.ProjectId == projectId);
            
            if (channel == null)
            {
                var project = await _context.Projects.Include(p => p.Student).FirstOrDefaultAsync(p => p.Id == projectId);
                if (project == null) return NotFound("Project not found.");

                channel = new ChatChannel
                {
                    Name = $"Chat: {project.Title}",
                    ChannelType = "Private",
                    ProjectId = projectId,
                    UniversityId = project.UniversityId,
                    CreatedAt = DateTime.UtcNow
                };
                _context.ChatChannels.Add(channel);
                await _context.SaveChangesAsync();
            }
            
            return Ok(channel);
        }
    } 
}