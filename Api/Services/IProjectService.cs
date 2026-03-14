using Api.Models.Dtos;

namespace Api.Services;

public interface IProjectService
{
    Task<(bool Success, string Message, ProjectDto? Project)> SubmitProjectAsync(int studentId, SubmitProjectRequest request, CancellationToken ct = default);
    Task<IEnumerable<ProjectDto>> GetMyProjectsAsync(int userId, string role, CancellationToken ct = default);
    Task<IEnumerable<ProjectDto>> GetPendingForTeacherAsync(int teacherId, CancellationToken ct = default);
    Task<ProjectDto?> GetByIdAsync(int projectId, int userId, string role, CancellationToken ct = default);
    Task<(bool Success, string Message)> ApproveOrRejectAsync(int projectId, int teacherId, ApproveRejectRequest request, CancellationToken ct = default);
    Task<(bool Success, string Message)> UpdateProgressAsync(int projectId, int userId, decimal progressPercent, CancellationToken ct = default);

Task<string> UploadProjectVideoAsync(int projectId, IFormFile file);
    Task<string> UploadProjectModelAsync(int projectId, IFormFile file);
    Task<bool> UpdateProjectLinksAsync(int projectId, string links);


}

