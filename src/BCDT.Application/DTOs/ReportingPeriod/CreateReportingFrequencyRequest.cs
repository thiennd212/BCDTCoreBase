namespace BCDT.Application.DTOs.ReportingPeriod;

public class CreateReportingFrequencyRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public int DaysInPeriod { get; set; }
    public string? CronExpression { get; set; }
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateReportingFrequencyRequest
{
    public string Name { get; set; } = string.Empty;
    public string? NameEn { get; set; }
    public int DaysInPeriod { get; set; }
    public string? CronExpression { get; set; }
    public string? Description { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
}
