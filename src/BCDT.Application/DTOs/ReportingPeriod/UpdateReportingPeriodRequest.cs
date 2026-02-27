namespace BCDT.Application.DTOs.ReportingPeriod;

public class UpdateReportingPeriodRequest
{
    public string? PeriodName { get; set; }
    public DateTime? StartDate { get; set; }
    public DateTime? EndDate { get; set; }
    public DateTime? Deadline { get; set; }
    public string? Status { get; set; }
    public bool? IsCurrent { get; set; }
    public bool? IsLocked { get; set; }
}
