using System.Globalization;
using System.Text;
using System.Text.RegularExpressions;
using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormDefinitionService : IFormDefinitionService
{
    private readonly AppDbContext _db;

    public FormDefinitionService(AppDbContext db)
    {
        _db = db;
    }

    public async Task<Result<FormDefinitionDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDefinitions
            .AsNoTracking()
            .Where(f => f.Id == id && !f.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Ok<FormDefinitionDto?>(null);
        return Result.Ok<FormDefinitionDto?>(MapToDto(entity));
    }

    public async Task<Result<FormDefinitionDto?>> GetByCodeAsync(string code, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDefinitions
            .AsNoTracking()
            .Where(f => f.Code == code && !f.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Ok<FormDefinitionDto?>(null);
        return Result.Ok<FormDefinitionDto?>(MapToDto(entity));
    }

    public async Task<Result<List<FormDefinitionDto>>> GetListAsync(string? status, string? formType, bool includeInactive, CancellationToken cancellationToken = default)
    {
        var query = _db.FormDefinitions.AsNoTracking().Where(f => !f.IsDeleted);
        if (!includeInactive)
            query = query.Where(f => f.IsActive);
        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(f => f.Status == status);
        if (!string.IsNullOrWhiteSpace(formType))
            query = query.Where(f => f.FormType == formType);

        var list = await query
            .OrderBy(f => f.Code)
            .Select(f => MapToDto(f))
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<PagedResultDto<FormDefinitionDto>>> GetListPagedAsync(string? status, string? formType, bool includeInactive, int pageSize, int pageNumber, CancellationToken cancellationToken = default)
    {
        if (pageSize <= 0) pageSize = 20;
        if (pageNumber <= 0) pageNumber = 1;
        pageSize = Math.Min(pageSize, PagingConstants.MaxPageSize);
        var query = _db.FormDefinitions.AsNoTracking().Where(f => !f.IsDeleted);
        if (!includeInactive)
            query = query.Where(f => f.IsActive);
        if (!string.IsNullOrWhiteSpace(status))
            query = query.Where(f => f.Status == status);
        if (!string.IsNullOrWhiteSpace(formType))
            query = query.Where(f => f.FormType == formType);

        var totalCount = await query.CountAsync(cancellationToken);
        var items = await query
            .OrderBy(f => f.Code)
            .Skip((pageNumber - 1) * pageSize)
            .Take(pageSize)
            .Select(f => MapToDto(f))
            .ToListAsync(cancellationToken);
        var paged = new PagedResultDto<FormDefinitionDto>(items, totalCount, pageNumber, pageSize);
        return Result.Ok(paged);
    }

    public async Task<Result<FormDefinitionDto>> CreateAsync(CreateFormDefinitionRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        if (request.FormType != "Input" && request.FormType != "Aggregate")
            return Result.Fail<FormDefinitionDto>("VALIDATION_FAILED", "FormType phải là Input hoặc Aggregate.");
        if (await _db.FormDefinitions.AnyAsync(f => f.Code == request.Code && !f.IsDeleted, cancellationToken))
            return Result.Fail<FormDefinitionDto>("CONFLICT", "Code biểu mẫu đã tồn tại.");
        if (request.ReportingFrequencyId.HasValue)
        {
            var freqExists = await _db.ReportingFrequencies.AnyAsync(r => r.Id == request.ReportingFrequencyId.Value, cancellationToken);
            if (!freqExists)
                return Result.Fail<FormDefinitionDto>("NOT_FOUND", "ReportingFrequency không tồn tại.");
        }

        var entity = new FormDefinition
        {
            Code = request.Code,
            Name = request.Name,
            Description = request.Description,
            FormType = request.FormType,
            CurrentVersion = 1,
            ReportingFrequencyId = request.ReportingFrequencyId,
            DeadlineOffsetDays = request.DeadlineOffsetDays,
            AllowLateSubmission = request.AllowLateSubmission,
            RequireApproval = request.RequireApproval,
            AutoCreateReport = request.AutoCreateReport,
            Status = "Draft",
            IsActive = request.IsActive,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy,
            IsDeleted = false
        };
        _db.FormDefinitions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);

        var version = new FormVersion
        {
            FormDefinitionId = entity.Id,
            VersionNumber = 1,
            VersionName = "Phiên bản 1",
            IsActive = true,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormVersions.Add(version);
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormDefinitionDto>> UpdateAsync(int id, UpdateFormDefinitionRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDefinitions.FirstOrDefaultAsync(f => f.Id == id && !f.IsDeleted, cancellationToken);
        if (entity == null)
            return Result.Fail<FormDefinitionDto>("NOT_FOUND", "Biểu mẫu không tồn tại.");
        if (request.FormType != "Input" && request.FormType != "Aggregate")
            return Result.Fail<FormDefinitionDto>("VALIDATION_FAILED", "FormType phải là Input hoặc Aggregate.");
        if (await _db.FormDefinitions.AnyAsync(f => f.Code == request.Code && f.Id != id && !f.IsDeleted, cancellationToken))
            return Result.Fail<FormDefinitionDto>("CONFLICT", "Code biểu mẫu đã tồn tại.");
        if (request.ReportingFrequencyId.HasValue)
        {
            var freqExists = await _db.ReportingFrequencies.AnyAsync(r => r.Id == request.ReportingFrequencyId.Value, cancellationToken);
            if (!freqExists)
                return Result.Fail<FormDefinitionDto>("NOT_FOUND", "ReportingFrequency không tồn tại.");
        }

        entity.Code = request.Code;
        entity.Name = request.Name;
        entity.Description = request.Description;
        entity.FormType = request.FormType;
        entity.ReportingFrequencyId = request.ReportingFrequencyId;
        entity.DeadlineOffsetDays = request.DeadlineOffsetDays;
        entity.AllowLateSubmission = request.AllowLateSubmission;
        entity.RequireApproval = request.RequireApproval;
        entity.AutoCreateReport = request.AutoCreateReport;
        entity.Status = request.Status;
        entity.IsActive = request.IsActive;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormDefinitions.FirstOrDefaultAsync(f => f.Id == id && !f.IsDeleted, cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Biểu mẫu không tồn tại.");
        entity.IsDeleted = true;
        entity.UpdatedAt = DateTime.UtcNow;
        entity.UpdatedBy = deletedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    public async Task<Result<List<FormVersionDto>>> GetVersionsAsync(int formDefinitionId, CancellationToken cancellationToken = default)
    {
        var formExists = await _db.FormDefinitions.AnyAsync(f => f.Id == formDefinitionId && !f.IsDeleted, cancellationToken);
        if (!formExists)
            return Result.Fail<List<FormVersionDto>>("NOT_FOUND", "Biểu mẫu không tồn tại.");

        var list = await _db.FormVersions
            .AsNoTracking()
            .Where(v => v.FormDefinitionId == formDefinitionId)
            .OrderByDescending(v => v.VersionNumber)
            .Select(v => new FormVersionDto
            {
                Id = v.Id,
                FormDefinitionId = v.FormDefinitionId,
                VersionNumber = v.VersionNumber,
                VersionName = v.VersionName,
                ChangeDescription = v.ChangeDescription,
                IsActive = v.IsActive,
                CreatedAt = v.CreatedAt,
                CreatedBy = v.CreatedBy
            })
            .ToListAsync(cancellationToken);
        return Result.Ok(list);
    }

    public async Task<Result<FormDefinitionDto>> CreateFromTemplateAsync(byte[] templateFileBytes, string fileName, string formName, string? code, int createdBy, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(formName))
            return Result.Fail<FormDefinitionDto>("VALIDATION_FAILED", "Tên biểu mẫu không được để trống.");

        string finalCode;
        if (!string.IsNullOrWhiteSpace(code))
        {
            finalCode = code.Trim();
            if (await _db.FormDefinitions.AnyAsync(f => f.Code == finalCode && !f.IsDeleted, cancellationToken))
                return Result.Fail<FormDefinitionDto>("CONFLICT", "Mã biểu mẫu đã tồn tại.");
        }
        else
        {
            var baseCode = SlugFromName(formName);
            finalCode = baseCode;
            var suffix = 0;
            while (await _db.FormDefinitions.AnyAsync(f => f.Code == finalCode && !f.IsDeleted, cancellationToken))
                finalCode = baseCode + "_" + (++suffix);
        }

        ExtractedFormStructure structure;
        string displayJson;
        try
        {
            using var ms1 = new MemoryStream(templateFileBytes);
            structure = ExcelTemplateParser.ExtractStructure(ms1);
            using var ms2 = new MemoryStream(templateFileBytes);
            displayJson = ExcelTemplateParser.ParseToFortuneSheetJson(ms2);
        }
        catch (Exception ex)
        {
            return Result.Fail<FormDefinitionDto>("PARSE_ERROR", "Không thể đọc file Excel: " + ex.Message);
        }

        var now = DateTime.UtcNow;
        var entity = new FormDefinition
        {
            Code = finalCode,
            Name = formName.Trim(),
            Description = "Tạo từ template: " + (string.IsNullOrEmpty(fileName) ? "template.xlsx" : fileName),
            FormType = "Input",
            CurrentVersion = 1,
            DeadlineOffsetDays = 5,
            AllowLateSubmission = true,
            RequireApproval = true,
            AutoCreateReport = false,
            TemplateFile = templateFileBytes,
            TemplateFileName = string.IsNullOrEmpty(fileName) ? "template.xlsx" : System.IO.Path.GetFileName(fileName),
            TemplateDisplayJson = displayJson,
            Status = "Draft",
            IsActive = true,
            CreatedAt = now,
            CreatedBy = createdBy,
            IsDeleted = false
        };
        _db.FormDefinitions.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);

        var version = new FormVersion
        {
            FormDefinitionId = entity.Id,
            VersionNumber = 1,
            VersionName = "Phiên bản 1",
            IsActive = true,
            CreatedAt = now,
            CreatedBy = createdBy
        };
        _db.FormVersions.Add(version);
        await _db.SaveChangesAsync(cancellationToken);

        var sheetIdByIndex = new Dictionary<int, int>();
        foreach (var sh in structure.Sheets)
        {
            var formSheet = new FormSheet
            {
                FormDefinitionId = entity.Id,
                SheetIndex = (byte)sh.SheetIndex,
                SheetName = sh.SheetName,
                DisplayName = sh.SheetName,
                IsDataSheet = true,
                IsVisible = true,
                DisplayOrder = sh.SheetIndex,
                CreatedAt = now,
                CreatedBy = createdBy
            };
            _db.FormSheets.Add(formSheet);
            await _db.SaveChangesAsync(cancellationToken);
            sheetIdByIndex[sh.SheetIndex] = formSheet.Id;
        }

        foreach (var sh in structure.Sheets)
        {
            if (!sheetIdByIndex.TryGetValue(sh.SheetIndex, out var formSheetId)) continue;
            var order = 0;
            foreach (var col in sh.Columns)
            {
                var formCol = new FormColumn
                {
                    FormSheetId = formSheetId,
                    ColumnCode = "COL_" + col.ExcelColumn,
                    ColumnName = col.ColumnName,
                    ExcelColumn = col.ExcelColumn,
                    DataType = col.DataType,
                    IsRequired = false,
                    IsEditable = true,
                    IsHidden = false,
                    DisplayOrder = order++,
                    CreatedAt = now,
                    CreatedBy = createdBy
                };
                _db.FormColumns.Add(formCol);
            }
        }
        await _db.SaveChangesAsync(cancellationToken);

        var created = await _db.FormDefinitions.AsNoTracking().FirstAsync(f => f.Id == entity.Id, cancellationToken);
        return Result.Ok(MapToDto(created));
    }

    private static string SlugFromName(string name)
    {
        if (string.IsNullOrWhiteSpace(name)) return "form";
        var normalized = name.Normalize(NormalizationForm.FormD);
        var sb = new System.Text.StringBuilder();
        foreach (var c in normalized)
        {
            if (CharUnicodeInfo.GetUnicodeCategory(c) != UnicodeCategory.NonSpacingMark)
                sb.Append(c);
        }
        var s = sb.ToString().Normalize(NormalizationForm.FormC).Trim();
        s = Regex.Replace(s, @"[\s_]+", "_");
        s = Regex.Replace(s, @"[^a-zA-Z0-9_]", "");
        if (s.Length > 50) s = s[..50];
        return string.IsNullOrEmpty(s) ? "form" : s;
    }

    private static FormDefinitionDto MapToDto(FormDefinition f) => new()
    {
        Id = f.Id,
        Code = f.Code,
        Name = f.Name,
        Description = f.Description,
        FormType = f.FormType,
        CurrentVersion = f.CurrentVersion,
        ReportingFrequencyId = f.ReportingFrequencyId,
        ReportingFrequencyCode = null,
        DeadlineOffsetDays = f.DeadlineOffsetDays,
        AllowLateSubmission = f.AllowLateSubmission,
        RequireApproval = f.RequireApproval,
        AutoCreateReport = f.AutoCreateReport,
        TemplateFileName = f.TemplateFileName,
        HasTemplateDisplay = !string.IsNullOrEmpty(f.TemplateDisplayJson),
        Status = f.Status,
        PublishedAt = f.PublishedAt,
        PublishedBy = f.PublishedBy,
        IsActive = f.IsActive,
        CreatedAt = f.CreatedAt,
        CreatedBy = f.CreatedBy,
        UpdatedAt = f.UpdatedAt,
        UpdatedBy = f.UpdatedBy
    };
}
