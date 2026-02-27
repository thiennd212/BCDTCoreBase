namespace BCDT.Application.Services.Notification;

/// <summary>Abstraction for sending email. Phase 4: mock implementation (log or MailHog).</summary>
public interface IEmailSender
{
    Task SendAsync(string to, string subject, string body, CancellationToken cancellationToken = default);
}
