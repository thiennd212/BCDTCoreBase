using System.Text.Json;
using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.Services.Data;
using BCDT.Domain.Entities.Data;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

/// <summary>Đồng bộ ReportDataRow từ WorkbookJson (hỗ trợ định dạng simple và FortuneSheet).</summary>
public class SyncFromPresentationService : ISyncFromPresentationService
{
    private readonly AppDbContext _db;

    public SyncFromPresentationService(AppDbContext db) => _db = db;

    public async Task<Result<SubmissionUploadResultDto>> SyncFromPresentationAsync(long submissionId, int userId, CancellationToken cancellationToken = default)
    {
        var submission = await _db.ReportSubmissions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == submissionId && !s.IsDeleted, cancellationToken);
        if (submission == null)
            return Result.Fail<SubmissionUploadResultDto>("NOT_FOUND", "Submission không tồn tại.");

        var presentation = await _db.ReportPresentations
            .AsNoTracking()
            .FirstOrDefaultAsync(p => p.SubmissionId == submissionId, cancellationToken);
        if (presentation == null || string.IsNullOrEmpty(presentation.WorkbookJson))
            return Result.Fail<SubmissionUploadResultDto>("NOT_FOUND", "Chưa có dữ liệu nhập liệu (presentation) cho submission này.");

        var formId = submission.FormDefinitionId;
        var sheets = await _db.FormSheets
            .AsNoTracking()
            .Where(s => s.FormDefinitionId == formId)
            .OrderBy(s => s.DisplayOrder).ThenBy(s => s.SheetIndex)
            .ToListAsync(cancellationToken);
        if (sheets.Count == 0)
            return Result.Fail<SubmissionUploadResultDto>("VALIDATION_FAILED", "Form chưa có sheet nào.");

        var sheetIds = sheets.Select(s => s.Id).ToList();
        var columns = await _db.FormColumns
            .AsNoTracking()
            .Where(c => sheetIds.Contains(c.FormSheetId))
            .OrderBy(c => c.FormSheetId).ThenBy(c => c.DisplayOrder).ThenBy(c => c.Id)
            .ToListAsync(cancellationToken);
        var columnIds = columns.Select(c => c.Id).ToList();
        var mappings = await _db.FormColumnMappings
            .AsNoTracking()
            .Where(m => columnIds.Contains(m.FormColumnId))
            .ToListAsync(cancellationToken);
        var mappingByColumnId = mappings.ToDictionary(m => m.FormColumnId);

        JsonElement root;
        try
        {
            root = JsonDocument.Parse(presentation.WorkbookJson).RootElement;
        }
        catch (JsonException ex)
        {
            return Result.Fail<SubmissionUploadResultDto>("INVALID_JSON", "WorkbookJson không hợp lệ: " + ex.Message);
        }

        var dataRowsToInsert = new List<ReportDataRow>();
        int dataRowCount = 0;

