using System.Collections.Generic;
using BCDT.Application.Common;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using ClosedXML.Excel;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormTemplateService : IFormTemplateService
{
    private readonly AppDbContext _db;
    private readonly IDataBindingResolver _resolver;

    public FormTemplateService(AppDbContext db, IDataBindingResolver resolver)
    {
        _db = db;
        _resolver = resolver;
    }

    public async Task<Result<byte[]>> GetTemplateAsync(
        int formId,
        bool fillBinding,
        ResolveContext? context = null,
        CancellationToken cancellationToken = default)
    {
        var form = await _db.FormDefinitions
            .AsNoTracking()
            .FirstOrDefaultAsync(f => f.Id == formId && !f.IsDeleted, cancellationToken);
        if (form == null)
            return Result.Fail<byte[]>("NOT_FOUND", "Biểu mẫu không tồn tại.");

        var sheets = await _db.FormSheets
            .AsNoTracking()
            .Where(s => s.FormDefinitionId == formId)
            .OrderBy(s => s.DisplayOrder).ThenBy(s => s.SheetIndex)
            .ToListAsync(cancellationToken);

        var sheetIds = sheets.Select(s => s.Id).ToList();
        var columnsBySheet = await _db.FormColumns
            .AsNoTracking()
            .Where(c => sheetIds.Contains(c.FormSheetId))
            .OrderBy(c => c.FormSheetId).ThenBy(c => c.DisplayOrder).ThenBy(c => c.Id)
            .ToListAsync(cancellationToken);

        var columnIds = columnsBySheet.Select(c => c.Id).ToList();
        Dictionary<int, FormDataBinding>? bindingByColumn = null;
        if (fillBinding && columnIds.Count > 0)
        {
            var bindings = await _db.FormDataBindings
                .AsNoTracking()
                .Where(b => columnIds.Contains(b.FormColumnId) && b.IsActive)
                .ToListAsync(cancellationToken);
            bindingByColumn = bindings.ToDictionary(b => b.FormColumnId);
        }

        var resolveCtx = context ?? new ResolveContext { CurrentDate = DateTime.UtcNow };

        using var workbook = new XLWorkbook();
        if (sheets.Count == 0)
        {
            workbook.Worksheets.Add("Sheet1");
        }
        foreach (var sheet in sheets)
        {
            var cols = columnsBySheet.Where(c => c.FormSheetId == sheet.Id).ToList();
            var ws = workbook.Worksheets.Add(TruncateSheetName(sheet.SheetName));

            int headerRow = 1;
            int dataRow = 2;

            foreach (var col in cols)
            {
                var addressHeader = $"{col.ExcelColumn}{headerRow}";
                ws.Cell(addressHeader).Value = col.ColumnName;

                if (col.Width.HasValue && col.Width.Value > 0)
                    ws.Column(col.ExcelColumn).Width = Math.Min(col.Width.Value, 100);

                if (fillBinding)
                {
                    var addressData = $"{col.ExcelColumn}{dataRow}";
                    object? cellValue = col.DefaultValue ?? "";
                    if (bindingByColumn != null && bindingByColumn.TryGetValue(col.Id, out var binding))
                    {
                        var resolved = await _resolver.ResolveValueAsync(binding, col, resolveCtx, cancellationToken);
                        if (resolved.IsSuccess && resolved.Data != null)
                            cellValue = resolved.Data;
                    }
                    SetCellValue(ws.Cell(addressData), ToCellValue(cellValue, col.DataType));
                    if (!col.IsEditable)
                        ws.Cell(addressData).Style.Protection.Locked = true;
                }
                else if (!col.IsEditable)
                {
                    ws.Cell($"{col.ExcelColumn}{dataRow}").Style.Protection.Locked = true;
                }
            }

            if (cols.Any(c => !c.IsEditable))
                ws.Protect();
        }

        using var ms = new MemoryStream();
        workbook.SaveAs(ms);
        return Result.Ok(ms.ToArray());
    }

    private static object? ToCellValue(object? value, string dataType) => value;

    private static void SetCellValue(ClosedXML.Excel.IXLCell cell, object? value)
    {
        if (value == null) { cell.Value = ""; return; }
        if (value is string s) { cell.Value = s; return; }
        if (value is int i) { cell.Value = i; return; }
        if (value is long l) { cell.Value = l; return; }
        if (value is double d) { cell.Value = d; return; }
        if (value is decimal dec) { cell.Value = (double)dec; return; }
        if (value is DateTime dt) { cell.Value = dt; return; }
        cell.Value = value.ToString() ?? "";
    }

    private static string TruncateSheetName(string name)
    {
        if (string.IsNullOrEmpty(name)) return "Sheet";
        if (name.Length <= 31) return name;
        return name[..28] + "...";
    }

    public async Task<Result<object>> UploadTemplateAsync(int formId, Stream xlsxStream, string fileName, CancellationToken cancellationToken = default)
    {
        var form = await _db.FormDefinitions.FirstOrDefaultAsync(f => f.Id == formId && !f.IsDeleted, cancellationToken);
        if (form == null)
            return Result.Fail<object>("NOT_FOUND", "Biểu mẫu không tồn tại.");

        byte[] bytes;
        try
        {
            using var ms = new MemoryStream();
            await xlsxStream.CopyToAsync(ms, cancellationToken);
            ms.Position = 0;
            bytes = ms.ToArray();
            using var parseStream = new MemoryStream(bytes);
            var displayJson = ExcelTemplateParser.ParseToFortuneSheetJson(parseStream);
            form.TemplateFile = bytes;
            form.TemplateFileName = string.IsNullOrEmpty(fileName) ? "template.xlsx" : Path.GetFileName(fileName);
            form.TemplateDisplayJson = displayJson;
            await _db.SaveChangesAsync(cancellationToken);
        }
        catch (Exception ex)
        {
            return Result.Fail<object>("PARSE_ERROR", "Không thể đọc file Excel: " + ex.Message);
        }

        return Result.Ok<object>(new { formId, fileName = form.TemplateFileName, hasDisplay = true });
    }

    public async Task<Result<string?>> GetTemplateDisplayJsonAsync(int formId, CancellationToken cancellationToken = default)
    {
        var form = await _db.FormDefinitions
            .AsNoTracking()
            .Where(f => f.Id == formId && !f.IsDeleted)
            .Select(f => f.TemplateDisplayJson)
            .FirstOrDefaultAsync(cancellationToken);
        return Result.Ok<string?>(form);
    }
}
