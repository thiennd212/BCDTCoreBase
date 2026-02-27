using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormSheetService : IFormSheetService
{
    private readonly AppDbContext _db;

    public FormSheetService(AppDbContext db) => _db = db;

    public async Task<Result<List<FormSheetDto>>> GetByFormIdAsync(int formDefinitionId, CancellationToken cancellationToken = default)
    {
        var exists = await _db.FormDefinitions.AnyAsync(f => f.Id == formDefinitionId && !f.IsDeleted, cancellationToken);
        if (!exists)
            return Result.Fail<List<FormSheetDto>>("NOT_FOUND", "Biểu mẫu không tồn tại.");

        var list = await _db.FormSheets
            .AsNoTracking()
            .Where(s => s.FormDefinitionId == formDefinitionId)
            .OrderBy(s => s.DisplayOrder).ThenBy(s => s.SheetIndex)
            .Select(s => MapToDto(s))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<FormSheetDto?>> GetByIdAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormSheets
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (entity == null)
            return Result.Ok<FormSheetDto?>(null);
        return Result.Ok<FormSheetDto?>(MapToDto(entity));
    }

    public async Task<Result<FormSheetDto>> CreateAsync(int formDefinitionId, CreateFormSheetRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var formExists = await _db.FormDefinitions.AnyAsync(f => f.Id == formDefinitionId && !f.IsDeleted, cancellationToken);
        if (!formExists)
            return Result.Fail<FormSheetDto>("NOT_FOUND", "Biểu mẫu không tồn tại.");
        var conflict = await _db.FormSheets.AnyAsync(s => s.FormDefinitionId == formDefinitionId && s.SheetIndex == request.SheetIndex, cancellationToken);
        if (conflict)
            return Result.Fail<FormSheetDto>("CONFLICT", "SheetIndex đã tồn tại trong biểu mẫu này.");

        var entity = new FormSheet
        {
            FormDefinitionId = formDefinitionId,
            SheetIndex = (byte)Math.Clamp(request.SheetIndex, 0, 255),
            SheetName = request.SheetName,
            DisplayName = request.DisplayName,
            Description = request.Description,
            IsDataSheet = request.IsDataSheet,
            IsVisible = request.IsVisible,
            DisplayOrder = request.DisplayOrder,
            DataStartRow = request.DataStartRow,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormSheets.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormSheetDto>> UpdateAsync(int formDefinitionId, int sheetId, UpdateFormSheetRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (entity == null)
            return Result.Fail<FormSheetDto>("NOT_FOUND", "Sheet không tồn tại.");
        var conflict = await _db.FormSheets.AnyAsync(s => s.FormDefinitionId == formDefinitionId && s.SheetIndex == request.SheetIndex && s.Id != sheetId, cancellationToken);
        if (conflict)
            return Result.Fail<FormSheetDto>("CONFLICT", "SheetIndex đã tồn tại trong biểu mẫu này.");

        entity.SheetIndex = (byte)Math.Clamp(request.SheetIndex, 0, 255);
        entity.SheetName = request.SheetName;
        entity.DisplayName = request.DisplayName;
        entity.Description = request.Description;
        entity.IsDataSheet = request.IsDataSheet;
        entity.IsVisible = request.IsVisible;
        entity.DisplayOrder = request.DisplayOrder;
        entity.DataStartRow = request.DataStartRow;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Sheet không tồn tại.");
        var hasColumns = await _db.FormColumns.AnyAsync(c => c.FormSheetId == sheetId, cancellationToken);
        if (hasColumns)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa sheet khi còn cột. Xóa hết cột trước.");

        _db.FormSheets.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormSheetDto MapToDto(FormSheet s) => new()
    {
        Id = s.Id,
        FormDefinitionId = s.FormDefinitionId,
        SheetIndex = s.SheetIndex,
        SheetName = s.SheetName,
        DisplayName = s.DisplayName,
        Description = s.Description,
        IsDataSheet = s.IsDataSheet,
        IsVisible = s.IsVisible,
        DisplayOrder = s.DisplayOrder,
        DataStartRow = s.DataStartRow,
        CreatedAt = s.CreatedAt,
        CreatedBy = s.CreatedBy
    };
}
