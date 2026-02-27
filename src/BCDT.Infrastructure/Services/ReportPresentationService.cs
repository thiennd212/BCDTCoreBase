using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.Services.Data;
using BCDT.Domain.Entities.Data;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class ReportPresentationService : IReportPresentationService
{
    private readonly AppDbContext _db;

    public ReportPresentationService(AppDbContext db) => _db = db;

    public async Task<Result<ReportPresentationDto?>> GetByIdAsync(long id, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportPresentations
            .AsNoTracking()
            .Where(p => p.Id == id)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Ok<ReportPresentationDto?>(null);
        return Result.Ok<ReportPresentationDto?>(MapToDto(entity));
    }

    public async Task<Result<ReportPresentationDto?>> GetBySubmissionIdAsync(long submissionId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportPresentations
            .AsNoTracking()
            .Where(p => p.SubmissionId == submissionId)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Ok<ReportPresentationDto?>(null);
        return Result.Ok<ReportPresentationDto?>(MapToDto(entity));
    }

    public async Task<Result<ReportPresentationDto>> CreateAsync(CreateReportPresentationRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var submissionExists = await _db.ReportSubmissions.AnyAsync(s => s.Id == request.SubmissionId && !s.IsDeleted, cancellationToken);
        if (!submissionExists)
            return Result.Fail<ReportPresentationDto>("NOT_FOUND", "Submission không tồn tại.");
        var exists = await _db.ReportPresentations.AnyAsync(p => p.SubmissionId == request.SubmissionId, cancellationToken);
        if (exists)
            return Result.Fail<ReportPresentationDto>("CONFLICT", "Presentation đã tồn tại cho submission này. Dùng PUT để cập nhật.");

        var entity = new ReportPresentation
        {
            SubmissionId = request.SubmissionId,
            WorkbookJson = request.WorkbookJson,
            WorkbookHash = request.WorkbookHash,
            FileSize = request.FileSize,
            SheetCount = request.SheetCount,
            LastModifiedAt = DateTime.UtcNow,
            LastModifiedBy = createdBy
        };
        _db.ReportPresentations.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<ReportPresentationDto>> UpdateAsync(long id, UpdateReportPresentationRequest request, int updatedBy, CancellationToken cancellationToken = default)
    {
        var entity = await _db.ReportPresentations.FirstOrDefaultAsync(p => p.Id == id, cancellationToken);
        if (entity == null)
            return Result.Fail<ReportPresentationDto>("NOT_FOUND", "Presentation không tồn tại.");
        entity.WorkbookJson = request.WorkbookJson;
        entity.WorkbookHash = request.WorkbookHash;
        entity.FileSize = request.FileSize;
        entity.SheetCount = request.SheetCount;
        entity.LastModifiedAt = DateTime.UtcNow;
        entity.LastModifiedBy = updatedBy;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<ReportPresentationDto>> UpsertBySubmissionIdAsync(long submissionId, CreateReportPresentationRequest request, int userId, CancellationToken cancellationToken = default)
    {
        var submissionExists = await _db.ReportSubmissions.AnyAsync(s => s.Id == submissionId && !s.IsDeleted, cancellationToken);
        if (!submissionExists)
            return Result.Fail<ReportPresentationDto>("NOT_FOUND", "Submission không tồn tại.");

        var existing = await _db.ReportPresentations.FirstOrDefaultAsync(p => p.SubmissionId == submissionId, cancellationToken);
        if (existing != null)
        {
            existing.WorkbookJson = request.WorkbookJson;
            existing.WorkbookHash = request.WorkbookHash;
            existing.FileSize = request.FileSize;
            existing.SheetCount = request.SheetCount;
            existing.LastModifiedAt = DateTime.UtcNow;
            existing.LastModifiedBy = userId;
            await _db.SaveChangesAsync(cancellationToken);
            return Result.Ok(MapToDto(existing));
        }

        var entity = new ReportPresentation
        {
            SubmissionId = submissionId,
            WorkbookJson = request.WorkbookJson,
            WorkbookHash = request.WorkbookHash,
            FileSize = request.FileSize,
            SheetCount = request.SheetCount,
            LastModifiedAt = DateTime.UtcNow,
            LastModifiedBy = userId
        };
        _db.ReportPresentations.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    private static ReportPresentationDto MapToDto(ReportPresentation p) => new()
    {
        Id = p.Id,
        SubmissionId = p.SubmissionId,
        WorkbookJson = p.WorkbookJson,
        WorkbookHash = p.WorkbookHash,
        FileSize = p.FileSize,
        SheetCount = p.SheetCount,
        LastModifiedAt = p.LastModifiedAt,
        LastModifiedBy = p.LastModifiedBy
    };
}
