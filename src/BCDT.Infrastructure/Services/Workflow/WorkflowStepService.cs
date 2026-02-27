using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services.Workflow;
using BCDT.Domain.Entities.Workflow;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Workflow;

public class WorkflowStepService : IWorkflowStepService
{
    private readonly AppDbContext _db;

    public WorkflowStepService(AppDbContext db) => _db = db;

    public async Task<Result<List<WorkflowStepDto>>> GetByDefinitionIdAsync(int workflowDefinitionId, CancellationToken cancellationToken = default)
    {
        var defExists = await _db.WorkflowDefinitions.AnyAsync(x => x.Id == workflowDefinitionId, cancellationToken);
        if (!defExists)
            return Result.Fail<List<WorkflowStepDto>>("NOT_FOUND", "WorkflowDefinition không tồn tại.");

        var list = await (from s in _db.WorkflowSteps.AsNoTracking()
                         where s.WorkflowDefinitionId == workflowDefinitionId
                         join r in _db.Roles.AsNoTracking() on s.ApproverRoleId equals r.Id into rLeft
                         from r in rLeft.DefaultIfEmpty()
                         orderby s.StepOrder
                         select new WorkflowStepDto
                         {
                             Id = s.Id,
                             WorkflowDefinitionId = s.WorkflowDefinitionId,
                             StepOrder = s.StepOrder,
                             StepName = s.StepName,
                             StepDescription = s.StepDescription,
                             ApproverRoleId = s.ApproverRoleId,
                             ApproverRoleCode = r != null ? r.Code : null,
                             ApproverUserId = s.ApproverUserId,
                             CanReject = s.CanReject,
                             CanRequestRevision = s.CanRequestRevision,
                             AutoApproveAfterDays = s.AutoApproveAfterDays,
                             NotifyOnPending = s.NotifyOnPending,
                             NotifyOnApprove = s.NotifyOnApprove,
                             NotifyOnReject = s.NotifyOnReject,
                             IsActive = s.IsActive
                         }).ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<WorkflowStepDto?>> GetByIdAsync(int workflowDefinitionId, int stepId, CancellationToken cancellationToken = default)
    {
        var step = await (from s in _db.WorkflowSteps.AsNoTracking()
                         where s.Id == stepId && s.WorkflowDefinitionId == workflowDefinitionId
                         join r in _db.Roles.AsNoTracking() on s.ApproverRoleId equals r.Id into rLeft
                         from r in rLeft.DefaultIfEmpty()
                         select new WorkflowStepDto
                         {
                             Id = s.Id,
                             WorkflowDefinitionId = s.WorkflowDefinitionId,
                             StepOrder = s.StepOrder,
                             StepName = s.StepName,
                             StepDescription = s.StepDescription,
                             ApproverRoleId = s.ApproverRoleId,
                             ApproverRoleCode = r != null ? r.Code : null,
                             ApproverUserId = s.ApproverUserId,
                             CanReject = s.CanReject,
                             CanRequestRevision = s.CanRequestRevision,
                             AutoApproveAfterDays = s.AutoApproveAfterDays,
                             NotifyOnPending = s.NotifyOnPending,
                             NotifyOnApprove = s.NotifyOnApprove,
                             NotifyOnReject = s.NotifyOnReject,
                             IsActive = s.IsActive
                         }).FirstOrDefaultAsync(cancellationToken);
        return Result.Ok<WorkflowStepDto?>(step);
    }

    public async Task<Result<WorkflowStepDto>> CreateAsync(int workflowDefinitionId, CreateWorkflowStepRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var def = await _db.WorkflowDefinitions.FirstOrDefaultAsync(x => x.Id == workflowDefinitionId, cancellationToken);
        if (def == null)
            return Result.Fail<WorkflowStepDto>("NOT_FOUND", "WorkflowDefinition không tồn tại.");
        var maxOrder = await _db.WorkflowSteps.Where(s => s.WorkflowDefinitionId == workflowDefinitionId).MaxAsync(s => (byte?)s.StepOrder, cancellationToken) ?? 0;
        if (request.StepOrder < 1 || request.StepOrder > maxOrder + 1)
            return Result.Fail<WorkflowStepDto>("VALIDATION_FAILED", "StepOrder phải từ 1 đến " + (maxOrder + 1) + ".");

        var entity = new WorkflowStep
        {
            WorkflowDefinitionId = workflowDefinitionId,
            StepOrder = request.StepOrder,
            StepName = request.StepName,
            StepDescription = request.StepDescription,
            ApproverRoleId = request.ApproverRoleId,
            ApproverUserId = request.ApproverUserId,
            CanReject = request.CanReject,
            CanRequestRevision = request.CanRequestRevision,
            AutoApproveAfterDays = request.AutoApproveAfterDays,
            NotifyOnPending = request.NotifyOnPending,
            NotifyOnApprove = request.NotifyOnApprove,
            NotifyOnReject = request.NotifyOnReject,
            IsActive = request.IsActive
        };
        _db.WorkflowSteps.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        var dto = await GetByIdAsync(workflowDefinitionId, entity.Id, cancellationToken);
        return Result.Ok(dto.Data!);
    }

    public async Task<Result<WorkflowStepDto>> UpdateAsync(int workflowDefinitionId, int stepId, UpdateWorkflowStepRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.WorkflowSteps.FirstOrDefaultAsync(s => s.Id == stepId && s.WorkflowDefinitionId == workflowDefinitionId, cancellationToken);
        if (entity == null)
            return Result.Fail<WorkflowStepDto>("NOT_FOUND", "WorkflowStep không tồn tại.");

        entity.StepOrder = request.StepOrder;
        entity.StepName = request.StepName;
        entity.StepDescription = request.StepDescription;
        entity.ApproverRoleId = request.ApproverRoleId;
        entity.ApproverUserId = request.ApproverUserId;
        entity.CanReject = request.CanReject;
        entity.CanRequestRevision = request.CanRequestRevision;
        entity.AutoApproveAfterDays = request.AutoApproveAfterDays;
        entity.NotifyOnPending = request.NotifyOnPending;
        entity.NotifyOnApprove = request.NotifyOnApprove;
        entity.NotifyOnReject = request.NotifyOnReject;
        entity.IsActive = request.IsActive;
        await _db.SaveChangesAsync(cancellationToken);
        var dto = await GetByIdAsync(workflowDefinitionId, entity.Id, cancellationToken);
        return Result.Ok(dto.Data!);
    }

    public async Task<Result<object>> DeleteAsync(int workflowDefinitionId, int stepId, int deletedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.WorkflowSteps.FirstOrDefaultAsync(s => s.Id == stepId && s.WorkflowDefinitionId == workflowDefinitionId, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "WorkflowStep không tồn tại.");

        _db.WorkflowSteps.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }
}
