namespace BCDT.Application.DTOs.Notification;

public class CreateNotificationRequest
{
    public int UserId { get; set; }
    public string Type { get; set; } = "System"; // Deadline, Approval, Rejection, Reminder, Revision, System
    public string Title { get; set; } = null!;
    public string Message { get; set; } = null!;
    public string Priority { get; set; } = "Normal";
    public string? EntityType { get; set; }
    public string? EntityId { get; set; }
    public string? ActionUrl { get; set; }
    public string Channels { get; set; } = "InApp";
}
