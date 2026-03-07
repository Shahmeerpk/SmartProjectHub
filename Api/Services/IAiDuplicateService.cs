namespace Api.Services;

public interface IAiDuplicateService
{
    /// <summary>
    /// Returns similarity score 0-100. If &gt; threshold, consider duplicate.
    /// </summary>
    Task<decimal> GetSimilarityScoreAsync(string title, string abstractText, CancellationToken ct = default);
}
