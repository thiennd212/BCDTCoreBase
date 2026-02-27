namespace BCDT.Application.DTOs.Dashboard;

public class DashboardUserTasksDto
{
    public List<SubmissionTaskDto> Drafts { get; set; } = new();
    public List<SubmissionTaskDto> Revisions { get; set; } = new();
    public List<PeriodDeadlineDto> UpcomingDeadlines { get; set; } = new();
    public List<PendingApprovalTaskDto> PendingApprovals { get; set; } = new();
}

public class SubmissionTaskDto
{
    public long SubmissionId { get; set; }
    public int FormDefinitionId { get; set; }
    public string FormName { get; set; } = string.Empty;
    public int ReportingPeriodId { get; set; }
    public string PeriodName { get; set; } = string.Empty;
    public DateTime? Deadline { get; set; }
    public string Status { get; set; } = string.Empty;
}

public class PeriodDeadlineDto
{
    public int ReportingPeriodId { get; set; }
    public string PeriodCode { get; set; } = string.Empty;
    public string PeriodName { get; set; } = string.Empty;
    public DateTime Deadline { get; set; }
    public int FormCount { get; set; }
}

public class PendingApprovalTaskDto
{
    public long WorkflowInstanceId { get; set; }
    public long SubmissionId { get; set; }
    public string FormName { get; set; } = string.Empty;
    public string OrganizationName { get; set; } = string.Empty;
    public string PeriodName { get; set; } = string.Empty;
    public int CurrentStep { get; set; }
    public int TotalSteps { get; set; }
    public DateTime? SubmittedAt { get; set; }
}
