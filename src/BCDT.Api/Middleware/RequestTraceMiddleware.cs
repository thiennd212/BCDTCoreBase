namespace BCDT.Api.Middleware;

/// <summary>
/// Prod-12 (R11): Gán RequestId/TraceId cho mỗi request, thêm header X-Request-Id và scope log để tra cứu sự cố.
/// Chạy đầu pipeline để mọi log (kể cả ExceptionMiddleware) có thể gắn TraceId.
/// </summary>
public class RequestTraceMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<RequestTraceMiddleware> _logger;

    public const string RequestIdHeaderName = "X-Request-Id";

    public RequestTraceMiddleware(RequestDelegate next, ILogger<RequestTraceMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        if (string.IsNullOrEmpty(context.TraceIdentifier))
            context.TraceIdentifier = Guid.NewGuid().ToString("N");

        context.Response.OnStarting(() =>
        {
            if (!context.Response.Headers.ContainsKey(RequestIdHeaderName))
                context.Response.Headers.Append(RequestIdHeaderName, context.TraceIdentifier);
            return Task.CompletedTask;
        });

        using (_logger.BeginScope(new Dictionary<string, object?>
        {
            ["TraceId"] = context.TraceIdentifier,
            ["RequestId"] = context.TraceIdentifier
        }))
        {
            _logger.LogInformation("Request started {Method} {Path}", context.Request.Method, context.Request.Path);
            try
            {
                await _next(context);
                _logger.LogInformation("Request completed {StatusCode} {Method} {Path}",
                    context.Response.StatusCode, context.Request.Method, context.Request.Path);
            }
            catch (Exception)
            {
                _logger.LogInformation("Request failed (exception) {Method} {Path}",
                    context.Request.Method, context.Request.Path);
                throw;
            }
        }
    }
}