        if (IsSimpleFormat(root))
        {
            var sheetsArray = root.GetProperty("sheets");
            foreach (var formSheet in sheets)
            {
                JsonElement? sheetEl = null;
                foreach (var s in sheetsArray.EnumerateArray())
                {
                    var name = s.TryGetProperty("name", out var n) ? n.GetString() : null;
                    if (string.Equals(name, formSheet.SheetName, StringComparison.OrdinalIgnoreCase))
                    {
                        sheetEl = s;
                        break;
                    }
                }
                if (!sheetEl.HasValue || !sheetEl.Value.TryGetProperty("rows", out var rowsProp))
                    continue;

                var colsWithMapping = columns
                    .Where(c => c.FormSheetId == formSheet.Id && mappingByColumnId.ContainsKey(c.Id))
                    .ToList();
                var rowIndex = 2; // Excel data row start (row 1 = header)
                foreach (var rowEl in rowsProp.EnumerateArray())
                {
                    var dataRow = new ReportDataRow
                    {
                        SubmissionId = submissionId,
                        SheetIndex = formSheet.SheetIndex,
                        RowIndex = rowIndex,
                        CreatedAt = DateTime.UtcNow,
                        CreatedBy = userId
                    };
                    foreach (var col in colsWithMapping)
                    {
                        var mapping = mappingByColumnId[col.Id];
                        object? value = null;
                        if (rowEl.TryGetProperty(col.ExcelColumn, out var cellProp))
                            value = GetJsonElementValue(cellProp, col.DataType);
                        SubmissionExcelServiceHelper.SetDataRowValue(dataRow, mapping.TargetColumnName, col.DataType, value);
                    }
                    dataRowsToInsert.Add(dataRow);
                    dataRowCount++;
                    rowIndex++;
                }
            }
        }
        else if (IsFortuneSheetFormat(root))
        {
            var sheetArray = root;
            foreach (var formSheet in sheets)
            {
                JsonElement? sheetEl = null;
                for (var si = 0; si < sheetArray.GetArrayLength(); si++)
                {
                    var s = sheetArray[si];
                    var name = s.TryGetProperty("name", out var n) ? n.GetString() : null;
                    if (string.Equals(name, formSheet.SheetName, StringComparison.OrdinalIgnoreCase))
                    {
                        sheetEl = s;
                        break;
                    }
                }
                if (!sheetEl.HasValue) continue;
                var grid = BuildGridFromFortuneSheetCelldata(sheetEl.Value);
                var colsWithMapping = columns
                    .Where(c => c.FormSheetId == formSheet.Id && mappingByColumnId.ContainsKey(c.Id))
                    .OrderBy(c => c.DisplayOrder)
                    .ToList();
                if (colsWithMapping.Count == 0) continue;

                var maxRow = grid.Count > 0 ? grid.Keys.Select(k => k.r).Max() : -1;
                var headerRowCount = GetHeaderRowCount(columns.Where(c => c.FormSheetId == formSheet.Id).ToList());
                for (var r = headerRowCount; r <= maxRow; r++)
                {
                    var dataRow = new ReportDataRow
                    {
                        SubmissionId = submissionId,
                        SheetIndex = formSheet.SheetIndex,
                        RowIndex = r + 1,
                        CreatedAt = DateTime.UtcNow,
                        CreatedBy = userId
                    };
                    foreach (var col in colsWithMapping)
                    {
                        var c = colsWithMapping.IndexOf(col);
                        var value = grid.TryGetValue((r, c), out var v) ? v : null;
                        var mapping = mappingByColumnId[col.Id];
                        SubmissionExcelServiceHelper.SetDataRowValue(dataRow, mapping.TargetColumnName, col.DataType, value);
                    }
                    dataRowsToInsert.Add(dataRow);
                    dataRowCount++;
                }
            }
        }
        else
        {
            return Result.Fail<SubmissionUploadResultDto>("INVALID_FORMAT", "Định dạng WorkbookJson không được hỗ trợ (cần sheets[] hoặc FortuneSheet Sheet[]).");
        }

        await _db.ReportDataRows.Where(r => r.SubmissionId == submissionId).ExecuteDeleteAsync(cancellationToken);
        foreach (var r in dataRowsToInsert)
            _db.ReportDataRows.Add(r);

        var dynamicRegions = await _db.FormDynamicRegions
            .AsNoTracking()
            .Where(r => sheetIds.Contains(r.FormSheetId))
            .ToListAsync(cancellationToken);
        var dynamicIndicatorRowsToInsert = new List<ReportDynamicIndicator>();
        if (dynamicRegions.Count > 0)
        {
            if (IsSimpleFormat(root))
                CollectDynamicIndicatorsFromSimpleFormat(root, sheets, dynamicRegions, submissionId, userId, dynamicIndicatorRowsToInsert);
            else if (IsFortuneSheetFormat(root))
                CollectDynamicIndicatorsFromFortuneSheetFormat(root, sheets, columns, dynamicRegions, submissionId, userId, dynamicIndicatorRowsToInsert);
        }

