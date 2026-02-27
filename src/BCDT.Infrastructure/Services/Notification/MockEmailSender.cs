using BCDT.Application.Services.Notification;
using Microsoft.Extensions.Logging;

namespace BCDT.Infrastructure.Services.Notification;

/// <summary>Email mock: log only. Có thể cấu hình gửi MailHog sau.</summary>
public class MockEmailSender : IEmailSender
{
    private readonly ILogger<MockEmailSender> _logger;

    public MockEmailSender(ILogger<MockEmailSender> logger) => _logger = logger;

    public Task SendAsync(string to, string subject, string body, CancellationToken cancellationToken = default)
    {
        _logger.LogInformation("[MockEmail] To: {To}, Subject: {Subject}, Body length: {Len}", to, subject, body?.Length ?? 0);
        return Task.CompletedTask;
    }
}
