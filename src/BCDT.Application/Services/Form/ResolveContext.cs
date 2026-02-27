namespace BCDT.Application.Services.Form;

/// <summary>Context truyền vào Data Binding Resolver (B8 mục 3): UserId, OrganizationId, ReportingPeriodId, CurrentDate.</summary>
public sealed class ResolveContext
{
    public int? UserId { get; init; }
    public int? OrganizationId { get; init; }
    public int? ReportingPeriodId { get; init; }
    public DateTime CurrentDate { get; init; } = DateTime.UtcNow;
}
