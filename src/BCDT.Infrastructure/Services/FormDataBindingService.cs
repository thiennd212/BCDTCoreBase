using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormDataBindingService : IFormDataBindingService
{
    private readonly AppDbContext _db;

    public FormDataBindingService(AppDbContext db) => _db = db;

    private static readonly HashSet<string> ValidBindingTypes = new(StringComparer.OrdinalIgnoreCase)
        { "Static", "Database", "API", "Formula", "Reference", "Organization", "System" };

    public async Task<Result<FormDataBindingDto?>> GetByColumnIdAsync(int formColumnId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDataBindings
            .AsNoTracking()
            .FirstOrDefaultAsync(b => b.FormColumnId == formColumnId, cancellationToken);
        if (entity == null)
            return Result.Ok<FormDataBindingDto?>(null);
        return Result.Ok<FormDataBindingDto?>(MapToDto(entity));
    }

    public async Task<Result<FormDataBindingDto>> CreateAsync(int formColumnId, CreateFormDataBindingRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var columnExists = await _db.FormColumns.AnyAsync(c => c.Id == formColumnId, cancellationToken);
        if (!columnExists)
            return Result.Fail<FormDataBindingDto>("NOT_FOUND", "Cột không tồn tại.");
        if (!ValidBindingTypes.Contains(request.BindingType))
            return Result.Fail<FormDataBindingDto>("VALIDATION_FAILED", "BindingType phải thuộc: Static, Database, API, Formula, Reference, Organization, System.");
        var exists = await _db.FormDataBindings.AnyAsync(b => b.FormColumnId == formColumnId, cancellationToken);
        if (exists)
            return Result.Fail<FormDataBindingDto>("CONFLICT", "Cột này đã có cấu hình data binding (mỗi cột chỉ một binding).");

        var entity = new FormDataBinding
        {
            FormColumnId = formColumnId,
            BindingType = request.BindingType,
            SourceTable = request.SourceTable,
            SourceColumn = request.SourceColumn,
            SourceCondition = request.SourceCondition,
            ApiEndpoint = request.ApiEndpoint,
            ApiMethod = request.ApiMethod,
            ApiResponsePath = request.ApiResponsePath,
            Formula = request.Formula,
            ReferenceEntityTypeId = request.ReferenceEntityTypeId,
            ReferenceDisplayColumn = request.ReferenceDisplayColumn,
            DefaultValue = request.DefaultValue,
            TransformExpression = request.TransformExpression,
            CacheMinutes = request.CacheMinutes,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormDataBindings.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormDataBindingDto>> UpdateAsync(int formColumnId, UpdateFormDataBindingRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDataBindings.FirstOrDefaultAsync(b => b.FormColumnId == formColumnId, cancellationToken);
        if (entity == null)
            return Result.Fail<FormDataBindingDto>("NOT_FOUND", "Data binding không tồn tại.");
        if (!ValidBindingTypes.Contains(request.BindingType))
            return Result.Fail<FormDataBindingDto>("VALIDATION_FAILED", "BindingType phải thuộc: Static, Database, API, Formula, Reference, Organization, System.");

        entity.BindingType = request.BindingType;
        entity.SourceTable = request.SourceTable;
        entity.SourceColumn = request.SourceColumn;
        entity.SourceCondition = request.SourceCondition;
        entity.ApiEndpoint = request.ApiEndpoint;
        entity.ApiMethod = request.ApiMethod;
        entity.ApiResponsePath = request.ApiResponsePath;
        entity.Formula = request.Formula;
        entity.ReferenceEntityTypeId = request.ReferenceEntityTypeId;
        entity.ReferenceDisplayColumn = request.ReferenceDisplayColumn;
        entity.DefaultValue = request.DefaultValue;
        entity.TransformExpression = request.TransformExpression;
        entity.CacheMinutes = request.CacheMinutes;
        entity.IsActive = request.IsActive;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formColumnId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDataBindings.FirstOrDefaultAsync(b => b.FormColumnId == formColumnId, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Data binding không tồn tại.");
        _db.FormDataBindings.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormDataBindingDto MapToDto(FormDataBinding b) => new()
    {
        Id = b.Id,
        FormColumnId = b.FormColumnId,
        BindingType = b.BindingType,
        SourceTable = b.SourceTable,
        SourceColumn = b.SourceColumn,
        SourceCondition = b.SourceCondition,
        ApiEndpoint = b.ApiEndpoint,
        ApiMethod = b.ApiMethod,
        ApiResponsePath = b.ApiResponsePath,
        Formula = b.Formula,
        ReferenceEntityTypeId = b.ReferenceEntityTypeId,
        ReferenceDisplayColumn = b.ReferenceDisplayColumn,
        DefaultValue = b.DefaultValue,
        TransformExpression = b.TransformExpression,
        CacheMinutes = b.CacheMinutes,
        IsActive = b.IsActive,
        CreatedAt = b.CreatedAt,
        CreatedBy = b.CreatedBy
    };
}
