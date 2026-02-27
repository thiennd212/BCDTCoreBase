using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormPlaceholderOccurrenceService : IFormPlaceholderOccurrenceService
{
    private readonly AppDbContext _db;

    public FormPlaceholderOccurrenceService(AppDbContext db) => _db = db;

    public async Task<Result<List<FormPlaceholderOccurrenceDto>>> GetBySheetIdAsync(int formId, int sheetId, CancellationToken cancellationToken = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<List<FormPlaceholderOccurrenceDto>>("NOT_FOUND", "Sheet không tồn tại hoặc không thuộc biểu mẫu.");
        var list = await _db.FormPlaceholderOccurrences
            .AsNoTracking()
            .Where(o => o.FormSheetId == sheetId)
            .OrderBy(o => o.DisplayOrder).ThenBy(o => o.Id)
            .Select(o => MapToDto(o))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<FormPlaceholderOccurrenceDto?>> GetByIdAsync(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Ok<FormPlaceholderOccurrenceDto?>(null);
        var entity = await _db.FormPlaceholderOccurrences
            .AsNoTracking()
            .FirstOrDefaultAsync(o => o.Id == occurrenceId && o.FormSheetId == sheetId, cancellationToken);
        return Result.Ok(entity != null ? MapToDto(entity) : null);
    }

    public async Task<Result<FormPlaceholderOccurrenceDto>> CreateAsync(int formId, int sheetId, CreateFormPlaceholderOccurrenceRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (sheet == null)
            return Result.Fail<FormPlaceholderOccurrenceDto>("NOT_FOUND", "Sheet không tồn tại hoặc không thuộc biểu mẫu.");
        var regionExists = await _db.FormDynamicRegions.AnyAsync(r => r.Id == request.FormDynamicRegionId && r.FormSheetId == sheetId, cancellationToken);
        if (!regionExists)
            return Result.Fail<FormPlaceholderOccurrenceDto>("NOT_FOUND", "Vùng chỉ tiêu động không tồn tại hoặc không thuộc sheet.");
        var entity = new FormPlaceholderOccurrence
        {
            FormSheetId = sheetId,
            FormDynamicRegionId = request.FormDynamicRegionId,
            ExcelRowStart = request.ExcelRowStart,
            FilterDefinitionId = request.FilterDefinitionId,
            DataSourceId = request.DataSourceId,
            DisplayOrder = request.DisplayOrder,
            MaxRows = request.MaxRows,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormPlaceholderOccurrences.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormPlaceholderOccurrenceDto>> UpdateAsync(int formId, int sheetId, int occurrenceId, UpdateFormPlaceholderOccurrenceRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormPlaceholderOccurrences.FirstOrDefaultAsync(o => o.Id == occurrenceId && o.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Fail<FormPlaceholderOccurrenceDto>("NOT_FOUND", "Vị trí placeholder không tồn tại.");
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<FormPlaceholderOccurrenceDto>("NOT_FOUND", "Sheet không thuộc biểu mẫu.");
        var regionExists = await _db.FormDynamicRegions.AnyAsync(r => r.Id == request.FormDynamicRegionId && r.FormSheetId == sheetId, cancellationToken);
        if (!regionExists)
            return Result.Fail<FormPlaceholderOccurrenceDto>("NOT_FOUND", "Vùng chỉ tiêu động không thuộc sheet.");
        entity.FormDynamicRegionId = request.FormDynamicRegionId;
        entity.ExcelRowStart = request.ExcelRowStart;
        entity.FilterDefinitionId = request.FilterDefinitionId;
        entity.DataSourceId = request.DataSourceId;
        entity.DisplayOrder = request.DisplayOrder;
        entity.MaxRows = request.MaxRows;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = entity.CreatedBy; // could pass updatedBy from controller
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormPlaceholderOccurrences.FirstOrDefaultAsync(o => o.Id == occurrenceId && o.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Vị trí placeholder không tồn tại.");
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<object>("NOT_FOUND", "Sheet không thuộc biểu mẫu.");
        _db.FormPlaceholderOccurrences.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormPlaceholderOccurrenceDto MapToDto(FormPlaceholderOccurrence o) => new()
    {
        Id = o.Id,
        FormSheetId = o.FormSheetId,
        FormDynamicRegionId = o.FormDynamicRegionId,
        ExcelRowStart = o.ExcelRowStart,
        FilterDefinitionId = o.FilterDefinitionId,
        DataSourceId = o.DataSourceId,
        DisplayOrder = o.DisplayOrder,
        MaxRows = o.MaxRows,
        CreatedAt = o.CreatedAt,
        CreatedBy = o.CreatedBy
    };
}
