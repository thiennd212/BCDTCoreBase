namespace BCDT.Application.Services.Form;

/// <summary>Ngữ cảnh tham số khi resolve bộ lọc (P8). ReportDate, OrganizationId, ... dùng thay thế Parameter trong FilterCondition.</summary>
public sealed class ParameterContext
{
    public DateTime? ReportDate { get; init; }
    public int? OrganizationId { get; init; }
    public long? SubmissionId { get; init; }
    public int? ReportingPeriodId { get; init; }
    public DateTime CurrentDate { get; init; } = DateTime.UtcNow;
    public int? UserId { get; init; }
    public int? CatalogId { get; init; }
}
