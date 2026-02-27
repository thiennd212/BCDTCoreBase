namespace BCDT.Application.DTOs.Data;

/// <summary>DTO cho ReportDataRow – dùng trong drill-down từ ReportSummary (FR-TH-02).</summary>
public class ReportDataRowDto
{
    public long Id { get; set; }
    public long SubmissionId { get; set; }
    public byte SheetIndex { get; set; }
    public int RowIndex { get; set; }
    public long? ReferenceEntityId { get; set; }

    public decimal? NumericValue1 { get; set; }
    public decimal? NumericValue2 { get; set; }
    public decimal? NumericValue3 { get; set; }
    public decimal? NumericValue4 { get; set; }
    public decimal? NumericValue5 { get; set; }
    public decimal? NumericValue6 { get; set; }
    public decimal? NumericValue7 { get; set; }
    public decimal? NumericValue8 { get; set; }
    public decimal? NumericValue9 { get; set; }
    public decimal? NumericValue10 { get; set; }

    public string? TextValue1 { get; set; }
    public string? TextValue2 { get; set; }
    public string? TextValue3 { get; set; }

    public DateTime? DateValue1 { get; set; }
    public DateTime? DateValue2 { get; set; }

    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
