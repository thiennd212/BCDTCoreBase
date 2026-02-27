namespace BCDT.Domain.Entities.Data;

/// <summary>Chỉ tiêu động theo submission (BCDT_ReportDynamicIndicator). R4, R8.</summary>
public class ReportDynamicIndicator
{
    public long Id { get; set; }
    public long SubmissionId { get; set; }
    public int FormDynamicRegionId { get; set; }
    public int RowOrder { get; set; }
    public int? IndicatorId { get; set; }
    public string IndicatorName { get; set; } = string.Empty;
    public string? IndicatorValue { get; set; }
    public string? DataType { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
