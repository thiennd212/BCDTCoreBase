namespace BCDT.Application.DTOs.ReportingPeriod;

public class PeriodSummaryExportDto
{
    public int PeriodId { get; set; }
    public DateTime ExportedAt { get; set; }
    public List<PeriodSummaryRowDto> Rows { get; set; } = new();
}

public class PeriodSummaryRowDto
{
    public long SubmissionId { get; set; }
    public int OrganizationId { get; set; }
    public byte SheetIndex { get; set; }
    public int DataRowCount { get; set; }
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
}
