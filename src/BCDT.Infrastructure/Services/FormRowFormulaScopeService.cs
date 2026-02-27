using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormRowFormulaScopeService : IFormRowFormulaScopeService
{
    private readonly AppDbContext _db;

    public FormRowFormulaScopeService(AppDbContext db) => _db = db;

    public async Task<Result<List<FormRowFormulaScopeDto>>> GetByRowIdAsync(int formDefinitionId, int sheetId, int rowId, CancellationToken ct = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, ct);
        if (!sheetExists)
            return Result.Fail<List<FormRowFormulaScopeDto>>("NOT_FOUND", "Sheet không tồn tại.");
        var rowExists = await _db.FormRows.AnyAsync(r => r.Id == rowId && r.FormSheetId == sheetId, ct);
        if (!rowExists)
            return Result.Fail<List<FormRowFormulaScopeDto>>("NOT_FOUND", "Hàng không tồn tại.");

        var list = await _db.FormRowFormulaScopes
            .AsNoTracking()
            .Where(s => s.FormRowId == rowId)
            .ToListAsync(ct);
        return Result.Ok(list.Select(MapToDto).ToList());
    }

    public async Task<Result<FormRowFormulaScopeDto>> CreateAsync(int formDefinitionId, int sheetId, int rowId, CreateFormRowFormulaScopeRequest request, int createdBy, CancellationToken ct = default)
    {
        var row = await _db.FormRows
            .Where(r => r.Id == rowId && r.FormSheetId == sheetId)
            .Join(_db.FormSheets.Where(s => s.FormDefinitionId == formDefinitionId), r => r.FormSheetId, s => s.Id, (r, _) => r)
            .FirstOrDefaultAsync(ct);
        if (row == null)
            return Result.Fail<FormRowFormulaScopeDto>("NOT_FOUND", "Hàng không tồn tại.");

        var colExists = await _db.FormColumns.AnyAsync(c => c.Id == request.FormColumnId && c.FormSheetId == sheetId, ct);
        if (!colExists)
            return Result.Fail<FormRowFormulaScopeDto>("NOT_FOUND", "Cột không tồn tại trong sheet này.");

        var duplicate = await _db.FormRowFormulaScopes.AnyAsync(s => s.FormRowId == rowId && s.FormColumnId == request.FormColumnId, ct);
        if (duplicate)
            return Result.Fail<FormRowFormulaScopeDto>("CONFLICT", "Cột đã được thêm vào phạm vi công thức của hàng này.");

        var entity = new FormRowFormulaScope
        {
            FormRowId = rowId,
            FormColumnId = request.FormColumnId,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormRowFormulaScopes.Add(entity);
        await _db.SaveChangesAsync(ct);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, int rowId, int id, CancellationToken ct = default)
    {
        var entity = await _db.FormRowFormulaScopes
            .Where(s => s.Id == id && s.FormRowId == rowId)
            .FirstOrDefaultAsync(ct);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Không tìm thấy scope.");

        _db.FormRowFormulaScopes.Remove(entity);
        await _db.SaveChangesAsync(ct);
        return Result.Ok<object>(new { });
    }

    private static FormRowFormulaScopeDto MapToDto(FormRowFormulaScope s) => new()
    {
        Id = s.Id,
        FormRowId = s.FormRowId,
        FormColumnId = s.FormColumnId,
        CreatedAt = s.CreatedAt,
        CreatedBy = s.CreatedBy
    };
}
