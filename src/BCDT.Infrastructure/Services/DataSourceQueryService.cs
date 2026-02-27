using System.Data;
using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

/// <summary>P8b: Truy vấn DataSource với filter đã resolve (whitelist cột, parameterized).</summary>
public class DataSourceQueryService : IDataSourceQueryService
{
    private readonly AppDbContext _db;
    private readonly IFilterDefinitionService _filterService;
    private readonly IDataSourceService _dataSourceService;

    public DataSourceQueryService(AppDbContext db, IFilterDefinitionService filterService, IDataSourceService dataSourceService)
    {
        _db = db;
        _filterService = filterService;
        _dataSourceService = dataSourceService;
    }

    public async Task<Result<List<Dictionary<string, object?>>>> QueryWithFilterAsync(
        int dataSourceId,
        int? filterDefinitionId,
        ParameterContext context,
        int? maxRows,
        IReadOnlyDictionary<int, FilterDefinitionDto>? filterCache = null,
        CancellationToken cancellationToken = default)
    {
        var dsResult = await _dataSourceService.GetByIdAsync(dataSourceId, cancellationToken);
        if (!dsResult.IsSuccess || dsResult.Data == null)
            return Result.Fail<List<Dictionary<string, object?>>>("NOT_FOUND", "Nguồn dữ liệu không tồn tại.");
        var ds = dsResult.Data;
        if (ds.SourceType != "Table" && ds.SourceType != "View")
            return Result.Fail<List<Dictionary<string, object?>>>("VALIDATION_FAILED", "Chỉ hỗ trợ nguồn kiểu Table/View.");

        var tableName = (ds.SourceRef ?? "").Trim();
        if (string.IsNullOrEmpty(tableName) || !System.Text.RegularExpressions.Regex.IsMatch(tableName, @"^[a-zA-Z0-9_]+$"))
            return Result.Fail<List<Dictionary<string, object?>>>("VALIDATION_FAILED", "Tên bảng/view không hợp lệ.");

        var columnsResult = await _dataSourceService.GetColumnsAsync(dataSourceId, cancellationToken);
        if (!columnsResult.IsSuccess || columnsResult.Data == null)
            return Result.Fail<List<Dictionary<string, object?>>>("VALIDATION_FAILED", "Không lấy được danh sách cột.");
        var allowedColumns = new HashSet<string>(columnsResult.Data.Select(c => c.Name.Trim()), StringComparer.OrdinalIgnoreCase);

        var whereClause = "";
        var parameters = new List<SqlParameter>();
        if (filterDefinitionId.HasValue && filterDefinitionId.Value > 0)
        {
            FilterDefinitionDto? filter = null;
            if (filterCache != null && filterCache.TryGetValue(filterDefinitionId.Value, out var cached))
                filter = cached;
            if (filter == null)
            {
                var filterResult = await _filterService.GetByIdAsync(filterDefinitionId.Value, cancellationToken);
                if (!filterResult.IsSuccess || filterResult.Data == null)
                    return Result.Fail<List<Dictionary<string, object?>>>("NOT_FOUND", "Bộ lọc không tồn tại.");
                filter = filterResult.Data;
            }
            var resolved = ResolveConditions(filter.Conditions, context, allowedColumns);
            if (resolved.Count == 0)
                whereClause = "1=1";
            else
            {
                var op = filter.LogicalOperator == "OR" ? " OR " : " AND ";
                var parts = new List<string>();
                var idx = 0;
                foreach (var (field, sqlOp, value) in resolved)
                {
                    var paramName = $"@p{idx}";
                    parts.Add($"[{field}] {sqlOp} {paramName}");
                    parameters.Add(new SqlParameter(paramName, value ?? DBNull.Value));
                    idx++;
                }
                whereClause = string.Join(op, parts);
            }
        }
        else
            whereClause = "1=1";

        var top = maxRows.HasValue && maxRows.Value > 0 ? $"TOP ({Math.Min(maxRows.Value, 10000)}) " : "";
        var sql = $"SELECT {top}* FROM [dbo].[{tableName}] WHERE {whereClause}";

        try
        {
            var rows = new List<Dictionary<string, object?>>();
            await using var conn = _db.Database.GetDbConnection();
            await conn.OpenAsync(cancellationToken);
            await using var cmd = conn.CreateCommand();
            cmd.CommandText = sql;
            foreach (var p in parameters)
                cmd.Parameters.Add(p);
            await using var reader = await cmd.ExecuteReaderAsync(cancellationToken);
            while (await reader.ReadAsync(cancellationToken))
            {
                var row = new Dictionary<string, object?>(StringComparer.OrdinalIgnoreCase);
                for (var i = 0; i < reader.FieldCount; i++)
                {
                    var name = reader.GetName(i);
                    var value = reader.IsDBNull(i) ? null : reader.GetValue(i);
                    row[name] = value;
                }
                rows.Add(row);
            }
            return Result.Ok(rows);
        }
        catch (Exception ex)
        {
            return Result.Fail<List<Dictionary<string, object?>>>("QUERY_FAILED", $"Truy vấn thất bại: {ex.Message}");
        }
    }

    /// <summary>Resolve điều kiện: Parameter → giá trị từ context; Literal → ép kiểu. Chỉ giữ điều kiện có Field trong whitelist. Trả về (field, sqlOperator, value).</summary>
    private static List<(string Field, string SqlOperator, object? Value)> ResolveConditions(
        List<FilterConditionDto> conditions,
        ParameterContext context,
        HashSet<string> allowedColumns)
    {
        var result = new List<(string, string, object?)>();
        foreach (var c in conditions.OrderBy(x => x.ConditionOrder))
        {
            var field = (c.Field ?? "").Trim();
            if (string.IsNullOrEmpty(field) || !allowedColumns.Contains(field))
                continue;
            var op = MapOperator(c.Operator);
            if (op == null) continue;
            object? value = null;
            if (c.ValueType == "Parameter")
            {
                value = GetParameterValue(c.Value, context);
                if (value == null && c.Operator != "IsNull" && c.Operator != "IsNotNull")
                    continue;
            }
            else
                value = ParseLiteral(c.Value, c.DataType);
            result.Add((field, op, value));
        }
        return result;
    }

    private static string? MapOperator(string op)
    {
        return (op ?? "").ToUpperInvariant() switch
        {
            "EQ" => "=",
            "NE" => "<>",
            "LT" => "<",
            "LE" => "<=",
            "GT" => ">",
            "GE" => ">=",
            _ => null
        };
    }

    private static object? GetParameterValue(string? paramName, ParameterContext context)
    {
        var name = (paramName ?? "").Trim();
        return name.ToUpperInvariant() switch
        {
            "REPORTDATE" => context.ReportDate,
            "ORGANIZATIONID" => context.OrganizationId,
            "SUBMISSIONID" => context.SubmissionId,
            "REPORTINGPERIODID" => context.ReportingPeriodId,
            "CURRENTDATE" => context.CurrentDate,
            "USERID" => context.UserId,
            "CATALOGID" => context.CatalogId,
            _ => null
        };
    }

    private static object? ParseLiteral(string? value, string? dataType)
    {
        if (string.IsNullOrEmpty(value)) return null;
        var dt = (dataType ?? "Text").ToUpperInvariant();
        return dt switch
        {
            "NUMBER" => long.TryParse(value, out var n) ? n : (double.TryParse(value, out var d) ? d : (object?)value),
            "DATE" => DateTime.TryParse(value, out var dtVal) ? dtVal : null,
            "BOOLEAN" => value == "1" || value.Equals("true", StringComparison.OrdinalIgnoreCase),
            _ => value
        };
    }
}
