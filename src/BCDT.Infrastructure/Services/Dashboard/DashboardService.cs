using BCDT.Application.Common;
using BCDT.Application.DTOs.Dashboard;
using BCDT.Application.Services.Dashboard;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Dashboard;

/// <summary>Dùng AppDbContext (connection có session context) để RLS đúng. Không dùng AppReadOnlyDbContext cho Dashboard khi có RLS (Prod-3).</summary>
public class DashboardService : IDashboardService
{
    private readonly AppDbContext _db;

    public DashboardService(AppDbContext db) => _db = db;

    public async Task<Result<DashboardAdminStatsDto>> GetAdminStatsAsync(int? userId, int? periodId = null, CancellationToken cancellationToken = default)
    {
        var submissions = _db.ReportSubmissions.AsNoTracking().Where(x => !x.IsDeleted);
        if (periodId.HasValue)
            submissions = submissions.Where(x => x.ReportingPeriodId == periodId.Value);
        var total = await submissions.CountAsync(cancellationToken);
        var draft = await submissions.CountAsync(x => x.Status == "Draft", cancellationToken);
        var submitted = await submissions.CountAsync(x => x.Status == "Submitted", cancellationToken);
        var approved = await submissions.CountAsync(x => x.Status == "Approved", cancellationToken);
        var rejected = await submissions.CountAsync(x => x.Status == "Rejected", cancellationToken);
        var revision = await submissions.CountAsync(x => x.Status == "Revision", cancellationToken);

        var byPeriod = await _db.ReportSubmissions.AsNoTracking()
            .Where(x => !x.IsDeleted)
            .GroupBy(x => new { x.ReportingPeriodId })
            .Select(g => new { g.Key.ReportingPeriodId, Count = g.Count() })
            .ToListAsync(cancellationToken);
        var periodIds = byPeriod.Select(x => x.ReportingPeriodId).Distinct().ToList();
        var periods = await _db.ReportingPeriods.AsNoTracking()
            .Where(x => periodIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, cancellationToken);
        var byPeriodDtos = byPeriod.Select(p => new SubmissionsByPeriodDto
        {
            ReportingPeriodId = p.ReportingPeriodId,
            PeriodCode = periods.GetValueOrDefault(p.ReportingPeriodId)?.PeriodCode ?? "",
            PeriodName = periods.GetValueOrDefault(p.ReportingPeriodId)?.PeriodName ?? "",
            Count = p.Count
        }).ToList();

        var byForm = await _db.ReportSubmissions.AsNoTracking()
            .Where(x => !x.IsDeleted)
            .GroupBy(x => new { x.FormDefinitionId })
            .Select(g => new { g.Key.FormDefinitionId, Count = g.Count() })
            .ToListAsync(cancellationToken);
        var formIds = byForm.Select(x => x.FormDefinitionId).Distinct().ToList();
        var forms = await _db.FormDefinitions.AsNoTracking()
            .Where(x => formIds.Contains(x.Id))
            .ToDictionaryAsync(x => x.Id, cancellationToken);
        var byFormDtos = byForm.Select(f => new SubmissionsByFormDto
        {
            FormDefinitionId = f.FormDefinitionId,
            FormCode = forms.GetValueOrDefault(f.FormDefinitionId)?.Code ?? "",
            FormName = forms.GetValueOrDefault(f.FormDefinitionId)?.Name ?? "",
            Count = f.Count
        }).ToList();

        return Result.Ok(new DashboardAdminStatsDto
        {
            TotalSubmissions = total,
            DraftCount = draft,
            SubmittedCount = submitted,
            ApprovedCount = approved,
            RejectedCount = rejected,
            RevisionCount = revision,
            SubmissionsByPeriod = byPeriodDtos,
            SubmissionsByForm = byFormDtos
        });
    }

