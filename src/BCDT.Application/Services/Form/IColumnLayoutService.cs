using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;

namespace BCDT.Application.Services.Form;

/// <summary>Tính layout cột tại runtime: sort FormColumn + PlaceholderColumnOccurrence theo LayoutOrder, gán ExcelColumn A/B/C...</summary>
public interface IColumnLayoutService
{
    /// <summary>
    /// Tính layout cột cho một sheet. Trả về danh sách slot đã gán ExcelColumn.
    /// Với cột tĩnh (FormColumn): 1 slot. Với PlaceholderOccurrence: N slots từ datasource.
    /// </summary>
    Task<Result<ColumnLayoutResult>> ComputeLayoutAsync(
        int sheetId,
        ParameterContext ctx,
        CancellationToken ct = default);
}
