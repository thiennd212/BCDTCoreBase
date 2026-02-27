using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services.Workflow;
using BCDT.Domain.Entities.Workflow;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Workflow;

public class FormWorkflowConfigService : IFormWorkflowConfigService
{
    private readonly AppDbContext _db;

    public FormWorkflowConfigService(AppDbContext db) => _db = db;

    public async Task<Result<List<FormWorkflowConfigDto>>> GetByFormIdAsync(int formDefinitionId, CancellationToken cancellationToken = default)
    {
        var list = await (from c in _db.FormWorkflowConfigs.AsNoTracking()
                         where c.FormDefinitionId == formDefinitionId
                         join f in _db.FormDefinitions.AsNoTracking() on c.FormDefinitionId equals f.Id
                         join w in _db.WorkflowDefinitions.AsNoTracking() on c.WorkflowDefinitionId equals w.Id
                         join o in _db.OrganizationTypes.AsNoTracking() on c.OrganizationTypeId equals o.Id into oLeft
                         from o in oLeft.DefaultIfEmpty()
                         orderby c.Id
                         select new FormWorkflowConfigDto
                         {
                             Id = c.Id,
                             FormDefinitionId = c.FormDefinitionId,
                             FormDefinitionCode = f.Code,
                             WorkflowDefinitionId = c.WorkflowDefinitionId,
                             WorkflowDefinitionCode = w.Code,
                             OrganizationTypeId = c.OrganizationTypeId,
                             OrganizationTypeCode = o != null ? o.Code : null,
                             IsActive = c.IsActive,
                             CreatedAt = c.CreatedAt,
                             CreatedBy = c.CreatedBy
                         }).ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<FormWorkflowConfigDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var c = await (from config in _db.FormWorkflowConfigs.AsNoTracking()
                      where config.Id == id
                      join f in _db.FormDefinitions.AsNoTracking() on config.FormDefinitionId equals f.Id
                      join w in _db.WorkflowDefinitions.AsNoTracking() on config.WorkflowDefinitionId equals w.Id
                      join o in _db.OrganizationTypes.AsNoTracking() on config.OrganizationTypeId equals o.Id into oLeft
                      from o in oLeft.DefaultIfEmpty()
                      select new FormWorkflowConfigDto
                      {
                          Id = config.Id,
                          FormDefinitionId = config.FormDefinitionId,
                          FormDefinitionCode = f.Code,
                          WorkflowDefinitionId = config.WorkflowDefinitionId,
                          WorkflowDefinitionCode = w.Code,
                          OrganizationTypeId = config.OrganizationTypeId,
                          OrganizationTypeCode = o != null ? o.Code : null,
                          IsActive = config.IsActive,
                          CreatedAt = config.CreatedAt,
                          CreatedBy = config.CreatedBy
                      }).FirstOrDefaultAsync(cancellationToken);
        return Result.Ok<FormWorkflowConfigDto?>(c);
    }

    public async Task<Result<FormWorkflowConfigDto>> CreateAsync(CreateFormWorkflowConfigRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var formExists = await _db.FormDefinitions.AnyAsync(f => f.Id == request.FormDefinitionId, cancellationToken);
        if (!formExists)
            return Result.Fail<FormWorkflowConfigDto>("NOT_FOUND", "FormDefinition không tồn tại.");
        var wfExists = await _db.WorkflowDefinitions.AnyAsync(w => w.Id == request.WorkflowDefinitionId, cancellationToken);
        if (!wfExists)
            return Result.Fail<FormWorkflowConfigDto>("NOT_FOUND", "WorkflowDefinition không tồn tại.");
        if (request.OrganizationTypeId.HasValue)
        {
            var orgTypeExists = await _db.OrganizationTypes.AnyAsync(o => o.Id == request.OrganizationTypeId.Value, cancellationToken);
            if (!orgTypeExists)
                return Result.Fail<FormWorkflowConfigDto>("NOT_FOUND", "OrganizationType không tồn tại.");
        }

        var entity = new FormWorkflowConfig
        {
            FormDefinitionId = request.FormDefinitionId,
            WorkflowDefinitionId = request.WorkflowDefinitionId,
            OrganizationTypeId = request.OrganizationTypeId,
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormWorkflowConfigs.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        var dto = await GetByIdAsync(entity.Id, cancellationToken);
        return Result.Ok(dto.Data!);
    }

    public async Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormWorkflowConfigs.FirstOrDefaultAsync(x => x.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "FormWorkflowConfig không tồn tại.");

        _db.FormWorkflowConfigs.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    public async Task<Result<int?>> GetWorkflowDefinitionIdForFormAsync(int formDefinitionId, int? organizationTypeId, CancellationToken cancellationToken = default)
    {
        var config = await _db.FormWorkflowConfigs
            .AsNoTracking()
            .Where(c => c.FormDefinitionId == formDefinitionId && c.IsActive)
            .Where(c => c.OrganizationTypeId == null || c.OrganizationTypeId == organizationTypeId)
            .OrderByDescending(c => c.OrganizationTypeId != null)
            .Select(c => (int?)c.WorkflowDefinitionId)
            .FirstOrDefaultAsync(cancellationToken);
        return Result.Ok(config);
    }
}
