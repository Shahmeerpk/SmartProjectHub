namespace Api.Models;

public class Project
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Abstract { get; set; } = string.Empty;
    public int StudentId { get; set; }
    public int? TeacherId { get; set; }
    public int UniversityId { get; set; }
    public string Status { get; set; } = "Pending"; // Pending | Approved | Rejected
    public decimal ProgressPercent { get; set; }
    public decimal? SimilarityScore { get; set; }
    public string? RejectionReason { get; set; }
    
    public DateTime? ReviewedAt { get; set; }
    public DateTime CreatedAt { get; set; }
    public DateTime UpdatedAt { get; set; }

    public User? Student { get; set; }
    public User? Teacher { get; set; }
    public University? University { get; set; }
    public string? VideoUrl { get; set; } 
    public string? Model3DUrl { get; set; }
    public string? ProjectLinks { get; set; }
}
