using BCDT.Application.Common;

namespace BCDT.Application.Services.Data;

public interface IAuditService
{
    /// <summary>Ghi một cell-level audit record.</summary>
    Task<Result<object>> LogCellChangeAsync(
        long submissionId,
        long? dataRowId,
        byte sheetIndex,
        string cellAddress,
        string? columnName,
        string? oldValue,
        string? newValue,
        string changeType,
        int changedBy,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default);

    /// <summary>Ghi nhiều cell-level audit records cùng lúc.</summary>
    Task<Result<int>> LogBatchCellChangesAsync(
        long submissionId,
        byte sheetIndex,
        IEnumerable<CellChangeEntry> changes,
        int changedBy,
        string? ipAddress = null,
        string? userAgent = null,
        CancellationToken cancellationToken = default);

    /// <summary>Lấy lịch sử audit cho một submission.</summary>
    Task<Result<List<AuditEntryDto>>> GetAuditHistoryAsync(long submissionId, CancellationToken cancellationToken = default);
}

public class CellChangeEntry
{
    public long? DataRowId { get; set; }
    public string CellAddress { get; set; } = string.Empty;
    public string? ColumnName { get; set; }
    public string? OldValue { get; set; }
    public string? NewValue { get; set; }
    public string ChangeType { get; set; } = "Update";
}

public class AuditEntryDto
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
}
