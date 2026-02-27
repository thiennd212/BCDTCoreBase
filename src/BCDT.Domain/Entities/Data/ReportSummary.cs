namespace BCDT.Domain.Entities.Data;

/// <summary>Layer 2.5: Pre-calculated aggregates (BCDT_ReportSummary). One per submission per sheet.</summary>
public class ReportSummary
{
    public long Id { get; set; }
    public long SubmissionId { get; set; }
    public byte SheetIndex { get; set; }

    public decimal? TotalValue1 { get; set; }
    public decimal? TotalValue2 { get; set; }
    public decimal? TotalValue3 { get; set; }
    public decimal? TotalValue4 { get; set; }
    public decimal? TotalValue5 { get; set; }
    public decimal? TotalValue6 { get; set; }
    public decimal? TotalValue7 { get; set; }
    public decimal? TotalValue8 { get; set; }
    public decimal? TotalValue9 { get; set; }
    public decimal? TotalValue10 { get; set; }

    public int RowCount { get; set; }
    public int DataRowCount { get; set; }
    public DateTime CalculatedAt { get; set; }
}
