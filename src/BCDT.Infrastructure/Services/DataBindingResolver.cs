using BCDT.Application.Common;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

/// <summary>Resolver giá trị theo BindingType (B8 mục 3): Static, Database, API, Reference, Organization, System.</summary>
public class DataBindingResolver : IDataBindingResolver
{
    private static readonly HashSet<string> AllowedDbTables = new(StringComparer.OrdinalIgnoreCase)
    {
        "BCDT_Organization", "BCDT_User", "BCDT_ReportingPeriod", "BCDT_FormDefinition"
    };
    private static readonly Dictionary<string, HashSet<string>> AllowedDbColumns = new(StringComparer.OrdinalIgnoreCase)
    {
        ["BCDT_Organization"] = new(StringComparer.OrdinalIgnoreCase) { "Id", "Code", "Name", "ShortName" },
        ["BCDT_User"] = new(StringComparer.OrdinalIgnoreCase) { "Id", "Username", "FullName", "Email" },
        ["BCDT_ReportingPeriod"] = new(StringComparer.OrdinalIgnoreCase) { "Id", "Name", "PeriodStart", "PeriodEnd" },
        ["BCDT_FormDefinition"] = new(StringComparer.OrdinalIgnoreCase) { "Id", "Code", "Name" }
    };
    private static readonly HashSet<string> AllowedReferenceDisplayColumns = new(StringComparer.OrdinalIgnoreCase) { "Code", "Name", "Id" };

    private readonly AppDbContext _db;

    public DataBindingResolver(AppDbContext db) => _db = db;

    public async Task<Result<object?>> ResolveValueAsync(
        FormDataBinding binding,
        FormColumn column,
        ResolveContext context,
        CancellationToken cancellationToken = default)
    {
        if (binding == null || string.IsNullOrEmpty(binding.BindingType))
            return Result.Ok<object?>(column?.DefaultValue ?? binding?.DefaultValue ?? "");

        var type = binding.BindingType.Trim();
        return type switch
        {
            "Static" => Result.Ok<object?>(binding.DefaultValue ?? column?.DefaultValue ?? ""),
            "System" => ResolveSystem(binding, context),
            "Organization" => await ResolveOrganizationAsync(context, cancellationToken),
            "Database" => await ResolveDatabaseAsync(binding, context, cancellationToken),
            "Reference" => await ResolveReferenceAsync(binding, cancellationToken),
            "API" => await ResolveApiAsync(binding, cancellationToken),
            "Formula" => Result.Ok<object?>(binding.Formula ?? column?.Formula ?? binding.DefaultValue ?? ""),
            _ => Result.Ok<object?>(binding.DefaultValue ?? column?.DefaultValue ?? "")
        };
    }

    private static Result<object?> ResolveSystem(FormDataBinding binding, ResolveContext context)
    {
        var key = (binding.DefaultValue ?? "").Trim();
        if (string.IsNullOrEmpty(key))
            return Result.Ok<object?>(null);
        return key.ToUpperInvariant() switch
        {
            "CURRENTDATE" or "CURRENT_DATE" => Result.Ok<object?>(context.CurrentDate),
            "CURRENTUSERID" or "CURRENT_USER_ID" => Result.Ok<object?>(context.UserId),
            _ => Result.Ok<object?>(binding.DefaultValue)
        };
    }

    private async Task<Result<object?>> ResolveOrganizationAsync(ResolveContext context, CancellationToken ct)
    {
        if (context.OrganizationId == null)
            return Result.Ok<object?>(null);
        var org = await _db.Organizations
            .AsNoTracking()
            .Where(o => o.Id == context.OrganizationId.Value && !o.IsDeleted)
            .Select(o => new { o.Code, o.Name })
            .FirstOrDefaultAsync(ct);
        if (org == null)
            return Result.Ok<object?>(null);
        return Result.Ok<object?>($"{org.Code} - {org.Name}");
    }

    private async Task<Result<object?>> ResolveDatabaseAsync(FormDataBinding binding, ResolveContext context, CancellationToken ct)
    {
        var table = (binding.SourceTable ?? "").Trim();
        var col = (binding.SourceColumn ?? "").Trim();
        if (string.IsNullOrEmpty(table) || string.IsNullOrEmpty(col))
            return Result.Ok<object?>(binding.DefaultValue);
        if (!AllowedDbTables.Contains(table) || !AllowedDbColumns.TryGetValue(table, out var cols) || !cols.Contains(col))
            return Result.Ok<object?>(binding.DefaultValue);

        try
        {
#pragma warning disable EF1002 // table/col whitelisted above
            if (table == "BCDT_Organization" && context.OrganizationId.HasValue)
            {
                var val = await _db.Database.SqlQueryRaw<string>(
                    "SELECT [" + col + "] FROM [BCDT_Organization] WHERE Id = {0} AND IsDeleted = 0",
                    context.OrganizationId.Value).FirstOrDefaultAsync(ct);
                return Result.Ok<object?>(val ?? binding.DefaultValue);
            }
            var any = await _db.Database.SqlQueryRaw<string>(
                "SELECT TOP 1 [" + col + "] FROM [" + table + "]").FirstOrDefaultAsync(ct);
            return Result.Ok<object?>(any ?? binding.DefaultValue);
#pragma warning restore EF1002
        }
        catch
        {
            return Result.Ok<object?>(binding.DefaultValue);
        }
    }

    private async Task<Result<object?>> ResolveReferenceAsync(FormDataBinding binding, CancellationToken ct)
    {
        if (!binding.ReferenceEntityTypeId.HasValue)
            return Result.Ok<object?>(binding.DefaultValue);
        var displayCol = (binding.ReferenceDisplayColumn ?? "Name").Trim();
        if (!AllowedReferenceDisplayColumns.Contains(displayCol))
            displayCol = "Name";
        try
        {
#pragma warning disable EF1002 // displayCol whitelisted (Code, Name, Id)
            var value = await _db.Database.SqlQueryRaw<string>(
                "SELECT TOP 1 [" + displayCol + "] FROM [BCDT_ReferenceEntity] WHERE EntityTypeId = {0} AND IsActive = 1 AND IsDeleted = 0 ORDER BY DisplayOrder, Id",
                binding.ReferenceEntityTypeId.Value).FirstOrDefaultAsync(ct);
            return Result.Ok<object?>(value ?? binding.DefaultValue);
#pragma warning restore EF1002
        }
        catch
        {
            return Result.Ok<object?>(binding.DefaultValue);
        }
    }

    private Task<Result<object?>> ResolveApiAsync(FormDataBinding binding, CancellationToken ct)
    {
        // API binding: cần IHttpClientFactory, parse JSON path. MVP trả DefaultValue.
        return Task.FromResult(Result.Ok<object?>(binding.DefaultValue));
    }
}
