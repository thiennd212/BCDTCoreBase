using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class IndicatorService : IIndicatorService
{
    private readonly AppDbContext _db;

    public IndicatorService(AppDbContext db) => _db = db;

    public async Task<Result<List<IndicatorDto>>> GetByCatalogAsync(int catalogId, bool tree = false, CancellationToken cancellationToken = default)
    {
        var catalogExists = await _db.IndicatorCatalogs.AnyAsync(c => c.Id == catalogId, cancellationToken);
        if (!catalogExists)
            return Result.Fail<List<IndicatorDto>>("NOT_FOUND", "Danh mục chỉ tiêu không tồn tại.");

        var all = await _db.Indicators
            .AsNoTracking()
            .Where(i => i.IndicatorCatalogId == catalogId)
            .OrderBy(i => i.DisplayOrder)
            .ThenBy(i => i.Code)
            .ToListAsync(cancellationToken);

        if (!tree)
            return Result.Ok(all.Select(MapToDto).ToList());

        // Build tree
        var dtoMap = all.Select(MapToDto).ToDictionary(d => d.Id);
        var roots = new List<IndicatorDto>();
        foreach (var dto in dtoMap.Values)
        {
            if (dto.ParentId.HasValue && dtoMap.TryGetValue(dto.ParentId.Value, out var parent))
            {
                parent.Children ??= new List<IndicatorDto>();
                parent.Children.Add(dto);
            }
            else
            {
                roots.Add(dto);
            }
        }
        return Result.Ok(roots);
    }

    public async Task<Result<IndicatorDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Indicators.AsNoTracking().FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        return Result.Ok(entity != null ? MapToDto(entity) : null);
    }

    public async Task<Result<IndicatorDto?>> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(code))
            return Result.Ok<IndicatorDto?>(null);
        var entity = await _db.Indicators
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Code == code.Trim(), cancellationToken);
        return Result.Ok(entity != null ? MapToDto(entity) : null);
    }

    public async Task<Result<IndicatorDto>> CreateAsync(CreateIndicatorRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var catalogExists = await _db.IndicatorCatalogs.AnyAsync(c => c.Id == request.IndicatorCatalogId, cancellationToken);
        if (!catalogExists)
            return Result.Fail<IndicatorDto>("NOT_FOUND", "Danh mục chỉ tiêu không tồn tại.");

        // Check code unique within catalog
        var codeExists = await _db.Indicators.AnyAsync(
            i => i.IndicatorCatalogId == request.IndicatorCatalogId && i.Code == request.Code.Trim(),
            cancellationToken);
        if (codeExists)
            return Result.Fail<IndicatorDto>("CONFLICT", "Mã chỉ tiêu đã tồn tại trong danh mục này.");

        if (request.ParentId.HasValue)
        {
            var parentExists = await _db.Indicators.AnyAsync(
                i => i.Id == request.ParentId.Value && i.IndicatorCatalogId == request.IndicatorCatalogId,
                cancellationToken);
            if (!parentExists)
                return Result.Fail<IndicatorDto>("VALIDATION_FAILED", "Chỉ tiêu cha không tồn tại hoặc không thuộc cùng danh mục.");
        }

        var entity = new Indicator
        {
            IndicatorCatalogId = request.IndicatorCatalogId,
            ParentId = request.ParentId,
            Code = request.Code.Trim(),
            Name = request.Name.Trim(),
            Description = request.Description?.Trim(),
            DataType = request.DataType,
            Unit = request.Unit?.Trim(),
            FormulaTemplate = request.FormulaTemplate?.Trim(),
            ValidationRule = request.ValidationRule?.Trim(),
            DefaultValue = request.DefaultValue?.Trim(),
            DisplayOrder = request.DisplayOrder,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.Indicators.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<IndicatorDto>> UpdateAsync(int id, UpdateIndicatorRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Indicators.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<IndicatorDto>("NOT_FOUND", "Chỉ tiêu không tồn tại.");

        if (request.ParentId.HasValue)
        {
            if (request.ParentId.Value == id)
                return Result.Fail<IndicatorDto>("VALIDATION_FAILED", "Chỉ tiêu không thể là cha của chính nó.");

            var parentExists = await _db.Indicators.AnyAsync(
                i => i.Id == request.ParentId.Value && i.IndicatorCatalogId == entity.IndicatorCatalogId,
                cancellationToken);
            if (!parentExists)
                return Result.Fail<IndicatorDto>("VALIDATION_FAILED", "Chỉ tiêu cha không tồn tại hoặc không thuộc cùng danh mục.");
        }

        entity.ParentId = request.ParentId;
        entity.Name = request.Name.Trim();
        entity.Description = request.Description?.Trim();
        entity.DataType = request.DataType;
        entity.Unit = request.Unit?.Trim();
        entity.FormulaTemplate = request.FormulaTemplate?.Trim();
        entity.ValidationRule = request.ValidationRule?.Trim();
        entity.DefaultValue = request.DefaultValue?.Trim();
        entity.DisplayOrder = request.DisplayOrder;
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.Indicators.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Chỉ tiêu không tồn tại.");

        var hasChildren = await _db.Indicators.AnyAsync(i => i.ParentId == id, cancellationToken);
        if (hasChildren)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa chỉ tiêu đang có chỉ tiêu con.");

        _db.Indicators.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static IndicatorDto MapToDto(Indicator x) => new()
    {
        Id = x.Id,
        IndicatorCatalogId = x.IndicatorCatalogId,
        ParentId = x.ParentId,
        Code = x.Code,
        Name = x.Name,
        Description = x.Description,
        DataType = x.DataType,
        Unit = x.Unit,
        FormulaTemplate = x.FormulaTemplate,
        ValidationRule = x.ValidationRule,
        DefaultValue = x.DefaultValue,
        DisplayOrder = x.DisplayOrder,
        IsActive = x.IsActive,
        CreatedAt = x.CreatedAt,
        CreatedBy = x.CreatedBy
    };
}
