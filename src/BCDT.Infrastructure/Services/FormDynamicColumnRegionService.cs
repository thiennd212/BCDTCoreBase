using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormDynamicColumnRegionService : IFormDynamicColumnRegionService
{
    private readonly AppDbContext _db;

    public FormDynamicColumnRegionService(AppDbContext db) => _db = db;

    public async Task<Result<List<FormDynamicColumnRegionDto>>> GetBySheetIdAsync(int formId, int sheetId, CancellationToken cancellationToken = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<List<FormDynamicColumnRegionDto>>("NOT_FOUND", "Sheet không tồn tại hoặc không thuộc biểu mẫu.");
        var list = await _db.FormDynamicColumnRegions
            .AsNoTracking()
            .Where(r => r.FormSheetId == sheetId)
            .OrderBy(r => r.DisplayOrder).ThenBy(r => r.Id)
            .Select(r => MapToDto(r))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<FormDynamicColumnRegionDto?>> GetByIdAsync(int formId, int sheetId, int regionId, CancellationToken cancellationToken = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Ok<FormDynamicColumnRegionDto?>(null);
        var entity = await _db.FormDynamicColumnRegions
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == regionId && r.FormSheetId == sheetId, cancellationToken);
        return Result.Ok(entity != null ? MapToDto(entity) : null);
    }

    public async Task<Result<FormDynamicColumnRegionDto>> CreateAsync(int formId, int sheetId, CreateFormDynamicColumnRegionRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (sheet == null)
            return Result.Fail<FormDynamicColumnRegionDto>("NOT_FOUND", "Sheet không tồn tại hoặc không thuộc biểu mẫu.");
        var entity = new FormDynamicColumnRegion
        {
            FormSheetId = sheetId,
            Code = request.Code.Trim(),
            Name = request.Name.Trim(),
            ColumnSourceType = request.ColumnSourceType.Trim(),
            ColumnSourceRef = request.ColumnSourceRef?.Trim(),
            LabelColumn = request.LabelColumn?.Trim(),
            DisplayOrder = request.DisplayOrder,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormDynamicColumnRegions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormDynamicColumnRegionDto>> UpdateAsync(int formId, int sheetId, int regionId, UpdateFormDynamicColumnRegionRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDynamicColumnRegions.FirstOrDefaultAsync(r => r.Id == regionId && r.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Fail<FormDynamicColumnRegionDto>("NOT_FOUND", "Vùng cột động không tồn tại.");
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<FormDynamicColumnRegionDto>("NOT_FOUND", "Sheet không thuộc biểu mẫu.");
        entity.Code = request.Code.Trim();
        entity.Name = request.Name.Trim();
        entity.ColumnSourceType = request.ColumnSourceType.Trim();
        entity.ColumnSourceRef = request.ColumnSourceRef?.Trim();
        entity.LabelColumn = request.LabelColumn?.Trim();
        entity.DisplayOrder = request.DisplayOrder;
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = entity.CreatedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formId, int sheetId, int regionId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDynamicColumnRegions.FirstOrDefaultAsync(r => r.Id == regionId && r.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Vùng cột động không tồn tại.");
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<object>("NOT_FOUND", "Sheet không thuộc biểu mẫu.");
        _db.FormDynamicColumnRegions.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormDynamicColumnRegionDto MapToDto(FormDynamicColumnRegion r) => new()
    {
        Id = r.Id,
        FormSheetId = r.FormSheetId,
        Code = r.Code,
        Name = r.Name,
        ColumnSourceType = r.ColumnSourceType,
        ColumnSourceRef = r.ColumnSourceRef,
        LabelColumn = r.LabelColumn,
        DisplayOrder = r.DisplayOrder,
        IsActive = r.IsActive,
        CreatedAt = r.CreatedAt,
        CreatedBy = r.CreatedBy
    };
}
