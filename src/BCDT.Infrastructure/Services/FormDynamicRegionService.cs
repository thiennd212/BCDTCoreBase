using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormDynamicRegionService : IFormDynamicRegionService
{
    private readonly AppDbContext _db;

    public FormDynamicRegionService(AppDbContext db) => _db = db;

    public async Task<Result<List<FormDynamicRegionDto>>> GetBySheetIdAsync(int formId, int sheetId, CancellationToken cancellationToken = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<List<FormDynamicRegionDto>>("NOT_FOUND", "Sheet không tồn tại hoặc không thuộc biểu mẫu.");

        var list = await _db.FormDynamicRegions
            .AsNoTracking()
            .Where(r => r.FormSheetId == sheetId)
            .OrderBy(r => r.DisplayOrder).ThenBy(r => r.Id)
            .Select(r => MapToDto(r))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<FormDynamicRegionDto?>> GetByIdAsync(int formId, int sheetId, int regionId, CancellationToken cancellationToken = default)
    {
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Ok<FormDynamicRegionDto?>(null);
        var entity = await _db.FormDynamicRegions
            .AsNoTracking()
            .FirstOrDefaultAsync(r => r.Id == regionId && r.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Ok<FormDynamicRegionDto?>(null);
        return Result.Ok<FormDynamicRegionDto?>(MapToDto(entity));
    }

    public async Task<Result<FormDynamicRegionDto>> CreateAsync(int formId, int sheetId, CreateFormDynamicRegionRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (sheet == null)
            return Result.Fail<FormDynamicRegionDto>("NOT_FOUND", "Sheet không tồn tại hoặc không thuộc biểu mẫu.");

        var entity = new FormDynamicRegion
        {
            FormSheetId = sheetId,
            ExcelRowStart = request.ExcelRowStart,
            ExcelRowEnd = request.ExcelRowEnd,
            ExcelColName = request.ExcelColName.Trim(),
            ExcelColValue = request.ExcelColValue.Trim(),
            MaxRows = Math.Clamp(request.MaxRows, 1, 500),
            IndicatorExpandDepth = Math.Clamp(request.IndicatorExpandDepth, 0, 10),
            IndicatorCatalogId = request.IndicatorCatalogId,
            DisplayOrder = request.DisplayOrder,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormDynamicRegions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormDynamicRegionDto>> UpdateAsync(int formId, int sheetId, int regionId, UpdateFormDynamicRegionRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDynamicRegions.FirstOrDefaultAsync(r => r.Id == regionId && r.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Fail<FormDynamicRegionDto>("NOT_FOUND", "Vùng chỉ tiêu động không tồn tại.");
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<FormDynamicRegionDto>("NOT_FOUND", "Sheet không thuộc biểu mẫu.");

        entity.ExcelRowStart = request.ExcelRowStart;
        entity.ExcelRowEnd = request.ExcelRowEnd;
        entity.ExcelColName = request.ExcelColName.Trim();
        entity.ExcelColValue = request.ExcelColValue.Trim();
        entity.MaxRows = Math.Clamp(request.MaxRows, 1, 500);
        entity.IndicatorExpandDepth = Math.Clamp(request.IndicatorExpandDepth, 0, 10);
        entity.IndicatorCatalogId = request.IndicatorCatalogId;
        entity.DisplayOrder = request.DisplayOrder;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formId, int sheetId, int regionId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDynamicRegions.FirstOrDefaultAsync(r => r.Id == regionId && r.FormSheetId == sheetId, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Vùng chỉ tiêu động không tồn tại.");
        var sheetExists = await _db.FormSheets.AnyAsync(s => s.Id == sheetId && s.FormDefinitionId == formId, cancellationToken);
        if (!sheetExists)
            return Result.Fail<object>("NOT_FOUND", "Sheet không thuộc biểu mẫu.");

        var hasData = await _db.ReportDynamicIndicators.AnyAsync(d => d.FormDynamicRegionId == regionId, cancellationToken);
        if (hasData)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa vùng khi đã có dữ liệu chỉ tiêu động. Xóa dữ liệu trước.");

        _db.FormDynamicRegions.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormDynamicRegionDto MapToDto(FormDynamicRegion r) => new()
    {
        Id = r.Id,
        FormSheetId = r.FormSheetId,
        ExcelRowStart = r.ExcelRowStart,
        ExcelRowEnd = r.ExcelRowEnd,
        ExcelColName = r.ExcelColName,
        ExcelColValue = r.ExcelColValue,
        MaxRows = r.MaxRows,
        IndicatorExpandDepth = r.IndicatorExpandDepth,
        IndicatorCatalogId = r.IndicatorCatalogId,
        DisplayOrder = r.DisplayOrder,
        CreatedAt = r.CreatedAt,
        CreatedBy = r.CreatedBy
    };
}
