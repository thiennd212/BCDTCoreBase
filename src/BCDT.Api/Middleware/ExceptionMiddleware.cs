using System.Net;
using System.Text.Json;
using BCDT.Api.Common;
using Microsoft.AspNetCore.Mvc;
namespace BCDT.Api.Middleware;

/// <summary>
/// Bắt mọi exception chưa xử lý, log và trả ApiErrorResponse thống nhất.
/// Ở Production không trả stack trace ra client.
/// </summary>
public class ExceptionMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<ExceptionMiddleware> _logger;
    private readonly IHostEnvironment _env;

    public ExceptionMiddleware(RequestDelegate next, ILogger<ExceptionMiddleware> logger, IHostEnvironment env)
    {
        _next = next;
        _logger = logger;
        _env = env;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        try
        {
            await _next(context);
        }
        catch (Exception ex)
        {
            await HandleExceptionAsync(context, ex);
        }
    }

    private async Task HandleExceptionAsync(HttpContext context, Exception ex)
    {
        _logger.LogError(ex, "Unhandled exception: {Message}", ex.Message);

        var statusCode = HttpStatusCode.InternalServerError;
        var code = "INTERNAL_ERROR";
        var message = _env.IsDevelopment()
            ? $"{ex.Message} ({ex.GetType().Name})"
            : "Đã xảy ra lỗi hệ thống, vui lòng thử lại sau.";

        if (ex is OperationCanceledException or TaskCanceledException)
        {
            statusCode = HttpStatusCode.BadRequest;
            code = "CANCELLED";
            message = "Yêu cầu đã bị hủy.";
        }
        else if (ex is Microsoft.AspNetCore.Http.BadHttpRequestException badReq && badReq.StatusCode == 413)
        {
            // Prod-7 (R9): body vượt MaxRequestBodySize → trả 413
            statusCode = HttpStatusCode.RequestEntityTooLarge;
            code = "PAYLOAD_TOO_LARGE";
            message = "Kích thước request body vượt giới hạn cho phép.";
        }

        context.Response.ContentType = "application/json";
        context.Response.StatusCode = (int)statusCode;

        var response = new ApiErrorResponse(code, message);
        var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
        await context.Response.WriteAsync(JsonSerializer.Serialize(new
        {
            success = false,
            errors = response.Errors
        }, options));
    }
}
