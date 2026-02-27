namespace BCDT.Application.DTOs.Dashboard;

public class DashboardAdminStatsDto
{
    public int TotalSubmissions { get; set; }
    public int DraftCount { get; set; }
    public int SubmittedCount { get; set; }
    public int ApprovedCount { get; set; }
    public int RejectedCount { get; set; }
    public int RevisionCount { get; set; }
    public List<SubmissionsByPeriodDto> SubmissionsByPeriod { get; set; } = new();
    public List<SubmissionsByFormDto> SubmissionsByForm { get; set; } = new();
}

public class SubmissionsByPeriodDto
{
    public int ReportingPeriodId { get; set; }
    public string PeriodCode { get; set; } = string.Empty;
    public string PeriodName { get; set; } = string.Empty;
    public int Count { get; set; }
}

public class SubmissionsByFormDto
{
    public int FormDefinitionId { get; set; }
    public string FormCode { get; set; } = string.Empty;
    public string FormName { get; set; } = string.Empty;
    public int Count { get; set; }
}
