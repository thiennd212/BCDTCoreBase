using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.Services.Data;
using BCDT.Domain.Entities.Data;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class ReportSubmissionService : IReportSubmissionService
{
    private readonly AppDbContext _db;

    public ReportSubmissionService(AppDbContext db) => _db = db;

    public async Task<Result<ReportSubmissionDto?>> GetByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportSubmissions
            .AsNoTracking()
            .Where(s => s.Id == id && !s.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Ok<ReportSubmissionDto?>(null);
        return Result.Ok<ReportSubmissionDto?>(MapToDto(entity));
    }

    public async Task<Result<List<ReportSubmissionDto>>> GetListAsync(int? formDefinitionId, int? organizationId, int? reportingPeriodId, string? status, bool includeDeleted, CancellationToken cancellationToken = default)
    {
        var query = _db.ReportSubmissions.AsNoTracking();
        if (!includeDeleted)
            query = query.Where(s => !s.IsDeleted);
        if (formDefinitionId.HasValue)
            query = query.Where(s => s.FormDefinitionId == formDefinitionId.Value);
        if (organizationId.HasValue)
            query = query.Where(s => s.OrganizationId == organizationId.Value);
        if (reportingPeriodId.HasValue)
            query = query.Where(s => s.ReportingPeriodId == reportingPeriodId.Value);
        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(s => s.Status == status);

        var list = await query
            .OrderByDescending(s => s.CreatedAt)
            .Select(s => MapToDto(s))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<PagedResultDto<ReportSubmissionDto>>> GetListPagedAsync(int? formDefinitionId, int? organizationId, int? reportingPeriodId, string? status, bool includeDeleted, int pageSize, int pageNumber, CancellationToken cancellationToken = default)
    {
        if (pageSize <= 0) pageSize = 20;
        if (pageNumber <= 0) pageNumber = 1;
        pageSize = Math.Min(pageSize, PagingConstants.MaxPageSize);
        var query = _db.ReportSubmissions.AsNoTracking();
        if (!includeDeleted)
            query = query.Where(s => !s.IsDeleted);
        if (formDefinitionId.HasValue)
            query = query.Where(s => s.FormDefinitionId == formDefinitionId.Value);
        if (organizationId.HasValue)
            query = query.Where(s => s.OrganizationId == organizationId.Value);
        if (reportingPeriodId.HasValue)
            query = query.Where(s => s.ReportingPeriodId == reportingPeriodId.Value);
        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(s => s.Status == status);

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderByDescending(s => s.CreatedAt)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(s => MapToDto(s))
            .ToListAsync(cancellationToken);
        var paged = new PagedResultDto<ReportSubmissionDto>(items, totalCount, pageNumber, pageSize);
        return Result.Ok(paged);
    }

    public async Task<Result<ReportSubmissionDto>> CreateAsync(CreateReportSubmissionRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var formExists = await _db.FormDefinitions.AnyAsync(f => f.Id == request.FormDefinitionId && !f.IsDeleted, cancellationToken);
        if (!formExists)
            return Result.Fail<ReportSubmissionDto>("NOT_FOUND", "FormDefinition không tồn tại.");
        var versionExists = await _db.FormVersions.AnyAsync(v => v.Id == request.FormVersionId && v.FormDefinitionId == request.FormDefinitionId, cancellationToken);
        if (!versionExists)
            return Result.Fail<ReportSubmissionDto>("NOT_FOUND", "FormVersion không tồn tại hoặc không thuộc FormDefinition.");
        var orgExists = await _db.Organizations.AnyAsync(o => o.Id == request.OrganizationId, cancellationToken);
        if (!orgExists)
            return Result.Fail<ReportSubmissionDto>("NOT_FOUND", "Organization không tồn tại.");

        var exists = await _db.ReportSubmissions.AnyAsync(s =>
            s.FormDefinitionId == request.FormDefinitionId &&
            s.OrganizationId == request.OrganizationId &&
            s.ReportingPeriodId == request.ReportingPeriodId &&
            !s.IsDeleted, cancellationToken);
        if (exists)
            return Result.Fail<ReportSubmissionDto>("CONFLICT", "Đã tồn tại submission cho Form/Đơn vị/Kỳ báo cáo này.");

        var entity = new ReportSubmission
        {
            FormDefinitionId = request.FormDefinitionId,
            FormVersionId = request.FormVersionId,
            OrganizationId = request.OrganizationId,
            ReportingPeriodId = request.ReportingPeriodId,
            Status = request.Status ?? "Draft",
            Version = 1,
            RevisionNumber = 0,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy,
            IsDeleted = false
        };
        _db.ReportSubmissions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<BulkCreateSubmissionsResultDto>> BulkCreateAsync(BulkCreateSubmissionsRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        if (request.OrganizationIds == null || request.OrganizationIds.Count == 0)
            return Result.Ok(new BulkCreateSubmissionsResultDto());

        var formExists = await _db.FormDefinitions.AnyAsync(f => f.Id == request.FormDefinitionId && !f.IsDeleted, cancellationToken);
        if (!formExists)
            return Result.Fail<BulkCreateSubmissionsResultDto>("NOT_FOUND", "FormDefinition không tồn tại.");
        var versionExists = await _db.FormVersions.AnyAsync(v => v.Id == request.FormVersionId && v.FormDefinitionId == request.FormDefinitionId, cancellationToken);
        if (!versionExists)
            return Result.Fail<BulkCreateSubmissionsResultDto>("NOT_FOUND", "FormVersion không tồn tại hoặc không thuộc FormDefinition.");
        var periodExists = await _db.ReportingPeriods.AnyAsync(p => p.Id == request.ReportingPeriodId, cancellationToken);
        if (!periodExists)
            return Result.Fail<BulkCreateSubmissionsResultDto>("NOT_FOUND", "ReportingPeriod không tồn tại.");

        var existingKeys = await _db.ReportSubmissions
            .Where(s => s.FormDefinitionId == request.FormDefinitionId && s.ReportingPeriodId == request.ReportingPeriodId && !s.IsDeleted)
            .Select(s => s.OrganizationId)
            .ToListAsync(cancellationToken);
        var existingSet = existingKeys.ToHashSet();

        var result = new BulkCreateSubmissionsResultDto();
        foreach (var orgId in request.OrganizationIds.Distinct())
        {
            if (existingSet.Contains(orgId))
            {
                result.SkippedCount++;
                continue;
            }
            var orgExists = await _db.Organizations.AnyAsync(o => o.Id == orgId, cancellationToken);
            if (!orgExists)
            {
                result.Errors.Add(new BulkCreateErrorItem { OrganizationId = orgId, Code = "NOT_FOUND", Message = "Organization không tồn tại." });
                continue;
            }
            var entity = new ReportSubmission
            {
                FormDefinitionId = request.FormDefinitionId,
                FormVersionId = request.FormVersionId,
                OrganizationId = orgId,
                ReportingPeriodId = request.ReportingPeriodId,
                Status = "Draft",
                Version = 1,
                RevisionNumber = 0,
                CreatedAt = DateTime.UtcNow,
                CreatedBy = createdBy,
                IsDeleted = false
            };
            _db.ReportSubmissions.Add(entity);
            await _db.SaveChangesAsync(cancellationToken);
            result.CreatedIds.Add(entity.Id);
            existingSet.Add(orgId);
        }
        return Result.Ok(result);
    }

    public async Task<Result<ReportSubmissionDto>> UpdateAsync(long id, UpdateReportSubmissionRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportSubmissions.FirstOrDefaultAsync(s => s.Id == id && !s.IsDeleted, cancellationToken);
        if (entity == null)
            return Result.Fail<ReportSubmissionDto>("NOT_FOUND", "Submission không tồn tại.");

        // Deadline enforcement: block submit after deadline unless AllowLateSubmission
        if (!string.IsNullOrWhiteSpace(request.Status) && request.Status == "Submitted")
        {
            var period = entity.ReportingPeriodId > 0
                ? await _db.ReportingPeriods.AsNoTracking().FirstOrDefaultAsync(p => p.Id == entity.ReportingPeriodId, cancellationToken)
                : null;
            if (period != null && DateTime.UtcNow > period.Deadline)
            {
                var form = await _db.FormDefinitions.AsNoTracking().FirstOrDefaultAsync(f => f.Id == entity.FormDefinitionId, cancellationToken);
                if (form != null && !form.AllowLateSubmission)
                    return Result.Fail<ReportSubmissionDto>("DEADLINE_PASSED", $"Đã quá hạn nộp ({period.Deadline:dd/MM/yyyy}). Biểu mẫu không cho phép nộp trễ.");
            }

            // Validate required rows: nếu form có hàng IsRequired, phải có ít nhất 1 ReportDataRow
            var sheetIds = await _db.FormSheets
                .AsNoTracking()
                .Where(s => s.FormDefinitionId == entity.FormDefinitionId)
                .Select(s => s.Id)
                .ToListAsync(cancellationToken);
            if (sheetIds.Count > 0)
            {
                var hasRequired = await _db.FormRows
                    .AsNoTracking()
                    .AnyAsync(r => sheetIds.Contains(r.FormSheetId) && r.IsRequired, cancellationToken);
                if (hasRequired)
                {
                    var dataCount = await _db.ReportDataRows
                        .AsNoTracking()
                        .Where(d => d.SubmissionId == entity.Id)
                        .CountAsync(cancellationToken);
                    if (dataCount == 0)
                        return Result.Fail<ReportSubmissionDto>("VALIDATION_FAILED", "Vui lòng điền đủ các trường bắt buộc trước khi nộp báo cáo.");
                }
            }

            entity.SubmittedAt = DateTime.UtcNow;
            entity.SubmittedBy = updatedBy;
        }

        if (!string.IsNullOrWhiteSpace(request.Status))
            entity.Status = request.Status;
        if (request.IsLocked.HasValue)
            entity.IsLocked = request.IsLocked.Value;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(long id, int deletedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportSubmissions.FirstOrDefaultAsync(s => s.Id == id && !s.IsDeleted, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Submission không tồn tại.");
        entity.IsDeleted = true;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = deletedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static ReportSubmissionDto MapToDto(ReportSubmission s) => new()
    {
        Id = s.Id,
        FormDefinitionId = s.FormDefinitionId,
        FormVersionId = s.FormVersionId,
        OrganizationId = s.OrganizationId,
        ReportingPeriodId = s.ReportingPeriodId,
        Status = s.Status,
        SubmittedAt = s.SubmittedAt,
        SubmittedBy = s.SubmittedBy,
        ApprovedAt = s.ApprovedAt,
        ApprovedBy = s.ApprovedBy,
        WorkflowInstanceId = s.WorkflowInstanceId,
        CurrentWorkflowStep = s.CurrentWorkflowStep,
        IsLocked = s.IsLocked,
        LockedBy = s.LockedBy,
        LockedAt = s.LockedAt,
        LockExpiresAt = s.LockExpiresAt,
        Version = s.Version,
        RevisionNumber = s.RevisionNumber,
        CreatedAt = s.CreatedAt,
        CreatedBy = s.CreatedBy,
        UpdatedAt = s.UpdatedAt,
        UpdatedBy = s.UpdatedBy
    };
}
