using System.Text.RegularExpressions;
using BCDT.Application.DTOs.Data;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;

namespace BCDT.Infrastructure.Services;

/// <summary>Inject công thức Excel vào Fortune Sheet celldata.
/// Priority: FormCellFormula (highest) > FormRow.Formula > FormColumn.Formula (lowest).
/// Placeholders: {COL} {ROW} {DATA_START_ROW} {PREV_ROW} {NEXT_ROW} {COL_X} (X = ColumnCode).
/// Fortune Sheet cell format: { r: int, c: int, v: { f: "=...", v: null } }</summary>
public class FormulaInjectionService : IFormulaInjectionService
{
    public void InjectFormulas(
        WorkbookSheetFromSubmissionDto sheet,
        List<FormColumn> columns,
        List<FormRow> rows,
        List<FormRowFormulaScope> rowScopes,
        List<FormCellFormula> cellFormulas,
        ColumnLayoutResult layout,
        int dataStartRow,
        int dataEndRow)
    {
        if (layout.Slots.Count == 0) return;

        // Build lookup maps
        var slotByColumnId = layout.Slots
            .Where(s => s.FormColumnId.HasValue)
            .ToDictionary(s => s.FormColumnId!.Value, s => s);
        var slotByExcelCol = layout.Slots.ToDictionary(s => s.ExcelColumn, s => s);
        var colByExcelCol = columns.ToDictionary(c => c.ExcelColumn ?? "", c => c);
        var colById = columns.ToDictionary(c => c.Id, c => c);

        // Build ColumnCode → ExcelColumn map for {COL_X} placeholder
        var codeToExcelCol = layout.Slots
            .Where(s => s.ColumnCode != null)
            .ToDictionary(s => s.ColumnCode!, s => s.ExcelColumn, StringComparer.OrdinalIgnoreCase);

        // Cell-level overrides: (FormColumnId, FormRowId) → FormCellFormula
        var cellFormulaByKey = cellFormulas.ToDictionary(f => (f.FormColumnId, f.FormRowId), f => f);

        // Row formula scopes: FormRowId → set of FormColumnId
        var rowScopesByRowId = rowScopes
            .GroupBy(s => s.FormRowId)
            .ToDictionary(g => g.Key, g => g.Select(s => s.FormColumnId).ToHashSet());

        // Build FortuneSheet celldata list if not present
        if (sheet.Celldata == null) sheet.Celldata = new List<Dictionary<string, object?>>();

        // Build existing cell index: (r, c) → index in Celldata
        var celldataIndex = new Dictionary<(int r, int c), int>();
        for (var i = 0; i < sheet.Celldata.Count; i++)
        {
            if (sheet.Celldata[i].TryGetValue("r", out var rv) && sheet.Celldata[i].TryGetValue("c", out var cv))
            {
                var r = Convert.ToInt32(rv);
                var c = Convert.ToInt32(cv);
                celldataIndex[(r, c)] = i;
            }
        }

        void SetCellFormula(int r, int c, string formula)
        {
            if (celldataIndex.TryGetValue((r, c), out var idx))
            {
                var cell = sheet.Celldata[idx];
                if (!cell.TryGetValue("v", out var vObj) || vObj == null)
                    cell["v"] = new Dictionary<string, object?> { ["f"] = formula, ["v"] = null };
                else if (vObj is Dictionary<string, object?> vDict)
                    vDict["f"] = formula;
                else
                    cell["v"] = new Dictionary<string, object?> { ["f"] = formula, ["v"] = null };
            }
            else
            {
                var newCell = new Dictionary<string, object?>
                {
                    ["r"] = r,
                    ["c"] = c,
                    ["v"] = new Dictionary<string, object?> { ["f"] = formula, ["v"] = null }
                };
                sheet.Celldata.Add(newCell);
                celldataIndex[(r, c)] = sheet.Celldata.Count - 1;
            }
        }

        // 1. Column formulas: inject into each data row (dataStartRow..dataEndRow), 0-based row index
        foreach (var slot in layout.Slots)
        {
            if (!slot.FormColumnId.HasValue) continue;
            var col = colById.GetValueOrDefault(slot.FormColumnId.Value);
            if (col == null || string.IsNullOrWhiteSpace(col.Formula)) continue;

            var colIndex = layout.Slots.IndexOf(slot);

            for (var rowIdx = dataStartRow; rowIdx <= dataEndRow; rowIdx++)
            {
                // Check cell-level override exists → skip column formula
                var hasCell = cellFormulaByKey.ContainsKey((col.Id, GetFormRowId(rows, rowIdx)));
                if (hasCell) continue;

                var resolved = ResolvePlaceholders(col.Formula, slot.ExcelColumn, rowIdx + 1, dataStartRow + 1, codeToExcelCol);
                if (!string.IsNullOrWhiteSpace(resolved))
                    SetCellFormula(rowIdx, colIndex, resolved);
            }
        }

        // 2. Row formulas
        foreach (var row in rows)
        {
            if (string.IsNullOrWhiteSpace(row.Formula)) continue;

            // Determine which Excel row index this FormRow maps to (0-based)
            var rowIdx = row.ExcelRowStart - 1; // ExcelRowStart is 1-based

            // Determine scope: which column slots to inject into
            rowScopesByRowId.TryGetValue(row.Id, out var scopeColIds);

            foreach (var slot in layout.Slots)
            {
                if (!slot.FormColumnId.HasValue) continue;
                var col = colById.GetValueOrDefault(slot.FormColumnId.Value);
                if (col == null) continue;

                // If scope defined → only inject into scoped columns
                if (scopeColIds != null && !scopeColIds.Contains(col.Id)) continue;
                // If no scope → inject into all editable Number/Formula columns
                if (scopeColIds == null && !(col.IsEditable && (col.DataType is "Number" or "Formula"))) continue;

                // Check cell-level override
                if (cellFormulaByKey.ContainsKey((col.Id, row.Id))) continue;

                var colIndex = layout.Slots.IndexOf(slot);
                var resolved = ResolvePlaceholders(row.Formula, slot.ExcelColumn, rowIdx + 1, dataStartRow + 1, codeToExcelCol);
                if (!string.IsNullOrWhiteSpace(resolved))
                    SetCellFormula(rowIdx, colIndex, resolved);
            }
        }

        // 3. Cell-level overrides (highest priority)
        foreach (var cellFml in cellFormulas)
        {
            if (string.IsNullOrWhiteSpace(cellFml.Formula)) continue;
            if (!slotByColumnId.TryGetValue(cellFml.FormColumnId, out var slot)) continue;

            var row = rows.FirstOrDefault(r => r.Id == cellFml.FormRowId);
            if (row == null) continue;

            var rowIdx = row.ExcelRowStart - 1;
            var colIndex = layout.Slots.IndexOf(slot);
            var resolved = ResolvePlaceholders(cellFml.Formula, slot.ExcelColumn, rowIdx + 1, dataStartRow + 1, codeToExcelCol);
            if (!string.IsNullOrWhiteSpace(resolved))
                SetCellFormula(rowIdx, colIndex, resolved);
        }
    }

