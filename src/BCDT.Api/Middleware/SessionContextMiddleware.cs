using System.Data;
using System.Text.Json;
using BCDT.Api.Common;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Api.Middleware;

/// <summary>
/// Middleware B3: set session context (UserId) trên connection DB để RLS áp dụng đúng.
/// Chạy sau UseAuthentication(), trước UseAuthorization().
/// Gọi sp_SetUserContext trên chính connection của DbContext để RLS SELECT/INSERT/UPDATE dùng đúng session.
/// Prod-11 (R3): Khi SetUserContext thất bại → từ chối request (503), không gọi pipeline để tránh request chạy không RLS.
/// </summary>
public class SessionContextMiddleware
{
    private readonly RequestDelegate _next;
    private readonly ILogger<SessionContextMiddleware> _logger;

    public SessionContextMiddleware(RequestDelegate next, ILogger<SessionContextMiddleware> logger)
    {
        _next = next;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context, AppDbContext db)
    {
        if (!context.User.Identity?.IsAuthenticated ?? true)
        {
            await _next(context);
            return;
        }

        var userIdClaim = context.User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdClaim) || !int.TryParse(userIdClaim, out var userId))
        {
            await _next(context);
            return;
        }

        var connection = db.Database.GetDbConnection();
        if (connection.State != ConnectionState.Open)
            await connection.OpenAsync(context.RequestAborted);

        try
        {
            await SetUserContextOnConnection(connection, userId, context.RequestAborted);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "SetUserContext failed for UserId {UserId}, rejecting request", userId);
            context.Response.ContentType = "application/json";
            context.Response.StatusCode = StatusCodes.Status503ServiceUnavailable;
            var response = new ApiErrorResponse("SESSION_CONTEXT_FAILED", "Không thể thiết lập ngữ cảnh phiên, yêu cầu bị từ chối.");
            var options = new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };
            await context.Response.WriteAsync(JsonSerializer.Serialize(new
            {
                success = false,
                errors = response.Errors
            }, options));
            return;
        }

        try
        {
            await _next(context);
        }
        finally
        {
            try
            {
                // Dùng CancellationToken.None vì context.RequestAborted đã bị cancel
                // khi request kết thúc → OperationCanceledException → stale connection trong pool
                await ClearUserContextOnConnection(connection, CancellationToken.None);
            }
            catch (Exception ex)
            {
                _logger.LogWarning(ex, "ClearUserContext failed – connection may have stale session context");
            }
        }
    }

    private static async Task SetUserContextOnConnection(System.Data.Common.DbConnection connection, int userId, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "EXEC sp_SetUserContext @UserId, 0";
        var p = cmd.CreateParameter();
        p.ParameterName = "@UserId";
        p.Value = userId;
        p.DbType = DbType.Int32;
        cmd.Parameters.Add(p);
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }

    private static async Task ClearUserContextOnConnection(System.Data.Common.DbConnection connection, CancellationToken cancellationToken)
    {
        await using var cmd = connection.CreateCommand();
        cmd.CommandText = "EXEC sp_ClearUserContext";
        await cmd.ExecuteNonQueryAsync(cancellationToken);
    }
}
