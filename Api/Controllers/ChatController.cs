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

        [HttpGet("channels/{userId}/{role}")]
        public async Task<IActionResult> GetChannels(int userId, string role)
        {
            // 🌟 University ka naam fetch karne ke liye Include lagaya hai
            var user = await _context.Users.Include(u => u.University).FirstOrDefaultAsync(u => u.Id == userId);
            if (user == null) return Unauthorized();

            // 🔥 JADOO: Agar channels nahi bane hue toh auto-create karlo!
            if (!string.IsNullOrEmpty(user.Department))
            {
                // 1. Check & Create Global Channel for this Department
                var globalExists = await _context.ChatChannels.AnyAsync(c => c.ChannelType == "Global" && c.Department == user.Department);
                if (!globalExists)
                {
                    _context.ChatChannels.Add(new ChatChannel { 
                        Name = $"Global {user.Department} Community", 
                        ChannelType = "Global", 
                        Department = user.Department, 
                        CreatedAt = DateTime.UtcNow 
                    });
                }

                // 2. Check & Create University Channel for this Department
                var uniExists = await _context.ChatChannels.AnyAsync(c => c.ChannelType == "University" && c.UniversityId == user.UniversityId && c.Department == user.Department);
                if (!uniExists)
                {
                    var uniName = user.University?.Name ?? "Your University";
                    _context.ChatChannels.Add(new ChatChannel { 
                        Name = $"{uniName} - {user.Department}", 
                        ChannelType = "University", 
                        UniversityId = user.UniversityId, 
                        Department = user.Department, 
                        CreatedAt = DateTime.UtcNow 
                    });
                }
                await _context.SaveChangesAsync();
            }

            var allChannels = await _context.ChatChannels.ToListAsync();
            var filteredChannels = new List<ChatChannel>();

            foreach (var ch in allChannels)
            {
                // 🔥 GLOBAL: Sirf apne department ka Global Chat (e.g., Any Uni -> Information Technology)
                if (ch.ChannelType == "Global" && ch.Department == user.Department) 
                {
                    filteredChannels.Add(ch);
                }
                // 🔥 UNIVERSITY: Apni Uni + Apna Department (e.g., Demo Uni -> Information Technology)
                else if (ch.ChannelType == "University" && ch.UniversityId == user.UniversityId && ch.Department == user.Department) 
                {
                    filteredChannels.Add(ch);
                }
                // 🔥 PRIVATE: Projects wala logic bilkul pehle jaisa safe hai
                else if (ch.ChannelType == "Private" && ch.ProjectId != null) 
                {
                    var project = await _context.Projects.Include(p => p.Student).FirstOrDefaultAsync(p => p.Id == ch.ProjectId);
                    if (project != null) 
                    {
                        if (role == "Student" && project.StudentId == userId) 
                        {
                            filteredChannels.Add(ch);
                        }
                        else if (role == "Teacher" && project.UniversityId == user.UniversityId) 
                        {
                            filteredChannels.Add(ch);
                        }
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
            // 🔥 NAYA: Join laga kar User ka Naam aur DP nikali hai
            var messages = await (from m in _context.ChatMessages
                                  join u in _context.Users on m.UserId equals u.Id
                                  where m.ChannelId == channelId
                                  orderby m.CreatedAt
                                  select new {
                                      userId = m.UserId.ToString(),
                                      text = m.Content,
                                      senderName = u.FullName ?? "Unknown", // 🔥
                                      dpUrl = u.ProfilePictureUrl           // 🔥
                                  }).ToListAsync();

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
                    Name = $"Project: {project.Title}",
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