    /// <summary>Substitute placeholder tokens in a formula template.
    /// {COL}=excelCol, {ROW}=rowNum(1-based), {DATA_START_ROW}=dataStart, {PREV_ROW}=rowNum-1, {NEXT_ROW}=rowNum+1, {COL_X}=excelCol of column with code X.</summary>
    private static string ResolvePlaceholders(string formula, string excelCol, int rowNum, int dataStartRow, Dictionary<string, string> codeToExcelCol)
    {
        var result = formula
            .Replace("{COL}", excelCol)
            .Replace("{ROW}", rowNum.ToString())
            .Replace("{DATA_START_ROW}", dataStartRow.ToString())
            .Replace("{PREV_ROW}", (rowNum - 1).ToString())
            .Replace("{NEXT_ROW}", (rowNum + 1).ToString());

        // {COL_X} → column letter of FormColumn with ColumnCode = X
        result = Regex.Replace(result, @"\{COL_([A-Za-z0-9_]+)\}", m =>
        {
            var code = m.Groups[1].Value;
            return codeToExcelCol.TryGetValue(code, out var letter) ? letter : m.Value;
        });

        return result;
    }

    /// <summary>Tìm FormRow có ExcelRowStart tương ứng với rowIdx (0-based). Trả về 0 nếu không tìm thấy.</summary>
    private static int GetFormRowId(List<FormRow> rows, int rowIdx)
    {
        // rowIdx is 0-based; ExcelRowStart is 1-based
        var row = rows.FirstOrDefault(r => r.ExcelRowStart - 1 == rowIdx);
        return row?.Id ?? 0;
    }
}
