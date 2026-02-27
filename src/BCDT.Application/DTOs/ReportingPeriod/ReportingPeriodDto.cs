namespace BCDT.Application.DTOs.ReportingPeriod;

public class ReportingPeriodDto
{
    public int Id { get; set; }
    public int ReportingFrequencyId { get; set; }
    public string? ReportingFrequencyCode { get; set; }
    public string? ReportingFrequencyName { get; set; }
    public string PeriodCode { get; set; } = string.Empty;
    public string PeriodName { get; set; } = string.Empty;
    public int Year { get; set; }
    public byte? Quarter { get; set; }
    public byte? Month { get; set; }
    public byte? Week { get; set; }
    public byte? Day { get; set; }
    public DateTime StartDate { get; set; }
    public DateTime EndDate { get; set; }
    public DateTime Deadline { get; set; }
    public string Status { get; set; } = "Open";
    public bool IsCurrent { get; set; }
    public bool IsLocked { get; set; }
    public DateTime? LockedAt { get; set; }
    public int? LockedBy { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
