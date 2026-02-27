using System.Text;
using BCDT.Application.Common;
using BCDT.Application.Services.Data;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;

namespace BCDT.Infrastructure.Services.Data;

public class SubmissionPdfService : ISubmissionPdfService
{
    private readonly AppDbContext _db;

    public SubmissionPdfService(AppDbContext db) => _db = db;

    static SubmissionPdfService()
    {
        QuestPDF.Settings.License = LicenseType.Community;
    }

    public async Task<Result<byte[]?>> GeneratePdfAsync(long submissionId, CancellationToken cancellationToken = default)
    {
        var submission = await _db.ReportSubmissions
            .AsNoTracking()
            .Where(s => s.Id == submissionId && !s.IsDeleted)
            .FirstOrDefaultAsync(cancellationToken);
        if (submission == null)
            return Result.Fail<byte[]?>("NOT_FOUND", "Submission không tồn tại.");

        var presentation = await _db.ReportPresentations
            .AsNoTracking()
            .Where(p => p.SubmissionId == submissionId)
            .FirstOrDefaultAsync(cancellationToken);

        var doc = Document.Create(container =>
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(40);
                page.DefaultTextStyle(x => x.FontSize(10));

                page.Header().Text("Báo cáo điện tử - Submission").Bold().FontSize(14);
                page.Content().Column(column =>
                {
                    column.Spacing(8);
                    column.Item().Text($"Mã submission: {submission.Id}");
                    column.Item().Text($"FormDefinitionId: {submission.FormDefinitionId}");
                    column.Item().Text($"OrganizationId: {submission.OrganizationId}");
                    column.Item().Text($"ReportingPeriodId: {submission.ReportingPeriodId}");
                    column.Item().Text($"Trạng thái: {submission.Status}");
                    column.Item().Text($"Ngày tạo: {submission.CreatedAt:yyyy-MM-dd HH:mm}");
                    if (submission.SubmittedAt.HasValue)
                        column.Item().Text($"Ngày nộp: {submission.SubmittedAt:yyyy-MM-dd HH:mm}");
                    if (presentation != null)
                    {
                        column.Item().PaddingTop(10).Text($"Đã có dữ liệu presentation (SheetCount: {presentation.SheetCount}, FileSize: {presentation.FileSize} bytes).").Italic();
                    }
                });
                page.Footer().AlignCenter().Text(x =>
                {
                    x.CurrentPageNumber();
                    x.Span(" / ");
                    x.TotalPages();
                });
            });
        });

        var bytes = doc.GeneratePdf();
        return Result.Ok<byte[]?>(bytes);
    }
}
