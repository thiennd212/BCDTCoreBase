using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services.Workflow;
using BCDT.Domain.Entities.Workflow;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Workflow;

public class WorkflowDefinitionService : IWorkflowDefinitionService
{
    private readonly AppDbContext _db;

    public WorkflowDefinitionService(AppDbContext db) => _db = db;

    public async Task<Result<WorkflowDefinitionDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.WorkflowDefinitions
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        return Result.Ok<WorkflowDefinitionDto?>(entity == null ? null : MapToDto(entity));
    }

    public async Task<Result<WorkflowDefinitionDto?>> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        var entity = await _db.WorkflowDefinitions
            .AsNoTracking()
            .FirstOrDefaultAsync(x => x.Code == code, cancellationToken);
        return Result.Ok<WorkflowDefinitionDto?>(entity == null ? null : MapToDto(entity));
    }

    public async Task<Result<List<WorkflowDefinitionDto>>> GetListAsync(bool includeInactive, CancellationToken cancellationToken = default)
    {
        var query = _db.WorkflowDefinitions.AsNoTracking();
        if (!includeInactive)
            query = query.Where(x => x.IsActive);
        var list = await query.OrderBy(x => x.Code).Select(x => MapToDto(x)).ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<WorkflowDefinitionDto>> CreateAsync(CreateWorkflowDefinitionRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        if (request.TotalSteps < 1 || request.TotalSteps > 5)
            return Result.Fail<WorkflowDefinitionDto>("VALIDATION_FAILED", "TotalSteps phải từ 1 đến 5.");
        var exists = await _db.WorkflowDefinitions.AnyAsync(x => x.Code == request.Code, cancellationToken);
        if (exists)
            return Result.Fail<WorkflowDefinitionDto>("CONFLICT", "Code workflow đã tồn tại.");

        var entity = new WorkflowDefinition
        {
            Code = request.Code,
            Name = request.Name,
            Description = request.Description,
            TotalSteps = request.TotalSteps,
            IsDefault = request.IsDefault,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.WorkflowDefinitions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<WorkflowDefinitionDto>> UpdateAsync(int id, UpdateWorkflowDefinitionRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        if (request.TotalSteps < 1 || request.TotalSteps > 5)
            return Result.Fail<WorkflowDefinitionDto>("VALIDATION_FAILED", "TotalSteps phải từ 1 đến 5.");
        var entity = await _db.WorkflowDefinitions.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<WorkflowDefinitionDto>("NOT_FOUND", "WorkflowDefinition không tồn tại.");
        var duplicateCode = await _db.WorkflowDefinitions.AnyAsync(x => x.Code == request.Code && x.Id != id, cancellationToken);
        if (duplicateCode)
            return Result.Fail<WorkflowDefinitionDto>("CONFLICT", "Code workflow đã được dùng bởi bản ghi khác.");

        entity.Code = request.Code;
        entity.Name = request.Name;
        entity.Description = request.Description;
        entity.TotalSteps = request.TotalSteps;
        entity.IsDefault = request.IsDefault;
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.WorkflowDefinitions.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "WorkflowDefinition không tồn tại.");
        var hasConfig = await _db.FormWorkflowConfigs.AnyAsync(c => c.WorkflowDefinitionId == id, cancellationToken);
        if (hasConfig)
            return Result.Fail<object>("CONFLICT", "Không thể xóa workflow đang được gán cho form.");
        var hasInstance = await _db.WorkflowInstances.AnyAsync(i => i.WorkflowDefinitionId == id, cancellationToken);
        if (hasInstance)
            return Result.Fail<object>("CONFLICT", "Không thể xóa workflow đã có instance chạy.");

        _db.WorkflowSteps.RemoveRange(await _db.WorkflowSteps.Where(s => s.WorkflowDefinitionId == id).ToListAsync(cancellationToken));
        _db.WorkflowDefinitions.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static WorkflowDefinitionDto MapToDto(WorkflowDefinition e) => new()
    {
        Id = e.Id,
        Code = e.Code,
        Name = e.Name,
        Description = e.Description,
        TotalSteps = e.TotalSteps,
        IsDefault = e.IsDefault,
        IsActive = e.IsActive,
        CreatedAt = e.CreatedAt,
        CreatedBy = e.CreatedBy,
        UpdatedAt = e.UpdatedAt,
        UpdatedBy = e.UpdatedBy
    };
}
