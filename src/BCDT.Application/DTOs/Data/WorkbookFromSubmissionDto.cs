namespace BCDT.Application.DTOs.Data;

/// <summary>Workbook (simple format) xây từ cấu trúc biểu mẫu và ReportDataRow theo submission/đơn vị. B12 P4: thêm ColumnHeaders (colspan), DynamicRegions.</summary>
public class WorkbookFromSubmissionDto
{
    public List<WorkbookSheetFromSubmissionDto> Sheets { get; set; } = new();
}

public class WorkbookSheetFromSubmissionDto
{
    public string Name { get; set; } = string.Empty;
    public List<Dictionary<string, object?>> Rows { get; set; } = new();
    /// <summary>Header cột theo cây (FormColumn ParentId). Colspan = số cột lá dưới cột cha; 1 = cột lá. Thứ tự ưu tiên cấu hình (R11).</summary>
    public List<WorkbookColumnHeaderDto>? ColumnHeaders { get; set; }
    /// <summary>Vùng chỉ tiêu động: dữ liệu ReportDynamicIndicator theo từng region, để FE/export điền vào placeholder.</summary>
    public List<WorkbookDynamicRegionDto>? DynamicRegions { get; set; }
    /// <summary>P8e: Vùng cột động – tại mỗi ExcelColStart sinh N cột với nhãn từ nguồn cột + bộ lọc.</summary>
    public List<WorkbookDynamicColumnRegionDto>? DynamicColumnRegions { get; set; }
    /// <summary>Fortune Sheet celldata với formula đã inject (FormulaInjectionService). Format: [{r,c,v:{f:"=...",v:null}}]. Null = không có công thức nào.</summary>
    public List<Dictionary<string, object?>>? Celldata { get; set; }
}

/// <summary>P8e: Một block cột động tại ExcelColStart; FE/export sinh N cột với header ColumnLabels.</summary>
public class WorkbookDynamicColumnRegionDto
{
    public int ExcelColStart { get; set; }
    public List<string> ColumnLabels { get; set; } = new();
}

public class WorkbookColumnHeaderDto
{
    public string ExcelColumn { get; set; } = string.Empty;
    public string ColumnName { get; set; } = string.Empty;
    /// <summary>Số cột lá dưới cột này (merge header). 1 = không merge.</summary>
    public int Colspan { get; set; } = 1;
    public int? ParentId { get; set; }
    public int DisplayOrder { get; set; }
}

public class WorkbookDynamicRegionDto
{
    public int FormDynamicRegionId { get; set; }
    public int ExcelRowStart { get; set; }
    public string ExcelColName { get; set; } = string.Empty;
    public string ExcelColValue { get; set; } = string.Empty;
    public List<WorkbookDynamicIndicatorRowDto> Rows { get; set; } = new();
}

public class WorkbookDynamicIndicatorRowDto
{
    public string IndicatorName { get; set; } = string.Empty;
    public string? IndicatorValue { get; set; }
}
