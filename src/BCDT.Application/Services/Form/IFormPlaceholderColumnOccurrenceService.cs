using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormPlaceholderColumnOccurrenceService
{
    Task<Result<List<FormPlaceholderColumnOccurrenceDto>>> GetBySheetIdAsync(int formId, int sheetId, CancellationToken cancellationToken = default);
    Task<Result<FormPlaceholderColumnOccurrenceDto?>> GetByIdAsync(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken = default);
    Task<Result<FormPlaceholderColumnOccurrenceDto>> CreateAsync(int formId, int sheetId, CreateFormPlaceholderColumnOccurrenceRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormPlaceholderColumnOccurrenceDto>> UpdateAsync(int formId, int sheetId, int occurrenceId, UpdateFormPlaceholderColumnOccurrenceRequest request, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken = default);
}
