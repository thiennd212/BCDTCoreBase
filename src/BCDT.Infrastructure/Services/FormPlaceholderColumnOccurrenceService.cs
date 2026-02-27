using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormPlaceholderColumnOccurrenceService : IFormPlaceholderColumnOccurrenceService
{
    private readonly AppDbContext _db;

    public FormPlaceholderColumnOccurrenceService(AppDbContext db) => _db = db;

    public async Task<Result<List<FormPlaceholderColumnOccurrenceDto>>> GetBySheetIdAsync(int formId, int sheetId, CancellationToken cancellationToken = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<List<FormPlaceholderColumnOccurrenceDto>>("NOT_FOUND", "Sheet không tồn tại hoặc không thuộc biểu mẫu.");
        var list = await _db.FormPlaceholderColumnOccurrences
            .AsNoTracking()
            .Where(o => o.FormSheetId == sheetId)
            .OrderBy(o => o.DisplayOrder).ThenBy(o => o.Id)
            .Select(o => MapToDto(o))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<FormPlaceholderColumnOccurrenceDto?>> GetByIdAsync(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Ok<FormPlaceholderColumnOccurrenceDto?>(null);
        var entity = await _db.FormPlaceholderColumnOccurrences
            .AsNoTracking()
            .FirstOrDefaultAsync(o => o.Id == occurrenceId && o.FormSheetId == sheetId, cancellationToken);
        return Result.Ok(entity != null ? MapToDto(entity) : null);
    }

    public async Task<Result<FormPlaceholderColumnOccurrenceDto>> CreateAsync(int formId, int sheetId, CreateFormPlaceholderColumnOccurrenceRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (sheet == null)
            return Result.Fail<FormPlaceholderColumnOccurrenceDto>("NOT_FOUND", "Sheet không tồn tại hoặc không thuộc biểu mẫu.");
        var regionExists = await _db.FormDynamicColumnRegions.AnyAsync(r => r.Id == request.FormDynamicColumnRegionId && r.FormSheetId == sheetId, cancellationToken);
        if (!regionExists)
            return Result.Fail<FormPlaceholderColumnOccurrenceDto>("NOT_FOUND", "Vùng cột động không tồn tại hoặc không thuộc sheet.");
        var entity = new FormPlaceholderColumnOccurrence
        {
            FormSheetId = sheetId,
            FormDynamicColumnRegionId = request.FormDynamicColumnRegionId,
            ExcelColStart = request.ExcelColStart,
            FilterDefinitionId = request.FilterDefinitionId,
            DisplayOrder = request.DisplayOrder,
            MaxColumns = request.MaxColumns,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormPlaceholderColumnOccurrences.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormPlaceholderColumnOccurrenceDto>> UpdateAsync(int formId, int sheetId, int occurrenceId, UpdateFormPlaceholderColumnOccurrenceRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormPlaceholderColumnOccurrences.FirstOrDefaultAsync(o => o.Id == occurrenceId && o.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Fail<FormPlaceholderColumnOccurrenceDto>("NOT_FOUND", "Vị trí placeholder cột không tồn tại.");
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<FormPlaceholderColumnOccurrenceDto>("NOT_FOUND", "Sheet không thuộc biểu mẫu.");
        var regionExists = await _db.FormDynamicColumnRegions.AnyAsync(r => r.Id == request.FormDynamicColumnRegionId && r.FormSheetId == sheetId, cancellationToken);
        if (!regionExists)
            return Result.Fail<FormPlaceholderColumnOccurrenceDto>("NOT_FOUND", "Vùng cột động không thuộc sheet.");
        entity.FormDynamicColumnRegionId = request.FormDynamicColumnRegionId;
        entity.ExcelColStart = request.ExcelColStart;
        entity.FilterDefinitionId = request.FilterDefinitionId;
        entity.DisplayOrder = request.DisplayOrder;
        entity.MaxColumns = request.MaxColumns;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = entity.CreatedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormPlaceholderColumnOccurrences.FirstOrDefaultAsync(o => o.Id == occurrenceId && o.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Vị trí placeholder cột không tồn tại.");
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<object>("NOT_FOUND", "Sheet không thuộc biểu mẫu.");
        _db.FormPlaceholderColumnOccurrences.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormPlaceholderColumnOccurrenceDto MapToDto(FormPlaceholderColumnOccurrence o) => new()
    {
        Id = o.Id,
        FormSheetId = o.FormSheetId,
        FormDynamicColumnRegionId = o.FormDynamicColumnRegionId,
        ExcelColStart = o.ExcelColStart,
        FilterDefinitionId = o.FilterDefinitionId,
        DisplayOrder = o.DisplayOrder,
        MaxColumns = o.MaxColumns,
        CreatedAt = o.CreatedAt,
        CreatedBy = o.CreatedBy
    };
}
