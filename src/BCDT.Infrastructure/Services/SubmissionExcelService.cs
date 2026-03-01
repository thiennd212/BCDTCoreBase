using System.Security.Cryptography;
using System.Text;
using System.Text.Json;
using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.Services.Data;
using BCDT.Domain.Entities.Data;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using ClosedXML.Excel;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class SubmissionExcelService : ISubmissionExcelService
{
    private readonly AppDbContext _db;

    public SubmissionExcelService(AppDbContext db) => _db = db;

    public async Task<Result<SubmissionUploadResultDto>> ProcessUploadedExcelAsync(long submissionId, Stream excelStream, int userId, CancellationToken cancellationToken = default)
    {
        var submission = await _db.ReportSubmissions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == submissionId && !s.IsDeleted, cancellationToken);
        if (submission == null)
            return Result.Fail<SubmissionUploadResultDto>("NOT_FOUND", "Submission không tồn tại.");

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

        XLWorkbook workbook;
        try
        {
            workbook = new XLWorkbook(excelStream);
        }
        catch (Exception ex)
        {
            return Result.Fail<SubmissionUploadResultDto>("INVALID_FILE", "File Excel không hợp lệ: " + ex.Message);
        }

        using (workbook)
        {
            var workbookData = new List<object>();
            var dataRowsToInsert = new List<ReportDataRow>();
            const int headerRow = 1;
            int dataRowCount = 0;

            foreach (var formSheet in sheets)
            {
                var ws = workbook.Worksheets.FirstOrDefault(w =>
                    string.Equals(w.Name, formSheet.SheetName, StringComparison.OrdinalIgnoreCase));
                if (ws == null)
                    continue;

                var colsWithMapping = columns
                    .Where(c => c.FormSheetId == formSheet.Id && mappingByColumnId.ContainsKey(c.Id))
                    .ToList();
                var sheetJsonRows = new List<Dictionary<string, object?>>();

                var lastRow = ws.LastRowUsed()?.RowNumber() ?? 0;
                for (int row = headerRow + 1; row <= lastRow; row++)
                {
                    var dataRow = new ReportDataRow
                    {
                        SubmissionId = submissionId,
                        SheetIndex = formSheet.SheetIndex,
                        RowIndex = row,
                        CreatedAt = DateTime.UtcNow,
                        CreatedBy = userId
                    };
                    var rowDict = new Dictionary<string, object?>();

                    foreach (var col in colsWithMapping)
                    {
                        var mapping = mappingByColumnId[col.Id];
                        var cellAddr = $"{col.ExcelColumn}{row}";
                        var cell = ws.Cell(cellAddr);
                        var value = GetCellValue(cell, col.DataType);
                        SubmissionExcelServiceHelper.SetDataRowValue(dataRow, mapping.TargetColumnName, col.DataType, value);
                        rowDict[col.ExcelColumn!] = value;
                    }

                    dataRowsToInsert.Add(dataRow);
                    sheetJsonRows.Add(rowDict);
                    dataRowCount++;
                }

                workbookData.Add(new { name = formSheet.SheetName, rows = sheetJsonRows });
            }

            var workbookJson = JsonSerializer.Serialize(new { sheets = workbookData });
            var hashBytes = SHA256.HashData(Encoding.UTF8.GetBytes(workbookJson));
            var workbookHash = Convert.ToHexString(hashBytes).ToLowerInvariant();
            var fileSize = Encoding.UTF8.GetByteCount(workbookJson);

            await _db.ReportDataRows.Where(r => r.SubmissionId == submissionId).ExecuteDeleteAsync(cancellationToken);

            foreach (var r in dataRowsToInsert)
                _db.ReportDataRows.Add(r);

            var existingPresentation = await _db.ReportPresentations.FirstOrDefaultAsync(p => p.SubmissionId == submissionId, cancellationToken);
            if (existingPresentation != null)
            {
                existingPresentation.WorkbookJson = workbookJson;
                existingPresentation.WorkbookHash = workbookHash;
                existingPresentation.FileSize = fileSize;
                existingPresentation.SheetCount = (byte)workbook.Worksheets.Count;
                existingPresentation.LastModifiedAt = DateTime.UtcNow;
                existingPresentation.LastModifiedBy = userId;
            }
            else
            {
                _db.ReportPresentations.Add(new ReportPresentation
                {
                    SubmissionId = submissionId,
                    WorkbookJson = workbookJson,
                    WorkbookHash = workbookHash,
                    FileSize = fileSize,
                    SheetCount = (byte)workbook.Worksheets.Count,
                    LastModifiedAt = DateTime.UtcNow,
                    LastModifiedBy = userId
                });
            }

            await _db.SaveChangesAsync(cancellationToken);
            return Result.Ok(new SubmissionUploadResultDto
            {
                SubmissionId = submissionId,
                DataRowCount = dataRowCount,
                SheetCount = workbook.Worksheets.Count,
                PresentationUpdated = true,
                Message = $"Đã nhập {dataRowCount} dòng dữ liệu từ {workbook.Worksheets.Count} sheet."
            });
        }
    }

    private static object? GetCellValue(IXLCell cell, string dataType)
    {
        if (cell.IsEmpty())
            return null;
        try
        {
            return (dataType?.ToLowerInvariant()) switch
            {
                "number" => cell.TryGetValue(out decimal num) ? num : (cell.TryGetValue(out double d) ? (object)d : cell.GetString()),
                "date" => cell.TryGetValue(out DateTime dt) ? dt : (object?)(DateTime.TryParse(cell.GetString(), out var parsed) ? parsed : null),
                "boolean" => cell.TryGetValue(out bool b) ? b : (object?)(bool.TryParse(cell.GetString(), out var bp) ? bp : null),
                _ => cell.GetString()
            };
        }
        catch
        {
            return cell.GetString();
        }
    }
}
