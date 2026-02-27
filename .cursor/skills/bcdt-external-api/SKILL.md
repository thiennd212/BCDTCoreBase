---
name: bcdt-external-api
description: Tích hợp API ngoài: HttpClient wrapper, DTO, retry (Polly), cache, optional DataBinding. Use when user says "tích hợp API ngoài", "external API", "HTTP client cho", or needs to call external REST API.
---

# BCDT External API Integration

Tạo client và integration service cho API ngoài, theo convention BCDT. Có thể kết nối với DataBinding (binding type API) cho form.

## Workflow

1. **Phân tích:**
   - Endpoint (base URL, path, method GET/POST).
   - Authentication: None / Bearer / API Key / Basic (không hardcode secret — dùng IConfiguration).
   - Rate limit, timeout mong muốn.

2. **Tạo client và DTO:**
   - Interface `IExternal{Service}Client` (vd `IExchangeRateClient`).
   - Class implementation dùng `HttpClient` (đăng ký typed client hoặc IHttpClientFactory).
   - DTO request/response (class hoặc record) cho payload.

3. **Retry và timeout:**
   - Polly: Retry (vd 3 lần, exponential backoff), Timeout.
   - Đăng ký trong DI: `services.AddHttpClient<IExternalXxxClient, ExternalXxxClient>().AddPolicyHandler(...)`.

4. **Logging và error handling:**
   - Log request/response (tránh log secret); catch HttpRequestException, map status → Result hoặc exception.

5. **Tùy chọn — Cache:**
   - Nếu data ít đổi: cache response với TTL (vd IMemoryCache, key theo endpoint + params).

6. **Tùy chọn — DataBinding:**
   - Nếu dùng cho form: cấu hình FormDataBinding với BindingType = 'API', ApiEndpoint, ApiMethod, ApiResponsePath (JSONPath). Tham chiếu agent bcdt-data-binding.

## Template gợi ý (C#)

```csharp
// Interface
public interface IExchangeRateClient
{
    Task<Result<decimal>> GetRateAsync(string currency, CancellationToken ct = default);
}

// Implementation
public class ExchangeRateClient : IExchangeRateClient
{
    private readonly HttpClient _http;
    private readonly ILogger<ExchangeRateClient> _logger;

    public ExchangeRateClient(HttpClient http, ILogger<ExchangeRateClient> logger)
    {
        _http = http;
        _logger = logger;
        _http.BaseAddress = new Uri(_config["External:ExchangeRate:BaseUrl"]);
        _http.Timeout = TimeSpan.FromSeconds(10);
    }

    public async Task<Result<decimal>> GetRateAsync(string currency, CancellationToken ct = default)
    {
        var response = await _http.GetAsync($"/rate?currency={currency}", ct);
        if (!response.IsSuccessStatusCode)
            return Result.Fail<decimal>($"API error: {response.StatusCode}");
        var json = await response.Content.ReadFromJsonAsync<RateResponse>(cancellationToken: ct);
        return Result.Success(json.Rate);
    }
}

// DI: Program.cs hoặc Extensions
services.AddHttpClient<IExchangeRateClient, ExchangeRateClient>()
    .AddTransientHttpErrorPolicy(p => p.WaitAndRetryAsync(3, _ => TimeSpan.FromSeconds(2)));
```

## Checklist

- [ ] Không hardcode secret (BaseUrl, API Key lấy từ IConfiguration / appsettings).
- [ ] Timeout và retry (Polly) cấu hình rõ.
- [ ] DTO request/response đúng format API.
- [ ] Error handling và logging (không lộ secret).
- [ ] Nếu dùng cho form: FormDataBinding BindingType API, ApiEndpoint, ApiResponsePath.
