using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormColumnMappingService : IFormColumnMappingService
{
    private readonly AppDbContext _db;

    public FormColumnMappingService(AppDbContext db) => _db = db;

    public async Task<Result<FormColumnMappingDto?>> GetByColumnIdAsync(int formColumnId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormColumnMappings
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.FormColumnId == formColumnId, cancellationToken);
        if (entity == null)
            return Result.Ok<FormColumnMappingDto?>(null);
        return Result.Ok<FormColumnMappingDto?>(MapToDto(entity));
    }

    public async Task<Result<FormColumnMappingDto>> CreateAsync(int formColumnId, CreateFormColumnMappingRequest request, CancellationToken cancellationToken = default)
    {
        var columnExists = await _db.FormColumns.AnyAsync(c => c.Id == formColumnId, cancellationToken);
        if (!columnExists)
            return Result.Fail<FormColumnMappingDto>("NOT_FOUND", "Cột không tồn tại.");
        var exists = await _db.FormColumnMappings.AnyAsync(m => m.FormColumnId == formColumnId, cancellationToken);
        if (exists)
            return Result.Fail<FormColumnMappingDto>("CONFLICT", "Cột này đã có column mapping (mỗi cột chỉ một mapping).");

        var entity = new FormColumnMapping
        {
            FormColumnId = formColumnId,
            TargetColumnName = request.TargetColumnName,
            TargetColumnIndex = (byte)Math.Clamp(request.TargetColumnIndex, 0, 255),
            AggregateFunction = request.AggregateFunction,
            CreatedAt = DateTime.UtcNow
        };
        _db.FormColumnMappings.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormColumnMappingDto>> UpdateAsync(int formColumnId, UpdateFormColumnMappingRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormColumnMappings.FirstOrDefaultAsync(m => m.FormColumnId == formColumnId, cancellationToken);
        if (entity == null)
            return Result.Fail<FormColumnMappingDto>("NOT_FOUND", "Column mapping không tồn tại.");

        entity.TargetColumnName = request.TargetColumnName;
        entity.TargetColumnIndex = (byte)Math.Clamp(request.TargetColumnIndex, 0, 255);
        entity.AggregateFunction = request.AggregateFunction;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formColumnId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormColumnMappings.FirstOrDefaultAsync(m => m.FormColumnId == formColumnId, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Column mapping không tồn tại.");
        _db.FormColumnMappings.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormColumnMappingDto MapToDto(FormColumnMapping m) => new()
    {
        Id = m.Id,
        FormColumnId = m.FormColumnId,
        TargetColumnName = m.TargetColumnName,
        TargetColumnIndex = m.TargetColumnIndex,
        AggregateFunction = m.AggregateFunction,
        CreatedAt = m.CreatedAt
    };
}
