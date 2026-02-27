using System.Collections.Generic;
using System.Drawing;
using System.IO;
using System.Text.Json;
using ClosedXML.Excel;

namespace BCDT.Infrastructure.Services;

/// <summary>Thông tin sheet trích xuất từ template (tên, thứ tự, danh sách cột).</summary>
public class ExtractedSheetInfo
{
    public string SheetName { get; set; } = string.Empty;
    public int SheetIndex { get; set; }
    public List<ExtractedColumnInfo> Columns { get; set; } = new();
}

/// <summary>Thông tin cột trích xuất từ template (tên, cột Excel, kiểu dữ liệu).</summary>
public class ExtractedColumnInfo
{
    public string ColumnName { get; set; } = string.Empty;
    public string ExcelColumn { get; set; } = string.Empty;
    public string DataType { get; set; } = "Text";
}

/// <summary>Cấu trúc biểu mẫu trích xuất từ file Excel (danh sách sheet, mỗi sheet có danh sách cột).</summary>
public class ExtractedFormStructure
{
    public List<ExtractedSheetInfo> Sheets { get; set; } = new();
}

/// <summary>Chuyển file Excel (.xlsx) upload thành JSON định dạng Fortune-sheet (celldata + merge + style) để dùng làm base hiển thị nhập liệu.</summary>
public static class ExcelTemplateParser
{
    /// <summary>Trích xuất cấu trúc (sheet + cột) từ workbook. Hàng đầu tiên dùng làm tên cột; format ô gợi ý DataType.</summary>
    public static ExtractedFormStructure ExtractStructure(Stream xlsxStream)
    {
        var result = new ExtractedFormStructure();
        using var workbook = new XLWorkbook(xlsxStream);
        var sheetIndex = 0;
        foreach (var ws in workbook.Worksheets)
        {
            var name = string.IsNullOrEmpty(ws.Name) ? "Sheet" + (sheetIndex + 1) : TruncateSheetName(ws.Name);
            var columns = new List<ExtractedColumnInfo>();
            var used = ws.RangeUsed();
            if (used != null)
            {
                var minC = used.FirstColumn().ColumnNumber();
                var maxC = used.LastColumn().ColumnNumber();
                const int headerRow = 1;
                for (var col = minC; col <= maxC; col++)
                {
                    var cell = ws.Cell(headerRow, col);
                    var colName = cell.GetString()?.Trim();
                    if (string.IsNullOrEmpty(colName)) colName = "Cột " + ColumnIndexToLetter(col);
                    var dataType = InferDataType(cell);
                    columns.Add(new ExtractedColumnInfo
                    {
                        ColumnName = colName,
                        ExcelColumn = ColumnIndexToLetter(col),
                        DataType = dataType
                    });
                }
            }
            result.Sheets.Add(new ExtractedSheetInfo
            {
                SheetName = name,
                SheetIndex = sheetIndex,
                Columns = columns
            });
            sheetIndex++;
        }
        if (result.Sheets.Count == 0)
            result.Sheets.Add(new ExtractedSheetInfo { SheetName = "Sheet1", SheetIndex = 0, Columns = new List<ExtractedColumnInfo>() });
        return result;
    }

    private static string InferDataType(IXLCell cell)
    {
        try
        {
            var format = cell.Style.NumberFormat.NumberFormatId;
            if (format >= 14 && format <= 22) return "Date";
            if (format == 2 || format == 4 || (format >= 37 && format <= 44)) return "Number";
            var formatStr = cell.Style.NumberFormat.Format?.ToLowerInvariant() ?? "";
            if (formatStr.Contains("d") || formatStr.Contains("y") || formatStr.Contains("m") && !formatStr.Contains("mm")) return "Date";
            if (formatStr.Contains("0") || formatStr.Contains("#")) return "Number";
        }
        catch { /* ignore */ }
        return "Text";
    }

    internal static string ColumnIndexToLetter(int col1Based)
    {
        var s = "";
        var n = col1Based;
        while (n > 0)
        {
            var r = (n - 1) % 26;
            s = (char)('A' + r) + s;
            n = (n - 1) / 26;
        }
        return string.IsNullOrEmpty(s) ? "A" : s;
    }

    /// <summary>Parse workbook từ stream, trả về JSON string (mảng Sheet Fortune-sheet).</summary>
    public static string ParseToFortuneSheetJson(Stream xlsxStream)
    {
        using var workbook = new XLWorkbook(xlsxStream);
        var sheets = new List<FortuneSheetOutput>();
        var index = 0;
        foreach (var ws in workbook.Worksheets)
        {
            var sheet = ParseWorksheet(ws, index);
            if (sheet != null)
                sheets.Add(sheet);
            index++;
        }
        if (sheets.Count == 0)
            sheets.Add(new FortuneSheetOutput { name = "Sheet1", celldata = new List<FortuneCellItem>(), row = 50, column = 20 });
        return JsonSerializer.Serialize(sheets, JsonOptions());
    }

    private static JsonSerializerOptions JsonOptions()
    {
        return new JsonSerializerOptions { PropertyNamingPolicy = JsonNamingPolicy.CamelCase, WriteIndented = false };
    }

