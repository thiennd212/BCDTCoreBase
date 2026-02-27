using BCDT.Application.DTOs.Data;
using BCDT.Application.DTOs.Form;
using BCDT.Domain.Entities.Form;

namespace BCDT.Application.Services.Form;

/// <summary>Inject công thức Excel vào Fortune Sheet celldata theo priority: cell > row > column.
/// Placeholder: {COL} {ROW} {DATA_START_ROW} {PREV_ROW} {NEXT_ROW} {COL_X}</summary>
public interface IFormulaInjectionService
{
    /// <summary>
    /// Inject formulas vào sheet celldata.
    /// Priority: FormCellFormula (highest) > FormRow.Formula > FormColumn.Formula (lowest).
    /// Fortune Sheet cell format: { r, c, v: { f: "=...", v: null } }
    /// </summary>
    void InjectFormulas(
        WorkbookSheetFromSubmissionDto sheet,
        List<FormColumn> columns,
        List<FormRow> rows,
        List<FormRowFormulaScope> rowScopes,
        List<FormCellFormula> cellFormulas,
        ColumnLayoutResult layout,
        int dataStartRow,
        int dataEndRow);
}
