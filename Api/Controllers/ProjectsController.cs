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

    [HttpPost]
    [ProducesResponseType(typeof(ProjectDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Submit([FromBody] SubmitProjectRequest request, CancellationToken ct)
    {
        var (success, message, project) = await _projectService.SubmitProjectAsync(UserId, request, ct);
        if (!success) return BadRequest(new { message });
        return Ok(project);
    }

    [HttpGet]
    [ProducesResponseType(typeof(IEnumerable<ProjectDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetMyProjects(CancellationToken ct)
    {
        var list = await _projectService.GetMyProjectsAsync(UserId, UserRole, ct);
        return Ok(list);
    }

    // 🔥 NAYA: Teacher aur HOD dono pending list mangwa sakte hain
    [HttpGet("pending")]
    [Authorize(Roles = "Teacher,HOD")] 
    [ProducesResponseType(typeof(IEnumerable<ProjectDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetPending(CancellationToken ct)
    {
        var list = await _projectService.GetPendingForTeacherAsync(UserId, ct);
        return Ok(list);
    }

    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ProjectDto), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id, CancellationToken ct)
    {
        var project = await _projectService.GetByIdAsync(id, UserId, UserRole, ct);
        if (project == null) return NotFound();
        return Ok(project);
    }

    // 🔥 NAYA: Teacher aur HOD dono Review (Approve/Reject) kar sakte hain
    [HttpPost("{id:int}/review")]
    [Authorize(Roles = "Teacher,HOD")] 
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Review(int id, [FromBody] ApproveRejectRequest request, CancellationToken ct)
    {
        var (success, message) = await _projectService.ApproveOrRejectAsync(id, UserId, request, ct);
        if (!success) return BadRequest(new { message });
        return Ok(new { message });
    }

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