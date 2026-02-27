using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services.Workflow;
using BCDT.Domain.Entities.Data;
using BCDT.Domain.Entities.Workflow;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Workflow;

public class WorkflowExecutionService : IWorkflowExecutionService
{
    private readonly AppDbContext _db;
    private readonly IFormWorkflowConfigService _configService;

    public WorkflowExecutionService(AppDbContext db, IFormWorkflowConfigService configService)
    {
        _db = db;
        _configService = configService;
    }

    public async Task<Result<WorkflowInstanceDto>> SubmitSubmissionAsync(long submissionId, int submittedBy, CancellationToken cancellationToken = default)
    {
        var submission = await _db.ReportSubmissions
            .FirstOrDefaultAsync(s => s.Id == submissionId && !s.IsDeleted, cancellationToken);
        if (submission == null)
            return Result.Fail<WorkflowInstanceDto>("NOT_FOUND", "Submission không tồn tại.");
        if (submission.Status != "Draft")
            return Result.Fail<WorkflowInstanceDto>("VALIDATION_FAILED", "Chỉ submission trạng thái Draft mới được gửi.");

        var orgTypeResult = await GetOrganizationTypeIdAsync(submission.OrganizationId, cancellationToken);
        var wfIdResult = await _configService.GetWorkflowDefinitionIdForFormAsync(submission.FormDefinitionId, orgTypeResult, cancellationToken);
        if (!wfIdResult.IsSuccess || wfIdResult.Data == null)
            return Result.Fail<WorkflowInstanceDto>("NOT_FOUND", "Form chưa được cấu hình workflow.");

        var instance = new WorkflowInstance
        {
            SubmissionId = submissionId,
            WorkflowDefinitionId = wfIdResult.Data.Value,
            CurrentStep = 1,
            Status = "Pending",
            StartedAt = DateTime.UtcNow,
            CreatedBy = submittedBy
        };
        _db.WorkflowInstances.Add(instance);
        await _db.SaveChangesAsync(cancellationToken);

        submission.Status = "Submitted";
        submission.SubmittedAt = DateTime.UtcNow;
        submission.SubmittedBy = submittedBy;
        submission.WorkflowInstanceId = instance.Id;
        submission.CurrentWorkflowStep = 1;
        submission.UpdatedAt = DateTime.UtcNow;
        submission.UpdatedBy = submittedBy;
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok(await MapInstanceToDtoAsync(instance.Id, cancellationToken));
    }

    public async Task<Result<WorkflowInstanceDto>> ApproveAsync(int workflowInstanceId, int approverId, WorkflowActionRequest? request, CancellationToken cancellationToken = default)
    {
        var instance = await _db.WorkflowInstances
            .FirstOrDefaultAsync(i => i.Id == workflowInstanceId, cancellationToken);
        if (instance == null)
            return Result.Fail<WorkflowInstanceDto>("NOT_FOUND", "WorkflowInstance không tồn tại.");
        if (instance.Status != "Pending")
            return Result.Fail<WorkflowInstanceDto>("VALIDATION_FAILED", "Chỉ instance Pending mới được duyệt.");

        var def = await _db.WorkflowDefinitions.FindAsync(new object[] { instance.WorkflowDefinitionId }, cancellationToken);
        if (def == null)
            return Result.Fail<WorkflowInstanceDto>("NOT_FOUND", "WorkflowDefinition không tồn tại.");

        _db.WorkflowApprovals.Add(new WorkflowApproval
        {
            WorkflowInstanceId = workflowInstanceId,
            StepOrder = instance.CurrentStep,
            Action = "Approve",
            Comments = request?.Comments,
            ApproverId = approverId,
            ApprovedAt = DateTime.UtcNow
        });

        if (instance.CurrentStep >= def.TotalSteps)
        {
            instance.Status = "Approved";
            instance.CompletedAt = DateTime.UtcNow;
            var sub = await _db.ReportSubmissions.FirstOrDefaultAsync(s => s.Id == instance.SubmissionId, cancellationToken);
            if (sub != null)
            {
                sub.Status = "Approved";
                sub.ApprovedAt = DateTime.UtcNow;
                sub.ApprovedBy = approverId;
                sub.UpdatedAt = DateTime.UtcNow;
                sub.UpdatedBy = approverId;
            }
        }
        else
        {
            instance.CurrentStep++;
            var sub = await _db.ReportSubmissions.FirstOrDefaultAsync(s => s.Id == instance.SubmissionId, cancellationToken);
            if (sub != null)
            {
                sub.CurrentWorkflowStep = instance.CurrentStep;
                sub.UpdatedAt = DateTime.UtcNow;
                sub.UpdatedBy = approverId;
            }
        }
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(await MapInstanceToDtoAsync(instance.Id, cancellationToken));
    }

    public async Task<Result<BulkApproveResultDto>> BulkApproveAsync(IReadOnlyList<int> workflowInstanceIds, int approverId, WorkflowActionRequest? request, CancellationToken cancellationToken = default)
    {
        var result = new BulkApproveResultDto();
        if (workflowInstanceIds == null || workflowInstanceIds.Count == 0)
            return Result.Ok(result);

        foreach (var id in workflowInstanceIds.Distinct())
        {
            var approveResult = await ApproveAsync(id, approverId, request, cancellationToken);
            if (approveResult.IsSuccess)
                result.SucceededIds.Add(id);
            else
                result.Failed.Add(new BulkApproveFailureItem { WorkflowInstanceId = id, Code = approveResult.Code, Message = approveResult.Message });
        }
        return Result.Ok(result);
    }

