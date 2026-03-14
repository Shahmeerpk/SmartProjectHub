namespace Api.Models.Dtos;

public class ProjectDto
{
    public int Id { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Abstract { get; set; } = string.Empty;
    
    public string Status { get; set; } = string.Empty; // 🔥 CS0200 Error Fixed
    
    public int StudentId { get; set; }
    public string? StudentName { get; set; }
    public string? RollNumber { get; set; }
    
    public int? TeacherId { get; set; } // 🔥 CS0117 Error Fixed
    public string? TeacherName { get; set; } // 🔥 CS0117 Error Fixed
    
    public int UniversityId { get; set; }
    public string? UniversityName { get; set; } // 🔥 CS0117 Error Fixed
    
    public double ProgressPercent { get; set; } 
    public decimal SimilarityScore { get; set; } // 🔥 CS0117 Error Fixed
    public string? RejectionReason { get; set; }
    
    // 🔥 NAYI 3 LINES 🔥
    public string? VideoUrl { get; set; } 
    public string? Model3DUrl { get; set; }
    public string? ProjectLinks { get; set; }
    
    public DateTime CreatedAt { get; set; }
    public DateTime? ReviewedAt { get; set; } // 🔥 CS0117 Error Fixed
    
    // Flutter Frontend ke liye Helpers
    public bool IsApproved => Status == "Approved";
    public bool IsRejected => Status == "Rejected";
    public bool IsPending => Status == "Pending";
}