    public async Task<Result<DashboardUserTasksDto>> GetUserTasksAsync(int userId, CancellationToken cancellationToken = default)
    {
        var orgIds = await _db.UserOrganizations.AsNoTracking()
            .Where(uo => uo.UserId == userId && uo.IsActive && uo.LeftAt == null)
            .Select(uo => uo.OrganizationId)
            .ToListAsync(cancellationToken);
        if (orgIds.Count == 0)
            return Result.Ok(new DashboardUserTasksDto());

        var submissionsQuery = _db.ReportSubmissions.AsNoTracking()
            .Where(x => !x.IsDeleted && orgIds.Contains(x.OrganizationId));
        var drafts = await submissionsQuery
            .Where(x => x.Status == "Draft" || x.Status == "Revision")
            .Join(_db.FormDefinitions.AsNoTracking(), s => s.FormDefinitionId, f => f.Id, (s, f) => new { s, f })
            .Join(_db.ReportingPeriods.AsNoTracking(), x => x.s.ReportingPeriodId, p => p.Id, (x, p) => new SubmissionTaskDto
            {
                SubmissionId = x.s.Id,
                FormDefinitionId = x.s.FormDefinitionId,
                FormName = x.f.Name,
                ReportingPeriodId = x.s.ReportingPeriodId,
                PeriodName = p.PeriodName,
                Deadline = p.Deadline,
                Status = x.s.Status
            })
            .ToListAsync(cancellationToken);
        var draftList = drafts.Where(x => x.Status == "Draft").ToList();
        var revisionList = drafts.Where(x => x.Status == "Revision").ToList();

        var fromDate = DateTime.UtcNow.Date;
        var toDate = fromDate.AddDays(30);
        var upcomingPeriods = await _db.ReportingPeriods.AsNoTracking()
            .Where(p => p.Deadline >= fromDate && p.Deadline <= toDate && p.Status == "Open")
            .Select(p => new PeriodDeadlineDto
            {
                ReportingPeriodId = p.Id,
                PeriodCode = p.PeriodCode,
                PeriodName = p.PeriodName,
                Deadline = p.Deadline,
                FormCount = 0
            })
            .ToListAsync(cancellationToken);
        var freqIds = upcomingPeriods.Select(x => x.ReportingPeriodId).ToList();
        var periodFreqMap = await _db.ReportingPeriods.AsNoTracking()
            .Where(p => freqIds.Contains(p.Id))
            .ToDictionaryAsync(x => x.Id, x => x.ReportingFrequencyId, cancellationToken);
        foreach (var p in upcomingPeriods)
        {
            if (periodFreqMap.TryGetValue(p.ReportingPeriodId, out var fid))
                p.FormCount = await _db.FormDefinitions.AsNoTracking().CountAsync(f => f.ReportingFrequencyId == fid, cancellationToken);
        }

        var userRoleIds = await _db.UserRoles.AsNoTracking()
            .Where(ur => ur.UserId == userId)
            .Select(ur => ur.RoleId)
            .ToListAsync(cancellationToken);
        var pendingInstances = await _db.WorkflowInstances.AsNoTracking()
            .Where(wi => wi.Status == "Pending")
            .Join(_db.ReportSubmissions.AsNoTracking(), wi => wi.SubmissionId, s => s.Id, (wi, s) => new { wi, s })
            .Where(x => orgIds.Contains(x.s.OrganizationId))
            .Join(_db.FormDefinitions.AsNoTracking(), x => x.s.FormDefinitionId, f => f.Id, (x, f) => new { x.wi, x.s, f })
            .Join(_db.Organizations.AsNoTracking(), x => x.s.OrganizationId, o => o.Id, (x, o) => new { x.wi, x.s, x.f, o })
            .Join(_db.ReportingPeriods.AsNoTracking(), x => x.s.ReportingPeriodId, p => p.Id, (x, p) => new PendingApprovalTaskDto
            {
                WorkflowInstanceId = x.wi.Id,
                SubmissionId = x.s.Id,
                FormName = x.f.Name,
                OrganizationName = x.o.Name,
                PeriodName = p.PeriodName,
                CurrentStep = x.wi.CurrentStep,
                TotalSteps = 0,
                SubmittedAt = x.s.SubmittedAt
            })
            .ToListAsync(cancellationToken);
        var defIds = await _db.WorkflowInstances.AsNoTracking()
            .Where(wi => wi.Status == "Pending" && pendingInstances.Select(pi => pi.WorkflowInstanceId).Contains(wi.Id))
            .Select(wi => new { wi.Id, wi.WorkflowDefinitionId })
            .ToListAsync(cancellationToken);
        var wfIds = defIds.Select(x => x.WorkflowDefinitionId).Distinct().ToList();
        var totalStepsDict = await _db.WorkflowDefinitions.AsNoTracking()
            .Where(w => wfIds.Contains(w.Id))
            .ToDictionaryAsync(w => w.Id, w => (int)w.TotalSteps, cancellationToken);
        foreach (var pi in pendingInstances)
        {
            var wid = defIds.FirstOrDefault(x => x.Id == pi.WorkflowInstanceId)?.WorkflowDefinitionId;
            pi.TotalSteps = wid.HasValue ? totalStepsDict.GetValueOrDefault(wid.Value, 1) : 1;
        }

        return Result.Ok(new DashboardUserTasksDto
        {
            Drafts = draftList,
            Revisions = revisionList,
            UpcomingDeadlines = upcomingPeriods,
            PendingApprovals = pendingInstances
        });
    }
}
