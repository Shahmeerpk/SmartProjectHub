namespace Api.Models.Dtos;

public class ProjectDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Abstract { get; set; } = string.Empty;
    public string Status { get; set; } = string.Empty;
    public decimal ProgressPercent { get; set; }
    public decimal? SimilarityScore { get; set; }
    public string? RejectionReason { get; set; }
    public string? ObjModelUrl { get; set; }
    public int StudentId { get; set; }
    public string? StudentName { get; set; }
    public int? TeacherId { get; set; }
    public string? TeacherName { get; set; }
    public int UniversityId { get; set; }
    public string? UniversityName { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime? ReviewedAt { get; set; }
}
