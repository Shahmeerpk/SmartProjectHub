using Api.Data;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class UniversitiesController : ControllerBase
{
    private readonly AppDbContext _db;

    public UniversitiesController(AppDbContext db)
    {
        _db = db;
    }

    /// <summary>List all universities (for registration dropdown).</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll(CancellationToken ct)
    {
        var list = await _db.Universities
            .Where(u => u.IsActive)
            .OrderBy(u => u.Name)
            .Select(u => new { u.Id, u.Name, u.Code })
            .ToListAsync(ct);
        return Ok(list);
    }
}
