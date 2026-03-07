using System.Net.Http.Json;
using System.Text.Json;

namespace Api.Services;

public class AiDuplicateService : IAiDuplicateService
{
    private readonly HttpClient _httpClient;
    private readonly IConfiguration _config;
    private readonly ILogger<AiDuplicateService> _logger;

    public AiDuplicateService(HttpClient httpClient, IConfiguration config, ILogger<AiDuplicateService> logger)
    {
        _httpClient = httpClient;
        _config = config;
        _logger = logger;
        var baseUrl = _config["AiDuplicateDetection:PythonServiceBaseUrl"] ?? "http://localhost:5000";
        _httpClient.BaseAddress = new Uri(baseUrl);
        _httpClient.Timeout = TimeSpan.FromSeconds(30);
    }

    public async Task<decimal> GetSimilarityScoreAsync(string title, string abstractText, CancellationToken ct = default)
    {
        try
        {
            var payload = new { title, abstract_text = abstractText };
            var response = await _httpClient.PostAsJsonAsync("/api/similarity", payload, ct);
            response.EnsureSuccessStatusCode();
            var json = await response.Content.ReadAsStringAsync(ct);
            var doc = JsonDocument.Parse(json);
            if (doc.RootElement.TryGetProperty("similarity_score", out var scoreEl))
                return scoreEl.GetDecimal();
            if (doc.RootElement.TryGetProperty("similarity", out var simEl))
                return simEl.GetDecimal();
            return 0;
        }
        catch (Exception ex)
        {
            _logger.LogWarning(ex, "AI similarity service unavailable; assuming unique.");
            return 0;
        }
    }
}
