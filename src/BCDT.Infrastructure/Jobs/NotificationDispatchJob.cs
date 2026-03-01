using BCDT.Application.Services.Notification;
using Hangfire;
using Microsoft.Extensions.Logging;

namespace BCDT.Infrastructure.Jobs;

/// <summary>
/// Job nền gửi email thông báo (fire-and-forget).
/// Nhận sẵn địa chỉ email và nội dung từ caller để tránh phụ thuộc DB trong job.
/// </summary>
[AutomaticRetry(Attempts = 3, OnAttemptsExceeded = AttemptsExceededAction.Delete)]
public class NotificationDispatchJob
{
    private readonly IEmailSender _emailSender;
    private readonly ILogger<NotificationDispatchJob> _logger;

    public NotificationDispatchJob(IEmailSender emailSender, ILogger<NotificationDispatchJob> logger)
    {
        _emailSender = emailSender;
        _logger = logger;
    }

    public async Task ExecuteAsync(string toEmail, string subject, string body, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(toEmail))
        {
            _logger.LogDebug("NotificationDispatchJob: toEmail rỗng – bỏ qua.");
            return;
        }

        try
        {
            await _emailSender.SendAsync(toEmail, subject, body, cancellationToken);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "NotificationDispatchJob: lỗi khi gửi email tới {Email}", toEmail);
            throw; // Hangfire retry
        }
    }
}
