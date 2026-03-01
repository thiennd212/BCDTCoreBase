using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;
using ReportingPeriodEntity = BCDT.Domain.Entities.ReportingPeriod.ReportingPeriod;

namespace BCDT.Infrastructure.Services;

/// <summary>Tính layout cột tại runtime: interleave FormColumn + PlaceholderColumnOccurrence theo LayoutOrder, gán ExcelColumn A/B/C...
/// FormColumn tĩnh → 1 slot; PlaceholderOccurrence → N slots từ datasource (ByDataSource/ByCatalog/ByReportingPeriod/Fixed).</summary>
public class ColumnLayoutService : IColumnLayoutService
{
    private readonly AppDbContext _db;
    private readonly IDataSourceQueryService _dataSourceQuery;
    private readonly IFilterDefinitionService _filterService;

    public ColumnLayoutService(AppDbContext db, IDataSourceQueryService dataSourceQuery, IFilterDefinitionService filterService)
    {
        _db = db;
        _dataSourceQuery = dataSourceQuery;
        _filterService = filterService;
    }

    public async Task<Result<ColumnLayoutResult>> ComputeLayoutAsync(int sheetId, ParameterContext ctx, CancellationToken ct = default)
    {
        var formColumns = await _db.FormColumns
            .AsNoTracking()
            .Where(c => c.FormSheetId == sheetId)
            .OrderBy(c => c.LayoutOrder).ThenBy(c => c.DisplayOrder).ThenBy(c => c.Id)
            .ToListAsync(ct);

        var placeholderOccurrences = await _db.FormPlaceholderColumnOccurrences
            .AsNoTracking()
            .Where(o => o.FormSheetId == sheetId)
            .OrderBy(o => o.LayoutOrder).ThenBy(o => o.DisplayOrder).ThenBy(o => o.Id)
            .ToListAsync(ct);

        if (placeholderOccurrences.Count == 0)
        {
            // Fast path: no dynamic columns, use FormColumns directly
            var slots = new List<ColumnSlot>();
            for (var i = 0; i < formColumns.Count; i++)
            {
                var col = formColumns[i];
                var excelCol = !string.IsNullOrEmpty(col.ExcelColumn)
                    ? col.ExcelColumn
                    : ExcelTemplateParser.ColumnIndexToLetter(i + 1);
                slots.Add(new ColumnSlot
                {
                    ExcelColumn = excelCol,
                    FormColumnId = col.Id,
                    DynamicLabel = null,
                    IsEditable = col.IsEditable,
                    LayoutOrder = col.LayoutOrder,
                    ColumnCode = col.ColumnCode
                });
            }
            return Result.Ok(new ColumnLayoutResult { Slots = slots });
        }

        // Load column regions for placeholders
        var regionIds = placeholderOccurrences.Select(o => o.FormDynamicColumnRegionId).Distinct().ToList();
        var columnRegions = await _db.FormDynamicColumnRegions
            .AsNoTracking()
            .Where(r => regionIds.Contains(r.Id))
            .ToDictionaryAsync(r => r.Id, ct);

        // Load reporting period from context if needed
        ReportingPeriodEntity? reportingPeriod = null;
        if (ctx.ReportingPeriodId.HasValue)
            reportingPeriod = await _db.ReportingPeriods.AsNoTracking().FirstOrDefaultAsync(r => r.Id == ctx.ReportingPeriodId.Value, ct);

        // Load indicator catalogs needed for ByCatalog
        var catalogRefs = placeholderOccurrences
            .Where(o => columnRegions.TryGetValue(o.FormDynamicColumnRegionId, out var r) && r.ColumnSourceType == "ByCatalog" && r.ColumnSourceRef != null)
            .Select(o => columnRegions[o.FormDynamicColumnRegionId].ColumnSourceRef!)
            .Where(r => int.TryParse(r, out _))
            .Select(r => int.Parse(r))
            .Distinct()
            .ToList();
        var indicatorsByCatalog = new Dictionary<int, List<Indicator>>();
        if (catalogRefs.Count > 0)
        {
            var allIndicators = await _db.Indicators
                .AsNoTracking()
                .Where(i => i.IsActive && i.IndicatorCatalogId.HasValue && catalogRefs.Contains(i.IndicatorCatalogId!.Value))
                .OrderBy(i => i.IndicatorCatalogId).ThenBy(i => i.DisplayOrder).ThenBy(i => i.Id)
                .ToListAsync(ct);
            foreach (var cid in catalogRefs)
                indicatorsByCatalog[cid] = allIndicators.Where(i => i.IndicatorCatalogId == cid).ToList();
        }

        // Batch load FilterDefinition
        var filterIds = placeholderOccurrences.Where(o => o.FilterDefinitionId.HasValue).Select(o => o.FilterDefinitionId!.Value).Distinct().ToList();
        var filterById = new Dictionary<int, FilterDefinitionDto>();
        if (filterIds.Count > 0)
        {
            var filterResult = await _filterService.GetByIdsAsync(filterIds, ct);
            if (filterResult.IsSuccess && filterResult.Data != null)
                foreach (var kv in filterResult.Data) filterById[kv.Key] = kv.Value;
        }

        // Build merged list of (LayoutOrder, item)
        // item = FormColumn | FormPlaceholderColumnOccurrence
        var colByOrder = formColumns.Select(c => (order: c.LayoutOrder, col: (object)c, occ: (FormPlaceholderColumnOccurrence?)null)).ToList();
        var occByOrder = placeholderOccurrences.Select(o => (order: o.LayoutOrder, col: (object?)null, occ: (FormPlaceholderColumnOccurrence?)o)).ToList();

        // Sort: FormColumn items at same LayoutOrder come before PlaceholderOccurrence
        var merged = colByOrder
            .Select(x => (x.order, isCol: true, colObj: (object?)x.col, occObj: (FormPlaceholderColumnOccurrence?)null, displayOrder: (x.col as FormColumn)!.DisplayOrder, id: (x.col as FormColumn)!.Id))
            .Concat(occByOrder
                .Select(x => (x.order, isCol: false, colObj: (object?)null, occObj: x.occ, displayOrder: x.occ!.DisplayOrder, id: x.occ!.Id)))
            .OrderBy(x => x.order)
            .ThenBy(x => x.isCol ? 0 : 1)
            .ThenBy(x => x.displayOrder)
            .ThenBy(x => x.id)
            .ToList();

        // Expand slots
        var result = new List<ColumnSlot>();
        var slotIndex = 0;

        foreach (var item in merged)
        {
            if (item.isCol)
            {
                var col = (FormColumn)item.colObj!;
                var excelCol = ExcelTemplateParser.ColumnIndexToLetter(slotIndex + 1);
                result.Add(new ColumnSlot
                {
                    ExcelColumn = excelCol,
                    FormColumnId = col.Id,
                    DynamicLabel = null,
                    IsEditable = col.IsEditable,
                    LayoutOrder = col.LayoutOrder,
                    ColumnCode = col.ColumnCode
                });
                slotIndex++;
            }
            else
            {
                var occ = item.occObj!;
                if (!columnRegions.TryGetValue(occ.FormDynamicColumnRegionId, out var region) || !region.IsActive)
                    continue;

                var labels = ResolveColumnLabels(region, occ, ctx, reportingPeriod, indicatorsByCatalog);
                var maxCols = occ.MaxColumns ?? 0;
                if (maxCols > 0 && labels.Count > maxCols)
                    labels = labels.Take(maxCols).ToList();

                // For ByDataSource: async resolve
                if (region.ColumnSourceType == "ByDataSource" && labels.Count == 0 && int.TryParse(region.ColumnSourceRef, out var dsId))
                {
                    var queryResult = await _dataSourceQuery.QueryWithFilterAsync(dsId, occ.FilterDefinitionId, ctx, occ.MaxColumns ?? 0, filterById, ct);
                    if (queryResult.IsSuccess && queryResult.Data != null)
                    {
                        var labelCol = region.LabelColumn ?? "Name";
                        labels = queryResult.Data.Select(row => row.TryGetValue(labelCol, out var v) && v != null ? v.ToString() ?? "" : "").ToList();
                        if (maxCols > 0 && labels.Count > maxCols) labels = labels.Take(maxCols).ToList();
                    }
                }

                foreach (var label in labels)
                {
                    result.Add(new ColumnSlot
                    {
                        ExcelColumn = ExcelTemplateParser.ColumnIndexToLetter(slotIndex + 1),
                        FormColumnId = null,
                        DynamicLabel = label,
                        IsEditable = true,
                        LayoutOrder = occ.LayoutOrder,
                        ColumnCode = null
                    });
                    slotIndex++;
                }
            }
        }

        return Result.Ok(new ColumnLayoutResult { Slots = result });
    }

