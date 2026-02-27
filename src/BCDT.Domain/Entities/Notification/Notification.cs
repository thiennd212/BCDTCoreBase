namespace BCDT.Domain.Entities.Notification;

public class Notification
{
    public long Id { get; set; }
    public int UserId { get; set; }
    public string Type { get; set; } = null!;       // Deadline, Approval, Rejection, Reminder, Revision, System
    public string Title { get; set; } = null!;
    public string Message { get; set; } = null!;
    public string Priority { get; set; } = "Normal"; // Low, Normal, High, Urgent

    public string? EntityType { get; set; }
    public string? EntityId { get; set; }
    public string? ActionUrl { get; set; }

    public string Channels { get; set; } = "InApp";
    public DateTime? EmailSentAt { get; set; }
    public DateTime? SmsSentAt { get; set; }

    public bool IsRead { get; set; }
    public DateTime? ReadAt { get; set; }
    public bool IsDismissed { get; set; }
    public DateTime? DismissedAt { get; set; }

    public DateTime CreatedAt { get; set; }
    public DateTime? ExpiresAt { get; set; }
}
