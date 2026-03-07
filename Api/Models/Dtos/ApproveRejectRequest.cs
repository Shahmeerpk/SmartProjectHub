using System.ComponentModel.DataAnnotations;

namespace Api.Models.Dtos;

public class ApproveRejectRequest
{
    public bool Approve { get; set; }

    [MaxLength(500)]
    public string? RejectionReason { get; set; }
}
