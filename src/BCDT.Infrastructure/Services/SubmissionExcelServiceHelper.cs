using BCDT.Domain.Entities.Data;

namespace BCDT.Infrastructure.Services;

/// <summary>Helper dùng chung cho ghi ReportDataRow (upload Excel và sync từ presentation).</summary>
internal static class SubmissionExcelServiceHelper
{
    public static void SetDataRowValue(ReportDataRow row, string targetName, string dataType, object? value)
    {
        if (string.IsNullOrEmpty(targetName) || value == null) return;
        switch (targetName)
        {
            case "NumericValue1": row.NumericValue1 = ToDecimal(value); break;
            case "NumericValue2": row.NumericValue2 = ToDecimal(value); break;
            case "NumericValue3": row.NumericValue3 = ToDecimal(value); break;
            case "NumericValue4": row.NumericValue4 = ToDecimal(value); break;
            case "NumericValue5": row.NumericValue5 = ToDecimal(value); break;
            case "NumericValue6": row.NumericValue6 = ToDecimal(value); break;
            case "NumericValue7": row.NumericValue7 = ToDecimal(value); break;
            case "NumericValue8": row.NumericValue8 = ToDecimal(value); break;
            case "NumericValue9": row.NumericValue9 = ToDecimal(value); break;
            case "NumericValue10": row.NumericValue10 = ToDecimal(value); break;
            case "TextValue1": row.TextValue1 = value?.ToString()?.Length > 500 ? value.ToString()![..500] : value?.ToString(); break;
            case "TextValue2": row.TextValue2 = value?.ToString()?.Length > 500 ? value.ToString()![..500] : value?.ToString(); break;
            case "TextValue3": row.TextValue3 = value?.ToString()?.Length > 500 ? value.ToString()![..500] : value?.ToString(); break;
            case "DateValue1": row.DateValue1 = ToDate(value); break;
            case "DateValue2": row.DateValue2 = ToDate(value); break;
        }
    }

    public static decimal? ToDecimal(object? value)
    {
        if (value == null) return null;
        if (value is decimal d) return d;
        if (value is double dbl) return (decimal)dbl;
        if (value is int i) return i;
        if (value is long l) return l;
        if (value is float f) return (decimal)f;
        if (decimal.TryParse(value.ToString(), out var parsed)) return parsed;
        return null;
    }

    public static DateTime? ToDate(object? value)
    {
        if (value == null) return null;
        if (value is DateTime dt) return dt;
        if (value is DateTimeOffset dto) return dto.UtcDateTime;
        if (DateTime.TryParse(value.ToString(), out var parsed)) return parsed;
        return null;
    }

    /// <summary>Đọc giá trị từ ReportDataRow theo tên cột đích (TargetColumnName).</summary>
    public static object? GetDataRowValue(ReportDataRow row, string targetName)
    {
        if (string.IsNullOrEmpty(targetName)) return null;
        return targetName switch
        {
            "NumericValue1" => row.NumericValue1,
            "NumericValue2" => row.NumericValue2,
            "NumericValue3" => row.NumericValue3,
            "NumericValue4" => row.NumericValue4,
            "NumericValue5" => row.NumericValue5,
            "NumericValue6" => row.NumericValue6,
            "NumericValue7" => row.NumericValue7,
            "NumericValue8" => row.NumericValue8,
            "NumericValue9" => row.NumericValue9,
            "NumericValue10" => row.NumericValue10,
            "TextValue1" => row.TextValue1,
            "TextValue2" => row.TextValue2,
            "TextValue3" => row.TextValue3,
            "DateValue1" => row.DateValue1,
            "DateValue2" => row.DateValue2,
            _ => null
        };
    }
}
