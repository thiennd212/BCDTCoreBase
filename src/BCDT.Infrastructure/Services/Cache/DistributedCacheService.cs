using System.Text.Json;
using BCDT.Application.Services.Cache;
using Microsoft.Extensions.Caching.Distributed;

namespace BCDT.Infrastructure.Services.Cache;

public class DistributedCacheService : ICacheService
{
    private static readonly TimeSpan DefaultTtl = TimeSpan.FromMinutes(10);
    private static readonly JsonSerializerOptions JsonOptions = new() { PropertyNameCaseInsensitive = true };

    private readonly IDistributedCache _cache;

    public DistributedCacheService(IDistributedCache cache) => _cache = cache;

    public async Task<T?> GetAsync<T>(string key, CancellationToken cancellationToken = default) where T : class
    {
        var bytes = await _cache.GetAsync(key, cancellationToken);
        if (bytes == null || bytes.Length == 0)
            return null;
        return JsonSerializer.Deserialize<T>(bytes, JsonOptions);
    }

    public async Task SetAsync<T>(string key, T value, TimeSpan? absoluteExpirationRelativeToNow = null, CancellationToken cancellationToken = default) where T : class
    {
        var ttl = absoluteExpirationRelativeToNow ?? DefaultTtl;
        var options = new DistributedCacheEntryOptions { AbsoluteExpirationRelativeToNow = ttl };
        var bytes = JsonSerializer.SerializeToUtf8Bytes(value, JsonOptions);
        await _cache.SetAsync(key, bytes, options, cancellationToken);
    }

    public Task RemoveAsync(string key, CancellationToken cancellationToken = default) =>
        _cache.RemoveAsync(key, cancellationToken);
}
