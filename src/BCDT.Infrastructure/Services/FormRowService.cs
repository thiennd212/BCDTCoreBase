using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormRowService : IFormRowService
{
    private readonly AppDbContext _db;

    public FormRowService(AppDbContext db) => _db = db;

    private static readonly HashSet<string> ValidRowTypes = new(StringComparer.OrdinalIgnoreCase)
        { "Header", "Data", "Total", "Static" };

    public async Task<Result<List<FormRowDto>>> GetBySheetIdAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (sheet == null)
            return Result.Fail<List<FormRowDto>>("NOT_FOUND", "Sheet không tồn tại.");

        var list = await _db.FormRows
            .AsNoTracking()
            .Where(r => r.FormSheetId == sheetId)
            .OrderBy(r => r.DisplayOrder).ThenBy(r => r.Id)
            .Select(r => MapToDto(r))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<List<FormRowTreeDto>>> GetBySheetIdAsTreeAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (sheet == null)
            return Result.Fail<List<FormRowTreeDto>>("NOT_FOUND", "Sheet không tồn tại.");

        var list = await _db.FormRows
            .AsNoTracking()
            .Where(r => r.FormSheetId == sheetId)
            .OrderBy(r => r.DisplayOrder).ThenBy(r => r.Id)
            .ToListAsync(cancellationToken);
        var dtos = list.Select(MapToDto).ToList();
        var tree = BuildTree(dtos, null);
        return Result.Ok(tree);
    }

    public async Task<Result<FormRowDto?>> GetByIdAsync(int formDefinitionId, int sheetId, int rowId, CancellationToken cancellationToken = default)
    {
        var row = await _db.FormRows
            .AsNoTracking()
            .Where(r => r.Id == rowId && r.FormSheetId == sheetId)
            .Join(_db.FormSheets.Where(s => s.FormDefinitionId == formDefinitionId), r => r.FormSheetId, s => s.Id, (r, _) => r)
            .FirstOrDefaultAsync(cancellationToken);
        if (row == null)
            return Result.Ok<FormRowDto?>(null);
        return Result.Ok<FormRowDto?>(MapToDto(row));
    }

    public async Task<Result<FormRowDto>> CreateAsync(int formDefinitionId, int sheetId, CreateFormRowRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (sheet == null)
            return Result.Fail<FormRowDto>("NOT_FOUND", "Sheet không tồn tại.");
        if (!ValidRowTypes.Contains(request.RowType))
            return Result.Fail<FormRowDto>("VALIDATION_FAILED", "RowType phải thuộc: Header, Data, Total, Static.");
        if (request.ParentId.HasValue)
        {
            var parentExists = await _db.FormRows.AnyAsync(r => r.Id == request.ParentId.Value && r.FormSheetId == sheetId, cancellationToken);
            if (!parentExists)
                return Result.Fail<FormRowDto>("VALIDATION_FAILED", "ParentId không thuộc sheet này.");
        }
        if (request.FormDynamicRegionId.HasValue)
        {
            var regionExists = await _db.FormDynamicRegions.AnyAsync(r => r.Id == request.FormDynamicRegionId.Value && r.FormSheetId == sheetId, cancellationToken);
            if (!regionExists)
                return Result.Fail<FormRowDto>("VALIDATION_FAILED", "FormDynamicRegionId không thuộc sheet này.");
        }

        var entity = new FormRow
        {
            FormSheetId = sheetId,
            RowCode = request.RowCode,
            RowName = request.RowName,
            ExcelRowStart = request.ExcelRowStart,
            ExcelRowEnd = request.ExcelRowEnd,
            RowType = request.RowType,
            IsRepeating = request.IsRepeating,
            ReferenceEntityTypeId = request.ReferenceEntityTypeId,
            ParentRowId = request.ParentId,
            FormDynamicRegionId = request.FormDynamicRegionId,
            DisplayOrder = request.DisplayOrder,
            Height = request.Height,
            IsEditable = request.IsEditable,
            IsRequired = request.IsRequired,
            Formula = request.Formula,
            IndicatorId = request.IndicatorId,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormRows.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormRowDto>> UpdateAsync(int formDefinitionId, int sheetId, int rowId, UpdateFormRowRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormRows
            .Where(r => r.Id == rowId && r.FormSheetId == sheetId)
            .Join(_db.FormSheets.Where(s => s.FormDefinitionId == formDefinitionId), r => r.FormSheetId, s => s.Id, (r, _) => r)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Fail<FormRowDto>("NOT_FOUND", "Hàng không tồn tại.");
        if (!ValidRowTypes.Contains(request.RowType))
            return Result.Fail<FormRowDto>("VALIDATION_FAILED", "RowType phải thuộc: Header, Data, Total, Static.");
        if (request.ParentId.HasValue && request.ParentId.Value != entity.ParentRowId)
        {
            if (request.ParentId.Value == rowId)
                return Result.Fail<FormRowDto>("VALIDATION_FAILED", "ParentId không được trỏ về chính hàng này.");
            var parentExists = await _db.FormRows.AnyAsync(r => r.Id == request.ParentId.Value && r.FormSheetId == sheetId, cancellationToken);
            if (!parentExists)
                return Result.Fail<FormRowDto>("VALIDATION_FAILED", "ParentId không thuộc sheet này.");
        }
        if (request.FormDynamicRegionId.HasValue)
        {
            var regionExists = await _db.FormDynamicRegions.AnyAsync(r => r.Id == request.FormDynamicRegionId.Value && r.FormSheetId == sheetId, cancellationToken);
            if (!regionExists)
                return Result.Fail<FormRowDto>("VALIDATION_FAILED", "FormDynamicRegionId không thuộc sheet này.");
        }

        entity.RowCode = request.RowCode;
        entity.RowName = request.RowName;
        entity.ExcelRowStart = request.ExcelRowStart;
        entity.ExcelRowEnd = request.ExcelRowEnd;
        entity.RowType = request.RowType;
        entity.IsRepeating = request.IsRepeating;
        entity.ReferenceEntityTypeId = request.ReferenceEntityTypeId;
        entity.ParentRowId = request.ParentId;
        entity.FormDynamicRegionId = request.FormDynamicRegionId;
        entity.DisplayOrder = request.DisplayOrder;
        entity.Height = request.Height;
        entity.IsEditable = request.IsEditable;
        entity.IsRequired = request.IsRequired;
        entity.Formula = request.Formula;
        entity.IndicatorId = request.IndicatorId;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, int rowId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormRows
            .Where(r => r.Id == rowId && r.FormSheetId == sheetId)
            .Join(_db.FormSheets.Where(s => s.FormDefinitionId == formDefinitionId), r => r.FormSheetId, s => s.Id, (r, _) => r)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Hàng không tồn tại.");
        var hasChildren = await _db.FormRows.AnyAsync(r => r.ParentRowId == rowId, cancellationToken);
        if (hasChildren)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa hàng còn hàng con. Xóa hàng con trước.");

        _db.FormRows.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormRowDto MapToDto(FormRow r) => new()
    {
        Id = r.Id,
        FormSheetId = r.FormSheetId,
        RowCode = r.RowCode,
        RowName = r.RowName,
        ExcelRowStart = r.ExcelRowStart,
        ExcelRowEnd = r.ExcelRowEnd,
        RowType = r.RowType,
        IsRepeating = r.IsRepeating,
        ReferenceEntityTypeId = r.ReferenceEntityTypeId,
        ParentId = r.ParentRowId,
        FormDynamicRegionId = r.FormDynamicRegionId,
        DisplayOrder = r.DisplayOrder,
        Height = r.Height,
        IsEditable = r.IsEditable,
        IsRequired = r.IsRequired,
        Formula = r.Formula,
        IndicatorId = r.IndicatorId,
        CreatedAt = r.CreatedAt,
        CreatedBy = r.CreatedBy
    };

    private static List<FormRowTreeDto> BuildTree(List<FormRowDto> flat, int? parentId)
    {
        return flat
            .Where(r => r.ParentId == parentId)
            .Select(r => new FormRowTreeDto
            {
                Id = r.Id,
                FormSheetId = r.FormSheetId,
                RowCode = r.RowCode,
                RowName = r.RowName,
                ExcelRowStart = r.ExcelRowStart,
                ExcelRowEnd = r.ExcelRowEnd,
                RowType = r.RowType,
                IsRepeating = r.IsRepeating,
                ReferenceEntityTypeId = r.ReferenceEntityTypeId,
                ParentId = r.ParentId,
                FormDynamicRegionId = r.FormDynamicRegionId,
                DisplayOrder = r.DisplayOrder,
                Height = r.Height,
                IsEditable = r.IsEditable,
                IsRequired = r.IsRequired,
                Formula = r.Formula,
                IndicatorId = r.IndicatorId,
                CreatedAt = r.CreatedAt,
                CreatedBy = r.CreatedBy,
                Children = BuildTree(flat, r.Id)
            })
            .ToList();
    }
}