    private static FortuneSheetOutput? ParseWorksheet(IXLWorksheet ws, int order)
    {
        var name = string.IsNullOrEmpty(ws.Name) ? "Sheet" + (order + 1) : TruncateSheetName(ws.Name);
        var used = ws.RangeUsed();
        if (used == null)
            return new FortuneSheetOutput { name = name, celldata = new List<FortuneCellItem>(), order = order, row = 50, column = 20 };

        var mergeMap = new Dictionary<string, MergeInfo>();
        foreach (var range in ws.MergedRanges)
        {
            var r = range.FirstRow().RowNumber() - 1;
            var c = range.FirstColumn().ColumnNumber() - 1;
            var rs = range.RowCount();
            var cs = range.ColumnCount();
            var key = $"{r}_{c}";
            mergeMap[key] = new MergeInfo { r = r, c = c, rs = rs, cs = cs };
        }

        var celldata = new List<FortuneCellItem>();
        var minR = used.FirstRow().RowNumber();
        var maxR = used.LastRow().RowNumber();
        var minC = used.FirstColumn().ColumnNumber();
        var maxC = used.LastColumn().ColumnNumber();

        for (var row = minR; row <= maxR; row++)
        {
            for (var col = minC; col <= maxC; col++)
            {
                var r0 = row - 1;
                var c0 = col - 1;
                var cell = ws.Cell(row, col);
                var mergeKey = $"{r0}_{c0}";
                MergeInfo? mc = null;
                var isTopLeftOfMerge = mergeMap.TryGetValue(mergeKey, out var m);
                if (isTopLeftOfMerge) mc = m;
                else
                {
                    foreach (var kv in mergeMap)
                    {
                        var mr = kv.Value;
                        if (r0 >= mr.r && r0 < mr.r + mr.rs && c0 >= mr.c && c0 < mr.c + mr.cs && (r0 != mr.r || c0 != mr.c))
                        {
                            mc = mr;
                            break;
                        }
                    }
                }

                FortuneSheetCellValue? v;
                if (mc != null && !isTopLeftOfMerge)
                {
                    v = new FortuneSheetCellValue { mc = mc };
                }
                else
                {
                    object? rawValue = cell.Value;
                    string? display = cell.GetString();
                    if (rawValue is DateTime dt)
                        display = dt.ToString("yyyy-MM-dd");
                    else if (display == null && rawValue != null)
                        display = rawValue.ToString();

                    v = new FortuneSheetCellValue
                    {
                        v = rawValue is double d ? d : rawValue is int i ? i : rawValue is bool b ? b : rawValue is DateTime ? display : rawValue,
                        m = display,
                        ct = new CellType { fa = "General", t = rawValue is double || rawValue is int ? "n" : "g" },
                        bg = TryGetBackgroundHex(cell),
                        bl = cell.Style.Font.Bold ? 1 : (int?)null,
                        ht = 1,
                        vt = 1,
                        mc = mc
                    };
                }
                celldata.Add(new FortuneCellItem { r = r0, c = c0, v = v });
            }
        }

        var mergeConfig = mergeMap.Count > 0 ? new Dictionary<string, MergeInfo>(mergeMap) : null;
        var rowCount = maxR - minR + 1;
        var colCount = maxC - minC + 1;
        return new FortuneSheetOutput
        {
            name = name,
            celldata = celldata,
            config = mergeConfig != null ? new FortuneSheetConfig { merge = mergeConfig } : null,
            order = order,
            row = Math.Max(50, rowCount + 10),
            column = Math.Max(20, colCount + 2)
        };
    }

    private static string? TryGetBackgroundHex(IXLCell cell)
    {
        try
        {
            var fill = cell.Style.Fill;
            if (fill?.BackgroundColor == null) return null;
            var xlColor = fill.BackgroundColor;
            if (xlColor.ColorType == XLColorType.Color)
            {
                var c = xlColor.Color;
                return "#" + c.R.ToString("X2") + c.G.ToString("X2") + c.B.ToString("X2");
            }
        }
        catch
        {
            // Theme color hoặc format đặc biệt có thể throw
        }
        return null;
    }

    private static string TruncateSheetName(string name)
    {
        if (string.IsNullOrEmpty(name)) return "Sheet";
        if (name.Length <= 31) return name;
        return name[..28] + "...";
    }

    // DTOs cho serialization Fortune-sheet
    private class FortuneSheetOutput
    {
        public string name { get; set; } = "";
        public List<FortuneCellItem> celldata { get; set; } = new();
        public FortuneSheetConfig? config { get; set; }
        public int? order { get; set; }
        public int? row { get; set; }
        public int? column { get; set; }
    }

    private class FortuneCellItem
    {
        public int r { get; set; }
        public int c { get; set; }
        public FortuneSheetCellValue? v { get; set; }
    }

    private class FortuneSheetCellValue
    {
        public object? v { get; set; }
        public string? m { get; set; }
        public CellType? ct { get; set; }
        public string? bg { get; set; }
        public int? bl { get; set; }
        public int? ht { get; set; }
        public int? vt { get; set; }
        public MergeInfo? mc { get; set; }
    }

    private class CellType
    {
        public string fa { get; set; } = "General";
        public string t { get; set; } = "g";
    }

    private class MergeInfo
    {
        public int r { get; set; }
        public int c { get; set; }
        public int rs { get; set; }
        public int cs { get; set; }
    }

    private class FortuneSheetConfig
    {
        public Dictionary<string, MergeInfo>? merge { get; set; }
    }
}