    private static List<string> ResolveColumnLabels(
        FormDynamicColumnRegion region,
        FormPlaceholderColumnOccurrence occ,
        ParameterContext ctx,
        ReportingPeriodEntity? reportingPeriod,
        Dictionary<int, List<Indicator>> indicatorsByCatalog)
    {
        var labels = new List<string>();
        switch (region.ColumnSourceType)
        {
            case "ByReportingPeriod":
                if (reportingPeriod != null)
                {
                    var start = reportingPeriod.StartDate;
                    var end = reportingPeriod.EndDate;
                    for (var d = new DateTime(start.Year, start.Month, 1); d <= end; d = d.AddMonths(1))
                    {
                        if (d < start) continue;
                        labels.Add(string.IsNullOrEmpty(region.LabelColumn) ? $"T{labels.Count + 1}" : $"Tháng {d.Month}/{d.Year}");
                    }
                    if (labels.Count == 0 && !string.IsNullOrEmpty(reportingPeriod.PeriodName))
                        labels.Add(reportingPeriod.PeriodName);
                }
                break;
            case "ByCatalog":
                if (int.TryParse(region.ColumnSourceRef, out var catalogId) && indicatorsByCatalog.TryGetValue(catalogId, out var indicators))
                {
                    var labelCol = region.LabelColumn;
                    labels = indicators
                        .OrderBy(i => i.DisplayOrder).ThenBy(i => i.Id)
                        .Select(i => string.IsNullOrEmpty(labelCol) ? i.Name : (labelCol.Equals("Code", StringComparison.OrdinalIgnoreCase) ? i.Code ?? i.Name : i.Name))
                        .ToList();
                }
                break;
            case "Fixed":
                if (!string.IsNullOrWhiteSpace(region.ColumnSourceRef))
                    labels = region.ColumnSourceRef.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(s => s.Trim()).ToList();
                break;
            // ByDataSource is handled async in the caller
        }
        return labels;
    }
}
