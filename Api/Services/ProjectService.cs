using Api.Data;
using Api.Models;
using Api.Models.Dtos;
using Api.Hubs; // Naya: Hub ka link
using Microsoft.AspNetCore.SignalR; // Naya: SignalR library
using Microsoft.EntityFrameworkCore;

namespace Api.Services;

public class ProjectService : IProjectService
{
    private readonly AppDbContext _db;
    private readonly IAiDuplicateService _aiService;
    private readonly IConfiguration _config;
    private readonly IHubContext<ProjectHub> _hub; // Naya: Hub connection

    public ProjectService(AppDbContext db, IAiDuplicateService aiService, IConfiguration config, IHubContext<ProjectHub> hub)
    {
        _db = db;
        _aiService = aiService;
        _config = config;
        _hub = hub;
    }

    public async Task<(bool Success, string Message, ProjectDto? Project)> SubmitProjectAsync(int studentId, SubmitProjectRequest request, CancellationToken ct = default)
    {
        var user = await _db.Users.FindAsync([studentId], ct);
        if (user == null) return (false, "User not found.", null);
        if (user.Role != "Student") return (false, "Only students can submit projects.", null);

        var similarity = await _aiService.GetSimilarityScoreAsync(request.Title, request.Abstract, ct);

        var project = new Project
        {
            Title = request.Title.Trim(),
            Abstract = request.Abstract.Trim(),
            StudentId = studentId,
            UniversityId = user.UniversityId,
            Status = "Pending", 
            ProgressPercent = 0,
            SimilarityScore = similarity, 
            CreatedAt = DateTime.UtcNow,
            UpdatedAt = DateTime.UtcNow
        };
        
        _db.Projects.Add(project);
        await _db.SaveChangesAsync(ct);

        var dto = await MapToDtoAsync(project, ct);

        // 🔥 SIGNALR: Sab ko ishara bhejo ke naya project aaya hai!
        await _hub.Clients.All.SendAsync("RefreshProjects");

        var threshold = decimal.Parse(_config["AiDuplicateDetection:SimilarityThresholdPercent"] ?? "70");
        string msg = similarity >= threshold 
            ? $"Project submitted successfully, but AI detected {similarity:F1}% duplication. Awaiting teacher review."
            : "Project submitted and pending teacher review.";

        return (true, msg, dto);
    }

    public async Task<IEnumerable<ProjectDto>> GetMyProjectsAsync(int userId, string role, CancellationToken ct = default)
    {
        var query = _db.Projects
            .Include(p => p.Student)
            .Include(p => p.Teacher)
            .Include(p => p.University)
            .AsQueryable();

        if (role == "Student")
            query = query.Where(p => p.StudentId == userId);
        else if (role == "Teacher")
            query = query.Where(p => p.TeacherId == userId || p.UniversityId == _db.Users.Where(u => u.Id == userId).Select(u => u.UniversityId).First());

        var list = await query.OrderByDescending(p => p.CreatedAt).ToListAsync(ct);
        return await Task.WhenAll(list.Select(p => MapToDtoAsync(p, ct)));
    }

    public async Task<IEnumerable<ProjectDto>> GetPendingForTeacherAsync(int teacherId, CancellationToken ct = default)
    {
        var teacher = await _db.Users.FindAsync([teacherId], ct);
        if (teacher == null) return Array.Empty<ProjectDto>();

        var list = await _db.Projects
            .Include(p => p.Student)
            .Include(p => p.University)
            .Where(p => p.UniversityId == teacher.UniversityId && p.Status == "Pending")
            .OrderByDescending(p => p.CreatedAt)
            .ToListAsync(ct);
        return await Task.WhenAll(list.Select(p => MapToDtoAsync(p, ct)));
    }

    public async Task<ProjectDto?> GetByIdAsync(int projectId, int userId, string role, CancellationToken ct = default)
    {
        var project = await _db.Projects
            .Include(p => p.Student)
            .Include(p => p.Teacher)
            .Include(p => p.University)
            .FirstOrDefaultAsync(p => p.Id == projectId, ct);
        if (project == null) return null;

        if (role == "Student" && project.StudentId != userId) return null;
        if (role == "Teacher" && project.UniversityId != (await _db.Users.FindAsync([userId], ct))?.UniversityId) return null;

        return await MapToDtoAsync(project, ct);
    }

    public async Task<(bool Success, string Message)> ApproveOrRejectAsync(int projectId, int teacherId, ApproveRejectRequest request, CancellationToken ct = default)
    {
        var project = await _db.Projects.FindAsync([projectId], ct);
        if (project == null) return (false, "Project not found.");
        if (project.Status != "Pending") return (false, "Project is not pending.");

        var teacher = await _db.Users.FindAsync([teacherId], ct);
        if (teacher == null || teacher.Role != "Teacher" || teacher.UniversityId != project.UniversityId)
            return (false, "Unauthorized to review this project.");

        project.TeacherId = teacherId;
        project.ReviewedAt = DateTime.UtcNow;
        project.UpdatedAt = DateTime.UtcNow;

        if (request.Approve)
        {
            project.Status = "Approved";
            project.RejectionReason = null;
        }
        else
        {
            project.Status = "Rejected";
            project.RejectionReason = request.RejectionReason ?? "Rejected by teacher.";
        }

        await _db.SaveChangesAsync(ct);
        
        // 🔥 SIGNALR: Sab ko ishara bhejo ke status update hua hai!
        await _hub.Clients.All.SendAsync("RefreshProjects");
        
        return (true, request.Approve ? "Project approved." : "Project rejected.");
    }

    public async Task<(bool Success, string Message)> UpdateProgressAsync(int projectId, int userId, decimal progressPercent, CancellationToken ct = default)
    {
        var project = await _db.Projects.FindAsync([projectId], ct);
        if (project == null) return (false, "Project not found.");
        if (project.StudentId != userId) return (false, "Only the project owner can update progress.");
        if (progressPercent < 0 || progressPercent > 100) return (false, "Progress must be between 0 and 100.");

        project.ProgressPercent = progressPercent;
        project.UpdatedAt = DateTime.UtcNow;
        await _db.SaveChangesAsync(ct);
        
        // 🔥 SIGNALR: Sab ko ishara bhejo ke progress update hui hai!
        await _hub.Clients.All.SendAsync("RefreshProjects");
        
        return (true, "Progress updated.");
    }

    private async Task<ProjectDto> MapToDtoAsync(Project p, CancellationToken ct)
    {
        await Task.CompletedTask;
        return new ProjectDto
        {
            Id = p.Id,
            Title = p.Title,
            Abstract = p.Abstract,
            Status = p.Status,
            ProgressPercent = p.ProgressPercent,
            SimilarityScore = p.SimilarityScore,
            RejectionReason = p.RejectionReason,
            ObjModelUrl = p.ObjModelUrl,
            StudentId = p.StudentId,
            StudentName = p.Student?.FullName,
            RollNumber = p.Student?.RollNumber, 
            TeacherId = p.TeacherId,
            TeacherName = p.Teacher?.FullName,
            UniversityId = p.UniversityId,
            UniversityName = p.University?.Name,
            CreatedAt = p.CreatedAt,
            ReviewedAt = p.ReviewedAt
        };
    }
}