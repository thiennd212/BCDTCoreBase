using BCDT.Application.Common;

namespace BCDT.Application.Services.Form;

/// <summary>Sinh file Excel template từ Form Definition (sheets + columns, optional data binding).</summary>
public interface IFormTemplateService
{
    /// <summary>Sinh workbook Excel từ form: mỗi FormSheet → worksheet, FormColumn → cột (header row 1). Khi fillBinding=true dùng IDataBindingResolver theo BindingType.</summary>
    /// <param name="formId">FormDefinition Id.</param>
    /// <param name="fillBinding">Nếu true, điền giá trị từ Data Binding (Static, Organization, System, Database, Reference, …) vào row 2.</param>
    /// <param name="context">Context cho resolver (UserId, OrganizationId, ReportingPeriodId, CurrentDate). Optional.</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Byte array của file .xlsx hoặc Result Fail nếu form không tồn tại.</returns>
    Task<Result<byte[]>> GetTemplateAsync(
        int formId,
        bool fillBinding,
        ResolveContext? context = null,
        CancellationToken cancellationToken = default);

    /// <summary>Upload file Excel template, lưu vào FormDefinition và parse thành TemplateDisplayJson (Fortune-sheet format).</summary>
    Task<Result<object>> UploadTemplateAsync(int formId, Stream xlsxStream, string fileName, CancellationToken cancellationToken = default);

    /// <summary>Lấy TemplateDisplayJson (JSON mảng Sheet Fortune-sheet) để FE dùng làm base hiển thị nhập liệu. Trả về null nếu chưa có template display.</summary>
    Task<Result<string?>> GetTemplateDisplayJsonAsync(int formId, CancellationToken cancellationToken = default);
}
