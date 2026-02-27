using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

public interface IFormDefinitionService
{
    Task<Result<FormDefinitionDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    Task<Result<FormDefinitionDto?>> GetByCodeAsync(string code, CancellationToken cancellationToken = default);
    Task<Result<List<FormDefinitionDto>>> GetListAsync(string? status, string? formType, bool includeInactive, CancellationToken cancellationToken = default);
    Task<Result<PagedResultDto<FormDefinitionDto>>> GetListPagedAsync(string? status, string? formType, bool includeInactive, int pageSize, int pageNumber, CancellationToken cancellationToken = default);
    Task<Result<FormDefinitionDto>> CreateAsync(CreateFormDefinitionRequest request, int createdBy, CancellationToken cancellationToken = default);
    Task<Result<FormDefinitionDto>> UpdateAsync(int id, UpdateFormDefinitionRequest request, int updatedBy, CancellationToken cancellationToken = default);
    Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default);
    Task<Result<List<FormVersionDto>>> GetVersionsAsync(int formDefinitionId, CancellationToken cancellationToken = default);

    /// <summary>Tạo biểu mẫu từ file template Excel: trích xuất số sheet, cột, format từ template; lưu template + TemplateDisplayJson.</summary>
    Task<Result<FormDefinitionDto>> CreateFromTemplateAsync(byte[] templateFileBytes, string fileName, string formName, string? code, int createdBy, CancellationToken cancellationToken = default);
}
