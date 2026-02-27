using BCDT.Application.Common;
using BCDT.Domain.Entities.Form;

namespace BCDT.Application.Services.Form;

/// <summary>Resolver giá trị theo BindingType (Static, Database, API, Reference, Organization, System) – B8 mục 3.</summary>
public interface IDataBindingResolver
{
    /// <summary>Resolve giá trị cho cột theo cấu hình FormDataBinding và context.</summary>
    /// <param name="binding">Cấu hình binding (BindingType, DefaultValue, SourceTable, ...).</param>
    /// <param name="column">Cột (DataType, DefaultValue) dùng khi binding không có giá trị.</param>
    /// <param name="context">Context (UserId, OrganizationId, CurrentDate, ...).</param>
    /// <param name="cancellationToken">Cancellation token.</param>
    /// <returns>Giá trị đã resolve (string, number, DateTime, ...) hoặc null; Result Fail nếu lỗi.</returns>
    Task<Result<object?>> ResolveValueAsync(
        FormDataBinding binding,
        FormColumn column,
        ResolveContext context,
        CancellationToken cancellationToken = default);
}
