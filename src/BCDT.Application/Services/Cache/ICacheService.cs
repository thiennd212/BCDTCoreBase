namespace BCDT.Application.Services.Cache;

/// <summary>
/// Abstraction over distributed cache for master data. Use IDistributedCache implementation (Memory/Redis) without coupling application to a specific provider.
/// </summary>
public interface ICacheService
{
    Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default) where T : class;

    Task SetAsync<T>(string key, T value, TimeSpan? absoluteExpirationRelativeToNow = null, CancellationToken cancellationToken = default) where T : class;

    Task RemoveAsync(string key, CancellationToken cancellationToken = default);
}
