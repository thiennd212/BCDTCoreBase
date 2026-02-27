using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormCellFormulaService : IFormCellFormulaService
{
    private readonly AppDbContext _db;

    public FormCellFormulaService(AppDbContext db) => _db = db;

    public async Task<Result<List<FormCellFormulaDto>>> GetBySheetIdAsync(int formDefinitionId, int sheetId, CancellationToken ct = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, ct);
        if (!sheetExists)
            return Result.Fail<List<FormCellFormulaDto>>("NOT_FOUND", "Sheet không tồn tại.");

        var list = await _db.FormCellFormulas
            .AsNoTracking()
            .Where(f => f.FormSheetId == sheetId)
            .ToListAsync(ct);
        return Result.Ok(list.Select(MapToDto).ToList());
    }

    public async Task<Result<FormCellFormulaDto>> UpsertAsync(int formDefinitionId, int sheetId, CreateFormCellFormulaRequest request, int userId, CancellationToken ct = default)
    {
        var sheet = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, ct);
        if (sheet == null)
            return Result.Fail<FormCellFormulaDto>("NOT_FOUND", "Sheet không tồn tại.");

        var colExists = await _db.FormColumns.AnyAsync(c => c.Id == request.FormColumnId && c.FormSheetId == sheetId, ct);
        if (!colExists)
            return Result.Fail<FormCellFormulaDto>("NOT_FOUND", "Cột không tồn tại trong sheet này.");

        var rowExists = await _db.FormRows.AnyAsync(r => r.Id == request.FormRowId && r.FormSheetId == sheetId, ct);
        if (!rowExists)
            return Result.Fail<FormCellFormulaDto>("NOT_FOUND", "Hàng không tồn tại trong sheet này.");

        var existing = await _db.FormCellFormulas
            .FirstOrDefaultAsync(f => f.FormColumnId == request.FormColumnId && f.FormRowId == request.FormRowId, ct);

        if (existing != null)
        {
            existing.Formula = request.Formula;
            existing.IsEditable = request.IsEditable;
            existing.UpdatedAt = DateTime.UtcNow;
            existing.UpdatedBy = userId;
            await _db.SaveChangesAsync(ct);
            return Result.Ok(MapToDto(existing));
        }

        var entity = new FormCellFormula
        {
            FormSheetId = sheetId,
            FormColumnId = request.FormColumnId,
            FormRowId = request.FormRowId,
            Formula = request.Formula,
            IsEditable = request.IsEditable,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = userId
        };
        _db.FormCellFormulas.Add(entity);
        await _db.SaveChangesAsync(ct);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, int id, CancellationToken ct = default)
    {
        var entity = await _db.FormCellFormulas
            .FirstOrDefaultAsync(f => f.Id == id && f.FormSheetId == sheetId, ct);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Không tìm thấy cell formula.");

        _db.FormCellFormulas.Remove(entity);
        await _db.SaveChangesAsync(ct);
        return Result.Ok<object>(new { });
    }

    private static FormCellFormulaDto MapToDto(FormCellFormula f) => new()
    {
        Id = f.Id,
        FormSheetId = f.FormSheetId,
        FormColumnId = f.FormColumnId,
        FormRowId = f.FormRowId,
        Formula = f.Formula,
        IsEditable = f.IsEditable,
        CreatedAt = f.CreatedAt,
        CreatedBy = f.CreatedBy,
        UpdatedAt = f.UpdatedAt,
        UpdatedBy = f.UpdatedBy
    };
}
