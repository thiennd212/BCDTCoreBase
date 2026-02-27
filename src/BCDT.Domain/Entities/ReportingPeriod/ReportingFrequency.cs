namespace BCDT.Domain.Entities.ReportingPeriod;

/// <summary>Chu kỳ báo cáo (BCDT_ReportingFrequency). Code: DAILY, WEEKLY, MONTHLY, QUARTERLY, YEARLY, ADHOC.</summary>
public class ReportingFrequency
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public int DaysInPeriod { get; set; }
    public string? CronExpression { get; set; }
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
}
