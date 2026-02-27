namespace BCDT.Domain.Entities.Data;

/// <summary>Cell-level audit trail (BCDT_ReportDataAudit).</summary>
public class ReportDataAudit
{
    public long Id { get; set; }
    public long SubmissionId { get; set; }
    public long? DataRowId { get; set; }
    public byte SheetIndex { get; set; }
    public string CellAddress { get; set; } = string.Empty;
    public string? ColumnName { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public string ChangeType { get; set; } = string.Empty;
    public DateTime ChangedAt { get; set; }
    public int ChangedBy { get; set; }
    public string? IpAddress { get; set; }
    public string? UserAgent { get; set; }
}