        if (dynamicIndicatorRowsToInsert.Count > 0)
        {
            var regionIds = dynamicRegions.Select(r => r.Id).ToList();
            await _db.ReportDynamicIndicators
                .Where(d => d.SubmissionId == submissionId && regionIds.Contains(d.FormDynamicRegionId))
                .ExecuteDeleteAsync(cancellationToken);
            foreach (var d in dynamicIndicatorRowsToInsert)
                _db.ReportDynamicIndicators.Add(d);
        }

        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok(new SubmissionUploadResultDto
        {
            SubmissionId = submissionId,
            DataRowCount = dataRowCount,
            SheetCount = sheets.Count,
            PresentationUpdated = false,
            Message = $"Đã đồng bộ {dataRowCount} dòng từ nhập liệu web vào bảng dữ liệu."
        });
    }

    /// <summary>B12 P4: Đọc vùng placeholder từ Simple format (sheets[].rows keyed by ExcelColumn) → ReportDynamicIndicator.</summary>
    private static void CollectDynamicIndicatorsFromSimpleFormat(JsonElement root, List<FormSheet> sheets, List<FormDynamicRegion> dynamicRegions, long submissionId, int userId, List<ReportDynamicIndicator> outList)
    {
        var sheetsArray = root.GetProperty("sheets");
        foreach (var region in dynamicRegions)
        {
            var formSheet = sheets.FirstOrDefault(s => s.Id == region.FormSheetId);
            if (formSheet == null) continue;
            JsonElement? sheetEl = null;
            foreach (var s in sheetsArray.EnumerateArray())
            {
                var name = s.TryGetProperty("name", out var n) ? n.GetString() : null;
                if (string.Equals(name, formSheet.SheetName, StringComparison.OrdinalIgnoreCase))
                {
                    sheetEl = s;
                    break;
                }
            }
            if (!sheetEl.HasValue || !sheetEl.Value.TryGetProperty("rows", out var rowsProp))
                continue;
            var rowsArray = rowsProp.EnumerateArray().ToList();
            var firstRowIndex = Math.Max(0, region.ExcelRowStart - 2);
            var lastRowIndex = region.ExcelRowEnd.HasValue
                ? Math.Min(rowsArray.Count - 1, region.ExcelRowEnd.Value - 2)
                : rowsArray.Count - 1;
            if (firstRowIndex > lastRowIndex) continue;
            for (var i = firstRowIndex; i <= lastRowIndex; i++)
            {
                var rowEl = rowsArray[i];
                var indicatorName = GetStringFromJsonElement(rowEl, region.ExcelColName);
                var indicatorValue = GetStringFromJsonElement(rowEl, region.ExcelColValue);
                if (string.IsNullOrWhiteSpace(indicatorName) && string.IsNullOrWhiteSpace(indicatorValue))
                    continue;
                outList.Add(new ReportDynamicIndicator
                {
                    SubmissionId = submissionId,
                    FormDynamicRegionId = region.Id,
                    RowOrder = i - firstRowIndex,
                    IndicatorName = indicatorName ?? string.Empty,
                    IndicatorValue = string.IsNullOrWhiteSpace(indicatorValue) ? null : indicatorValue,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = userId
                });
            }
        }
    }

    /// <summary>B12 P4: Đọc vùng placeholder từ FortuneSheet format (celldata by r,c) → ReportDynamicIndicator. Cột theo index (A=0, B=1, ...).</summary>
    private static void CollectDynamicIndicatorsFromFortuneSheetFormat(JsonElement root, List<FormSheet> sheets, List<FormColumn> columns, List<FormDynamicRegion> dynamicRegions, long submissionId, int userId, List<ReportDynamicIndicator> outList)
    {
        var sheetArray = root;
        foreach (var region in dynamicRegions)
        {
            var formSheet = sheets.FirstOrDefault(s => s.Id == region.FormSheetId);
            if (formSheet == null) continue;
            JsonElement? sheetEl = null;
            for (var si = 0; si < sheetArray.GetArrayLength(); si++)
            {
                var s = sheetArray[si];
                var name = s.TryGetProperty("name", out var n) ? n.GetString() : null;
                if (string.Equals(name, formSheet.SheetName, StringComparison.OrdinalIgnoreCase))
                {
                    sheetEl = s;
                    break;
                }
            }
            if (!sheetEl.HasValue) continue;
            var grid = BuildGridFromFortuneSheetCelldata(sheetEl.Value);
            var colNameIdx = ExcelColLetterToIndex(region.ExcelColName);
            var colValueIdx = ExcelColLetterToIndex(region.ExcelColValue);
            var rStart = region.ExcelRowStart - 1;
            var rEnd = region.ExcelRowEnd ?? (grid.Count > 0 ? grid.Keys.Select(k => k.r).Max() + 1 : rStart);
            var rowOrder = 0;
            for (var r = rStart; r <= rEnd; r++)
            {
                var indicatorName = grid.TryGetValue((r, colNameIdx), out var v1) ? v1?.ToString()?.Trim() : null;
                var indicatorValue = grid.TryGetValue((r, colValueIdx), out var v2) ? v2?.ToString()?.Trim() : null;
                if (string.IsNullOrWhiteSpace(indicatorName) && string.IsNullOrWhiteSpace(indicatorValue))
                    continue;
                outList.Add(new ReportDynamicIndicator
                {
                    SubmissionId = submissionId,
                    FormDynamicRegionId = region.Id,
                    RowOrder = rowOrder++,
                    IndicatorName = indicatorName ?? string.Empty,
                    IndicatorValue = string.IsNullOrWhiteSpace(indicatorValue) ? null : indicatorValue,
                    CreatedAt = DateTime.UtcNow,
                    CreatedBy = userId
                });
            }
        }
    }

    private static string? GetStringFromJsonElement(JsonElement rowEl, string excelCol)
    {
        if (!rowEl.TryGetProperty(excelCol, out var prop)) return null;
        return prop.ValueKind switch
        {
            JsonValueKind.String => prop.GetString(),
            JsonValueKind.Number => prop.GetRawText(),
            JsonValueKind.True => "true",
            JsonValueKind.False => "false",
            _ => prop.GetRawText()
        };
    }

    /// <summary>A=0, B=1, ..., Z=25, AA=26, AB=27, ...</summary>
    private static int ExcelColLetterToIndex(string col)
    {
        if (string.IsNullOrWhiteSpace(col)) return 0;
        col = col.Trim().ToUpperInvariant();
        var idx = 0;
        foreach (var ch in col)
        {
            if (ch < 'A' || ch > 'Z') continue;
            idx = idx * 26 + (ch - 'A' + 1);
        }
        return idx - 1;
    }

    /// <summary>Số hàng header (1 = chỉ tên cột; 2+ = các tầng nhóm + hàng tên cột). Hỗ trợ tối đa 4 tầng nhóm.</summary>
    private static int GetHeaderRowCount(List<FormColumn> columns)
    {
        var levelCount = 0;
        if (columns.Any(c => !string.IsNullOrWhiteSpace(c.ColumnGroupName))) levelCount = 1;
        if (columns.Any(c => !string.IsNullOrWhiteSpace(c.ColumnGroupLevel2))) levelCount = 2;
        if (columns.Any(c => !string.IsNullOrWhiteSpace(c.ColumnGroupLevel3))) levelCount = 3;
        if (columns.Any(c => !string.IsNullOrWhiteSpace(c.ColumnGroupLevel4))) levelCount = 4;
        return levelCount + 1; // +1 hàng tên cột
    }

    private static bool IsSimpleFormat(JsonElement root)
    {
        return root.ValueKind == JsonValueKind.Object && root.TryGetProperty("sheets", out var s) && s.ValueKind == JsonValueKind.Array;
    }

    private static bool IsFortuneSheetFormat(JsonElement root)
    {
        if (root.ValueKind != JsonValueKind.Array || root.GetArrayLength() == 0) return false;
        var first = root[0];
        return first.TryGetProperty("name", out _) && (first.TryGetProperty("celldata", out _) || first.TryGetProperty("data", out _));
    }

    private static Dictionary<(int r, int c), object?> BuildGridFromFortuneSheetCelldata(JsonElement sheet)
    {
        var grid = new Dictionary<(int r, int c), object?>();
        if (!sheet.TryGetProperty("celldata", out var celldata) || celldata.ValueKind != JsonValueKind.Array)
            return grid;
        foreach (var cell in celldata.EnumerateArray())
        {
            var r = cell.TryGetProperty("r", out var rp) ? rp.GetInt32() : 0;
            var c = cell.TryGetProperty("c", out var cp) ? cp.GetInt32() : 0;
            object? value = null;
            if (cell.TryGetProperty("v", out var vProp) && vProp.ValueKind == JsonValueKind.Object)
            {
                if (vProp.TryGetProperty("v", out var vv))
                    value = GetJsonElementValue(vv, "text");
                else if (vProp.TryGetProperty("m", out var vm))
                    value = vm.GetString();
            }
            grid[(r, c)] = value;
        }
        return grid;
    }

    private static object? GetJsonElementValue(JsonElement el, string dataType)
    {
        switch (el.ValueKind)
        {
            case JsonValueKind.Number:
                if (el.TryGetInt64(out var l)) return l;
                if (el.TryGetDouble(out var d)) return d;
                return null;
            case JsonValueKind.String:
                var s = el.GetString();
                if (string.IsNullOrEmpty(s)) return null;
                if (dataType?.ToLowerInvariant() == "number" && decimal.TryParse(s, out var dec)) return dec;
                if (dataType?.ToLowerInvariant() == "date" && DateTime.TryParse(s, out var dt)) return dt;
                return s;
            case JsonValueKind.True: return true;
            case JsonValueKind.False: return false;
            case JsonValueKind.Null:
            case JsonValueKind.Undefined:
            default: return null;
        }
    }
}
