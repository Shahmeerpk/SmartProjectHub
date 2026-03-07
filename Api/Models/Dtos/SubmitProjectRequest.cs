using System.ComponentModel.DataAnnotations;

namespace Api.Models.Dtos;

public class SubmitProjectRequest
{
    [Required, MaxLength(500)]
    public string Title { get; set; } = string.Empty;

    [Required]
    public string Abstract { get; set; } = string.Empty;
}
