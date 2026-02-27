using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

/// <summary>P8b: Truy vấn DataSource với bộ lọc đã resolve (whitelist cột, parameterized).</summary>
public interface IDataSourceQueryService
{
    /// <summary>Truy vấn nguồn theo filter (resolve Parameter từ context, Literal ép kiểu). Trả về danh sách hàng (column name → value). Chỉ hỗ trợ SourceType Table/View. filterCache: dùng khi caller đã batch load (Perf-8).</summary>
    Task<Result<List<Dictionary<string, object?>>>> QueryWithFilterAsync(
        int dataSourceId,
        int? filterDefinitionId,
        ParameterContext context,
        int? maxRows,
        IReadOnlyDictionary<int, FilterDefinitionDto>? filterCache = null,
        CancellationToken cancellationToken = default);
}
