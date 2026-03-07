using System.Security.Claims;
using Api.Models.Dtos;
using Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
[Authorize]
public class ProjectsController : ControllerBase
{
    private readonly IProjectService _projectService;

    public ProjectsController(IProjectService projectService)
    {
        _projectService = projectService;
    }

    private int UserId => int.Parse(User.FindFirstValue(ClaimTypes.NameIdentifier) ?? "0");
    private string UserRole => User.FindFirstValue(ClaimTypes.Role) ?? "";

    /// <summary>Student submits a project. AI duplicate check; if similarity &gt; 70% reject, else save as Pending.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ProjectDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Submit([FromBody] SubmitProjectRequest request, CancellationToken ct)
    {
        var (success, message, project) = await _projectService.SubmitProjectAsync(UserId, request, ct);
        if (!success) return BadRequest(new { message });
        return Ok(project);
    }

    /// <summary>Get projects for current user (my projects as Student/Teacher).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<ProjectDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyProjects(CancellationToken ct)
    {
        var list = await _projectService.GetMyProjectsAsync(UserId, UserRole, ct);
        return Ok(list);
    }

    /// <summary>Teacher: get all pending projects for their university.</summary>
    [HttpGet("pending")]
    [Authorize(Roles = "Teacher")]
    [ProducesResponseType(typeof(IEnumerable<ProjectDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPending(CancellationToken ct)
    {
        var list = await _projectService.GetPendingForTeacherAsync(UserId, ct);
        return Ok(list);
    }

    /// <summary>Get a single project by id (if authorized).</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ProjectDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id, CancellationToken ct)
    {
        var project = await _projectService.GetByIdAsync(id, UserId, UserRole, ct);
        if (project == null) return NotFound();
        return Ok(project);
    }

    /// <summary>Teacher: approve or reject a pending project.</summary>
    [HttpPost("{id:int}/review")]
    [Authorize(Roles = "Teacher")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Review(int id, [FromBody] ApproveRejectRequest request, CancellationToken ct)
    {
        var (success, message) = await _projectService.ApproveOrRejectAsync(id, UserId, request, ct);
        if (!success) return BadRequest(new { message });
        return Ok(new { message });
    }

    /// <summary>Student: update project progress percent.</summary>
    [HttpPatch("{id:int}/progress")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> UpdateProgress(int id, [FromBody] UpdateProgressRequest request, CancellationToken ct)
    {
        var (success, message) = await _projectService.UpdateProgressAsync(id, UserId, request.ProgressPercent, ct);
        if (!success) return BadRequest(new { message });
        return Ok(new { message });
    }
}

public class UpdateProgressRequest
{
    public decimal ProgressPercent { get; set; }
}