    public async Task<Result<WorkflowInstanceDto>> RejectAsync(int workflowInstanceId, int approverId, WorkflowActionRequest? request, CancellationToken cancellationToken = default)
    {
        var instance = await _db.WorkflowInstances.FirstOrDefaultAsync(i => i.Id == workflowInstanceId, cancellationToken);
        if (instance == null)
            return Result.Fail<WorkflowInstanceDto>("NOT_FOUND", "WorkflowInstance không tồn tại.");
        if (instance.Status != "Pending")
            return Result.Fail<WorkflowInstanceDto>("VALIDATION_FAILED", "Chỉ instance Pending mới được từ chối.");

        _db.WorkflowApprovals.Add(new WorkflowApproval
        {
            WorkflowInstanceId = workflowInstanceId,
            StepOrder = instance.CurrentStep,
            Action = "Reject",
            Comments = request?.Comments,
            ApproverId = approverId,
            ApprovedAt = DateTime.UtcNow
        });
        instance.Status = "Rejected";
        instance.CompletedAt = DateTime.UtcNow;

        var sub = await _db.ReportSubmissions.FirstOrDefaultAsync(s => s.Id == instance.SubmissionId, cancellationToken);
        if (sub != null)
        {
            sub.Status = "Rejected";
            sub.UpdatedAt = DateTime.UtcNow;
            sub.UpdatedBy = approverId;
        }
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(await MapInstanceToDtoAsync(instance.Id, cancellationToken));
    }

    public async Task<Result<WorkflowInstanceDto>> RequestRevisionAsync(int workflowInstanceId, int approverId, WorkflowActionRequest? request, CancellationToken cancellationToken = default)
    {
        var instance = await _db.WorkflowInstances.FirstOrDefaultAsync(i => i.Id == workflowInstanceId, cancellationToken);
        if (instance == null)
            return Result.Fail<WorkflowInstanceDto>("NOT_FOUND", "WorkflowInstance không tồn tại.");
        if (instance.Status != "Pending")
            return Result.Fail<WorkflowInstanceDto>("VALIDATION_FAILED", "Chỉ instance Pending mới được yêu cầu chỉnh sửa.");

        _db.WorkflowApprovals.Add(new WorkflowApproval
        {
            WorkflowInstanceId = workflowInstanceId,
            StepOrder = instance.CurrentStep,
            Action = "RequestRevision",
            Comments = request?.Comments,
            ApproverId = approverId,
            ApprovedAt = DateTime.UtcNow
        });

        var sub = await _db.ReportSubmissions.FirstOrDefaultAsync(s => s.Id == instance.SubmissionId, cancellationToken);
        if (sub != null)
        {
            sub.Status = "Revision";
            sub.UpdatedAt = DateTime.UtcNow;
            sub.UpdatedBy = approverId;
        }
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(await MapInstanceToDtoAsync(instance.Id, cancellationToken));
    }

    public async Task<Result<WorkflowInstanceDto?>> GetInstanceBySubmissionIdAsync(long submissionId, CancellationToken cancellationToken = default)
    {
        var instance = await _db.WorkflowInstances
            .AsNoTracking()
            .FirstOrDefaultAsync(i => i.SubmissionId == submissionId, cancellationToken);
        if (instance == null)
            return Result.Ok<WorkflowInstanceDto?>(null);
        var dto = await MapInstanceToDtoAsync(instance.Id, cancellationToken);
        return Result.Ok<WorkflowInstanceDto?>(dto);
    }

    public async Task<Result<List<WorkflowApprovalDto>>> GetApprovalsByInstanceIdAsync(int workflowInstanceId, CancellationToken cancellationToken = default)
    {
        var exists = await _db.WorkflowInstances.AsNoTracking().AnyAsync(i => i.Id == workflowInstanceId, cancellationToken);
        if (!exists)
            return Result.Fail<List<WorkflowApprovalDto>>("NOT_FOUND", "WorkflowInstance không tồn tại.");

        var list = await _db.WorkflowApprovals
            .AsNoTracking()
            .Where(a => a.WorkflowInstanceId == workflowInstanceId)
            .OrderBy(a => a.ApprovedAt)
            .Select(a => new WorkflowApprovalDto
            {
                Id = a.Id,
                StepOrder = a.StepOrder,
                Action = a.Action,
                Comments = a.Comments,
                ApproverId = a.ApproverId,
                ApprovedAt = a.ApprovedAt
            })
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    private async Task<int?> GetOrganizationTypeIdAsync(int organizationId, CancellationToken cancellationToken)
    {
        var org = await _db.Organizations.AsNoTracking()
            .Where(o => o.Id == organizationId)
            .Select(o => (int?)o.OrganizationTypeId)
            .FirstOrDefaultAsync(cancellationToken);
        return org;
    }

    private async Task<WorkflowInstanceDto> MapInstanceToDtoAsync(int instanceId, CancellationToken cancellationToken)
    {
        var i = await _db.WorkflowInstances.AsNoTracking().FirstAsync(x => x.Id == instanceId, cancellationToken);
        var w = await _db.WorkflowDefinitions.AsNoTracking().FirstOrDefaultAsync(x => x.Id == i.WorkflowDefinitionId, cancellationToken);
        return new WorkflowInstanceDto
        {
            Id = i.Id,
            SubmissionId = i.SubmissionId,
            WorkflowDefinitionId = i.WorkflowDefinitionId,
            WorkflowDefinitionCode = w?.Code,
            CurrentStep = i.CurrentStep,
            Status = i.Status,
            StartedAt = i.StartedAt,
            CompletedAt = i.CompletedAt,
            CreatedBy = i.CreatedBy
        };
    }
}
