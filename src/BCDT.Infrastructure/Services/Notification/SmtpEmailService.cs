using BCDT.Application.Services.Notification;
using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;
using MimeKit;

namespace BCDT.Infrastructure.Services.Notification;

/// <summary>MailKit SMTP implementation. Được dùng khi Email:SmtpHost được cấu hình.</summary>
public class SmtpEmailService : IEmailSender
{
    private readonly IConfiguration _config;
    private readonly ILogger<SmtpEmailService> _logger;

    public SmtpEmailService(IConfiguration config, ILogger<SmtpEmailService> logger)
    {
        _config = config;
        _logger = logger;
    }

    public async Task SendAsync(string to, string subject, string body, CancellationToken cancellationToken = default)
    {
        var host = _config["Email:SmtpHost"];
        if (string.IsNullOrWhiteSpace(host))
        {
            _logger.LogWarning("[SmtpEmail] SmtpHost chưa được cấu hình – bỏ qua gửi email tới {To}", to);
            return;
        }

        var port = _config.GetValue<int>("Email:SmtpPort", 587);
        var fromAddress = _config["Email:FromAddress"] ?? "noreply@bcdt.local";
        var fromName = _config["Email:FromName"] ?? "BCDT System";
        var enableSsl = _config.GetValue<bool>("Email:EnableSsl", true);
        var username = _config["Email:Username"];
        var password = _config["Email:Password"];

        var message = new MimeMessage();
        message.From.Add(new MailboxAddress(fromName, fromAddress));
        message.To.Add(MailboxAddress.Parse(to));
        message.Subject = subject;
        message.Body = new TextPart("html") { Text = body };

        using var client = new SmtpClient();
        try
        {
            var sslOption = enableSsl ? SecureSocketOptions.StartTls : SecureSocketOptions.None;
            await client.ConnectAsync(host, port, sslOption, cancellationToken);

            if (!string.IsNullOrWhiteSpace(username))
                await client.AuthenticateAsync(username, password, cancellationToken);

            await client.SendAsync(message, cancellationToken);
            await client.DisconnectAsync(true, cancellationToken);

            _logger.LogInformation("[SmtpEmail] Đã gửi email tới {To} – Subject: {Subject}", to, subject);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "[SmtpEmail] Lỗi khi gửi email tới {To} – Subject: {Subject}", to, subject);
            throw;
        }
    }
}
