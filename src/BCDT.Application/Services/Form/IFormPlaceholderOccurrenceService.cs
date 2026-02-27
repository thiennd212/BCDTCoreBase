using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormPlaceholderOccurrenceService
{
    Task<Result<List<FormPlaceholderOccurrenceDto>>> GetBySheetIdAsync(int formId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<FormPlaceholderOccurrenceDto?>> GetByIdAsync(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken = default);
    Task<Result<FormPlaceholderOccurrenceDto>> CreateAsync(int formId, int sheetId, CreateFormPlaceholderOccurrenceRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormPlaceholderOccurrenceDto>> UpdateAsync(int formId, int sheetId, int occurrenceId, UpdateFormPlaceholderOccurrenceRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken = default);
}
