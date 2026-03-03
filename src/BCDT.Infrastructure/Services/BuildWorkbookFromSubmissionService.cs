using BCDT.Application.Common;
using BCDT.Application.DTOs.Data;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Data;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Data;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using ReportingPeriodEntity = BCDT.Domain.Entities.ReportingPeriod.ReportingPeriod;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

/// <summary>Xây workbook từ cấu trúc biểu mẫu và ReportDataRow theo submission/đơn vị. B12 P4: ColumnHeaders (colspan), DynamicRegions. P4 mở rộng: vùng có IndicatorCatalogId → cây Indicator cắt theo IndicatorExpandDepth, pre-fill/merge ReportDynamicIndicator. P8b: FormPlaceholderOccurrence → resolve filter, query DataSource → N hàng. v29: FormulaInjection.</summary>
public class BuildWorkbookFromSubmissionService : IBuildWorkbookFromSubmissionService
{
    private readonly AppDbContext _db;
    private readonly IDataSourceQueryService _dataSourceQuery;
    private readonly IDataSourceService _dataSourceService;
    private readonly IFilterDefinitionService _filterService;
    private readonly IFormulaInjectionService _formulaInjection;
    private readonly IColumnLayoutService _columnLayout;

    public BuildWorkbookFromSubmissionService(AppDbContext db, IDataSourceQueryService dataSourceQuery, IDataSourceService dataSourceService, IFilterDefinitionService filterService, IFormulaInjectionService formulaInjection, IColumnLayoutService columnLayout)
    {
        _db = db;
        _dataSourceQuery = dataSourceQuery;
        _dataSourceService = dataSourceService;
        _filterService = filterService;
        _formulaInjection = formulaInjection;
        _columnLayout = columnLayout;
    }

    public async Task<Result<WorkbookFromSubmissionDto>> BuildAsync(long submissionId, CancellationToken cancellationToken = default)
    {
        var submission = await _db.ReportSubmissions
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == submissionId && !s.IsDeleted, cancellationToken);
        if (submission == null)
            return Result.Fail<WorkbookFromSubmissionDto>("NOT_FOUND", "Submission không tồn tại.");

        var formId = submission.FormDefinitionId;
        var sheets = await _db.FormSheets
            .AsNoTracking()
            .Where(s => s.FormDefinitionId == formId)
            .OrderBy(s => s.DisplayOrder).ThenBy(s => s.SheetIndex)
            .ToListAsync(cancellationToken);
        if (sheets.Count == 0)
            return Result.Fail<WorkbookFromSubmissionDto>("VALIDATION_FAILED", "Biểu mẫu chưa có sheet nào.");

        var sheetIds = sheets.Select(s => s.Id).ToList();
        var columns = await _db.FormColumns
            .AsNoTracking()
            .Where(c => sheetIds.Contains(c.FormSheetId))
            .OrderBy(c => c.FormSheetId).ThenBy(c => c.DisplayOrder).ThenBy(c => c.Id)
            .ToListAsync(cancellationToken);
        var columnIds = columns.Select(c => c.Id).ToList();
        var mappings = await _db.FormColumnMappings
            .AsNoTracking()
            .Where(m => columnIds.Contains(m.FormColumnId))
            .ToListAsync(cancellationToken);
        var mappingByColumnId = mappings.ToDictionary(m => m.FormColumnId);

        var dataRows = await _db.ReportDataRows
            .AsNoTracking()
            .Where(r => r.SubmissionId == submissionId)
            .OrderBy(r => r.SheetIndex).ThenBy(r => r.RowIndex)
            .ToListAsync(cancellationToken);

        var dynamicRegions = await _db.FormDynamicRegions
            .AsNoTracking()
            .Where(r => sheetIds.Contains(r.FormSheetId))
            .OrderBy(r => r.FormSheetId).ThenBy(r => r.DisplayOrder).ThenBy(r => r.Id)
            .ToListAsync(cancellationToken);
        var regionIds = dynamicRegions.Select(r => r.Id).ToList();
        var dynamicIndicatorRows = regionIds.Count > 0
            ? await _db.ReportDynamicIndicators
                .AsNoTracking()
                .Where(d => d.SubmissionId == submissionId && regionIds.Contains(d.FormDynamicRegionId))
                .OrderBy(d => d.FormDynamicRegionId).ThenBy(d => d.RowOrder)
                .ToListAsync(cancellationToken)
            : new List<ReportDynamicIndicator>();

        // B12 P4 mở rộng: một query indicators theo tất cả catalog của các vùng (tránh N+1)
        var catalogIds = dynamicRegions
            .Where(r => r.IndicatorCatalogId.HasValue)
            .Select(r => r.IndicatorCatalogId!.Value)
            .Distinct()
            .ToList();
        var indicatorsByCatalog = new Dictionary<int, List<Indicator>>();
        if (catalogIds.Count > 0)
        {
            var allIndicators = await _db.Indicators
                .AsNoTracking()
                .Where(i => i.IsActive && i.IndicatorCatalogId.HasValue && catalogIds.Contains(i.IndicatorCatalogId!.Value))
                .OrderBy(i => i.IndicatorCatalogId)
                .ThenBy(i => i.DisplayOrder)
                .ThenBy(i => i.Id)
                .ToListAsync(cancellationToken);
            foreach (var cid in catalogIds)
                indicatorsByCatalog[cid] = allIndicators.Where(i => i.IndicatorCatalogId == cid).ToList();
        }

        // P8b: placeholder occurrences và parameter context
        var placeholderOccurrences = await _db.FormPlaceholderOccurrences
            .AsNoTracking()
            .Where(o => sheetIds.Contains(o.FormSheetId))
            .OrderBy(o => o.FormSheetId).ThenBy(o => o.DisplayOrder).ThenBy(o => o.Id)
            .ToListAsync(cancellationToken);
        // P8e: placeholder cột
        var placeholderColumnOccurrences = await _db.FormPlaceholderColumnOccurrences
            .AsNoTracking()
            .Where(o => sheetIds.Contains(o.FormSheetId))
            .OrderBy(o => o.FormSheetId).ThenBy(o => o.DisplayOrder).ThenBy(o => o.Id)
            .ToListAsync(cancellationToken);
        var columnRegionIds = placeholderColumnOccurrences.Select(o => o.FormDynamicColumnRegionId).Distinct().ToList();
        var columnRegions = columnRegionIds.Count > 0
            ? await _db.FormDynamicColumnRegions
                .AsNoTracking()
                .Where(r => columnRegionIds.Contains(r.Id))
                .ToDictionaryAsync(r => r.Id, cancellationToken)
            : new Dictionary<int, FormDynamicColumnRegion>();
        var reportingPeriod = submission.ReportingPeriodId != 0
            ? await _db.ReportingPeriods.AsNoTracking().FirstOrDefaultAsync(r => r.Id == submission.ReportingPeriodId, cancellationToken)
            : null;
        var context = new ParameterContext
        {
            ReportDate = reportingPeriod?.EndDate,
            OrganizationId = submission.OrganizationId,
            SubmissionId = submission.Id,
            ReportingPeriodId = submission.ReportingPeriodId,
            CurrentDate = DateTime.UtcNow
        };

        // W16: Batch load DataSource metadata for all placeholder occurrences (tránh N+1 GetByIdAsync trong vòng lặp)
        var dataSourceIds = placeholderOccurrences.Where(o => o.DataSourceId.HasValue).Select(o => o.DataSourceId!.Value).Distinct().ToList();
        var dataSourceById = new Dictionary<int, DataSourceDto?>();
        foreach (var dsId in dataSourceIds)
        {
            var dsResult = await _dataSourceService.GetByIdAsync(dsId, cancellationToken);
            dataSourceById[dsId] = dsResult.Data;
        }

        // Perf-8: Batch load FilterDefinition + Condition theo list id (1–2 query), dùng trong vòng lặp thay vì GetByIdAsync mỗi lần
        var filterDefinitionIds = placeholderOccurrences.Where(o => o.FilterDefinitionId.HasValue).Select(o => o.FilterDefinitionId!.Value)
            .Concat(placeholderColumnOccurrences.Where(o => o.FilterDefinitionId.HasValue).Select(o => o.FilterDefinitionId!.Value))
            .Distinct().ToList();
        var filterById = new Dictionary<int, FilterDefinitionDto>();
        if (filterDefinitionIds.Count > 0)
        {
            var filterResult = await _filterService.GetByIdsAsync(filterDefinitionIds, cancellationToken);
            if (filterResult.IsSuccess && filterResult.Data != null)
            {
                foreach (var kv in filterResult.Data)
                    filterById[kv.Key] = kv.Value;
            }
        }

        var result = new WorkbookFromSubmissionDto();
        foreach (var formSheet in sheets)
        {
            var sheetColumns = columns.Where(c => c.FormSheetId == formSheet.Id).ToList();
            var colsWithMapping = sheetColumns
                .Where(c => mappingByColumnId.ContainsKey(c.Id))
                .OrderBy(c => c.DisplayOrder)
                .ToList();
            var emptyRow = new Dictionary<string, object?>();
            foreach (var col in colsWithMapping)
                emptyRow[col.ExcelColumn!] = null;

            var sheetDataRows = dataRows.Where(r => r.SheetIndex == formSheet.SheetIndex).ToList();
            var rows = new List<Dictionary<string, object?>>();
            if (sheetDataRows.Count > 0)
            {
                foreach (var dataRow in sheetDataRows)
                {
                    var row = new Dictionary<string, object?>();
                    foreach (var col in colsWithMapping)
                    {
                        var mapping = mappingByColumnId[col.Id];
                        var raw = SubmissionExcelServiceHelper.GetDataRowValue(dataRow, mapping.TargetColumnName);
                        row[col.ExcelColumn!] = ToJsonFriendly(raw);
                    }
                    rows.Add(row);
                }
            }
            else
            {
                rows.Add(new Dictionary<string, object?>(emptyRow));
            }

            var columnHeaders = BuildColumnHeaders(sheetColumns);
            var sheetDynamicRegions = dynamicRegions.Where(r => r.FormSheetId == formSheet.Id).ToList();
            var sheetOccurrences = placeholderOccurrences.Where(o => o.FormSheetId == formSheet.Id).OrderBy(o => o.DisplayOrder).ThenBy(o => o.Id).ToList();
            var dynamicRegionDtos = new List<WorkbookDynamicRegionDto>();

            if (sheetOccurrences.Count > 0)
            {
                foreach (var occ in sheetOccurrences)
                {
                    var region = sheetDynamicRegions.FirstOrDefault(r => r.Id == occ.FormDynamicRegionId);
                    if (region == null) continue;
                    List<WorkbookDynamicIndicatorRowDto> regionRows;
                    if (occ.DataSourceId.HasValue)
                    {
                        var queryResult = await _dataSourceQuery.QueryWithFilterAsync(occ.DataSourceId.Value, occ.FilterDefinitionId, context, occ.MaxRows, filterById, cancellationToken);
                        if (!queryResult.IsSuccess || queryResult.Data == null)
                            regionRows = new List<WorkbookDynamicIndicatorRowDto>();
                        else
                        {
                            dataSourceById.TryGetValue(occ.DataSourceId.Value, out var dsMeta);
                            var displayCol = dsMeta?.DisplayColumn ?? "Name";
                            var valueCol = dsMeta?.ValueColumn;
                            regionRows = queryResult.Data.Select(row => new WorkbookDynamicIndicatorRowDto
                            {
                                IndicatorName = row.TryGetValue(displayCol, out var n) && n != null ? n.ToString() ?? "" : "",
                                IndicatorValue = valueCol != null && row.TryGetValue(valueCol, out var v) ? v?.ToString() : null
                            }).ToList();
                        }
                    }
                    else
                        regionRows = BuildDynamicRegionRows(region, dynamicIndicatorRows, indicatorsByCatalog);
                    dynamicRegionDtos.Add(new WorkbookDynamicRegionDto
                    {
                        FormDynamicRegionId = region.Id,
                        ExcelRowStart = occ.ExcelRowStart,
                        ExcelColName = region.ExcelColName,
                        ExcelColValue = region.ExcelColValue,
                        Rows = regionRows
                    });
                }
                var occurrenceRegionIds = sheetOccurrences.Select(o => o.FormDynamicRegionId).ToHashSet();
                foreach (var region in sheetDynamicRegions.Where(r => !occurrenceRegionIds.Contains(r.Id)))
                {
                    var regionRows = BuildDynamicRegionRows(region, dynamicIndicatorRows, indicatorsByCatalog);
                    dynamicRegionDtos.Add(new WorkbookDynamicRegionDto
                    {
                        FormDynamicRegionId = region.Id,
                        ExcelRowStart = region.ExcelRowStart,
                        ExcelColName = region.ExcelColName,
                        ExcelColValue = region.ExcelColValue,
                        Rows = regionRows
                    });
                }
                dynamicRegionDtos = dynamicRegionDtos.OrderBy(d => d.ExcelRowStart).ToList();
            }
            else
            {
                foreach (var region in sheetDynamicRegions)
                {
                    var regionRows = BuildDynamicRegionRows(region, dynamicIndicatorRows, indicatorsByCatalog);
                    dynamicRegionDtos.Add(new WorkbookDynamicRegionDto
                    {
                        FormDynamicRegionId = region.Id,
                        ExcelRowStart = region.ExcelRowStart,
                        ExcelColName = region.ExcelColName,
                        ExcelColValue = region.ExcelColValue,
                        Rows = regionRows
                    });
                }
            }

            // P8e: vùng cột động – mỗi occurrence sinh N cột tại ExcelColStart
            // Perf-12: Batch resolve cột động – gom nhóm theo (DataSourceId, FilterDefinitionId), gọi QueryWithFilterAsync một lần mỗi cặp
            var sheetColOccurrences = placeholderColumnOccurrences.Where(o => o.FormSheetId == formSheet.Id).OrderBy(o => o.DisplayOrder).ThenBy(o => o.Id).ToList();
            var columnDataSourceCache = new Dictionary<(int DataSourceId, int? FilterDefinitionId), List<Dictionary<string, object?>>>();
            foreach (var colOcc in sheetColOccurrences)
            {
                if (!columnRegions.TryGetValue(colOcc.FormDynamicColumnRegionId, out var colRegion) || !colRegion.IsActive)
                    continue;
                if (colRegion.ColumnSourceType == "ByDataSource" && int.TryParse(colRegion.ColumnSourceRef, out var dsId))
                {
                    var key = (dsId, colOcc.FilterDefinitionId);
                    if (!columnDataSourceCache.ContainsKey(key))
                    {
                        var maxCols = sheetColOccurrences
                            .Where(o => columnRegions.TryGetValue(o.FormDynamicColumnRegionId, out var r) && r?.ColumnSourceType == "ByDataSource" && r.ColumnSourceRef == colRegion.ColumnSourceRef && o.FilterDefinitionId == colOcc.FilterDefinitionId)
                            .Select(o => o.MaxColumns ?? 0)
                            .DefaultIfEmpty(0)
                            .Max();
                        var queryResult = await _dataSourceQuery.QueryWithFilterAsync(dsId, colOcc.FilterDefinitionId, context, maxCols > 0 ? maxCols : 1000, filterById, cancellationToken);
                        columnDataSourceCache[key] = queryResult.IsSuccess && queryResult.Data != null ? queryResult.Data : new List<Dictionary<string, object?>>();
                    }
                }
            }
            var dynamicColumnRegionDtos = new List<WorkbookDynamicColumnRegionDto>();
            foreach (var colOcc in sheetColOccurrences)
            {
                if (!columnRegions.TryGetValue(colOcc.FormDynamicColumnRegionId, out var colRegion) || !colRegion.IsActive)
                    continue;
                var labels = await ResolveColumnLabelsAsync(colRegion, colOcc, context, reportingPeriod, indicatorsByCatalog, filterById, columnDataSourceCache, cancellationToken);
                var maxCols = colOcc.MaxColumns ?? 0;
                if (maxCols > 0 && labels.Count > maxCols)
                    labels = labels.Take(maxCols).ToList();
                dynamicColumnRegionDtos.Add(new WorkbookDynamicColumnRegionDto
                {
                    ExcelColStart = colOcc.ExcelColStart,
                    ColumnLabels = labels
                });
            }

            var sheetDto = new WorkbookSheetFromSubmissionDto
            {
                Name = formSheet.SheetName,
                Rows = rows,
                ColumnHeaders = columnHeaders.Count > 0 ? columnHeaders : null,
                DynamicRegions = dynamicRegionDtos.Count > 0 ? dynamicRegionDtos : null,
                DynamicColumnRegions = dynamicColumnRegionDtos.Count > 0 ? dynamicColumnRegionDtos : null
            };

            // v29: Inject formulas via FormulaInjectionService
            var hasColumnFormula = sheetColumns.Any(c => !string.IsNullOrWhiteSpace(c.Formula));
            var formRows = await _db.FormRows.AsNoTracking().Where(r => r.FormSheetId == formSheet.Id).ToListAsync(cancellationToken);
            var hasRowFormula = formRows.Any(r => !string.IsNullOrWhiteSpace(r.Formula));
            var rowIds = formRows.Select(r => r.Id).ToList();
            var rowFormulaScopesForSheet = rowIds.Count > 0
                ? await _db.FormRowFormulaScopes.AsNoTracking().Where(s => rowIds.Contains(s.FormRowId)).ToListAsync(cancellationToken)
                : new List<FormRowFormulaScope>();
            var cellFormulasForSheet = await _db.FormCellFormulas.AsNoTracking().Where(f => f.FormSheetId == formSheet.Id).ToListAsync(cancellationToken);

            if (hasColumnFormula || hasRowFormula || cellFormulasForSheet.Count > 0)
            {
                var layoutResult = await _columnLayout.ComputeLayoutAsync(formSheet.Id, context, cancellationToken);
                if (layoutResult.IsSuccess && layoutResult.Data != null)
                {
                    var headerRowCount = GetHeaderRowCountFromColumns(sheetColumns);
                    var dataEndRow = headerRowCount + (rows.Count > 0 ? rows.Count - 1 : 0);
                    _formulaInjection.InjectFormulas(sheetDto, sheetColumns, formRows, rowFormulaScopesForSheet, cellFormulasForSheet, layoutResult.Data, headerRowCount, dataEndRow);
                }
            }

            result.Sheets.Add(sheetDto);
        }

        return Result.Ok(result);
    }

    /// <summary>Thứ tự ưu tiên cấu hình (R11): cột theo cây FormColumn (DisplayOrder, ParentId). Colspan = số cột lá dưới cột cha.</summary>
    private static List<WorkbookColumnHeaderDto> BuildColumnHeaders(List<FormColumn> sheetColumns)
    {
        if (sheetColumns.Count == 0) return new List<WorkbookColumnHeaderDto>();
        var byId = sheetColumns.ToDictionary(c => c.Id);
        var leafCountById = new Dictionary<int, int>();
        foreach (var c in sheetColumns)
        {
            var count = GetLeafCount(c.Id, byId);
            leafCountById[c.Id] = count;
        }
        var ordered = OrderColumnsByTree(sheetColumns, null);
        return ordered.Select(c => new WorkbookColumnHeaderDto
        {
            ExcelColumn = c.ExcelColumn!,
            ColumnName = c.ColumnName,
            Colspan = leafCountById.TryGetValue(c.Id, out var n) ? n : 1,
            ParentId = c.ParentId,
            DisplayOrder = c.DisplayOrder
        }).ToList();
    }

    private static int GetLeafCount(int columnId, Dictionary<int, FormColumn> byId)
    {
        var children = byId.Values.Where(c => c.ParentId == columnId).ToList();
        if (children.Count == 0) return 1;
        var sum = 0;
        foreach (var ch in children)
            sum += GetLeafCount(ch.Id, byId);
        return sum;
    }

    private static List<FormColumn> OrderColumnsByTree(List<FormColumn> sheetColumns, int? parentId)
    {
        var children = sheetColumns.Where(c => c.ParentId == parentId).OrderBy(c => c.DisplayOrder).ThenBy(c => c.Id).ToList();
        var result = new List<FormColumn>();
        foreach (var ch in children)
        {
            result.Add(ch);
            result.AddRange(OrderColumnsByTree(sheetColumns, ch.Id));
        }
        return result;
    }

    /// <summary>B12 P4 mở rộng: sinh danh sách dòng cho vùng. Có IndicatorCatalogId → cây Indicator cắt theo depth, pre-fill hoặc merge với ReportDynamicIndicator.</summary>
    private static List<WorkbookDynamicIndicatorRowDto> BuildDynamicRegionRows(
        FormDynamicRegion region,
        List<ReportDynamicIndicator> dynamicIndicatorRows,
        Dictionary<int, List<Indicator>> indicatorsByCatalog)
    {
        var existing = dynamicIndicatorRows
            .Where(d => d.FormDynamicRegionId == region.Id)
            .OrderBy(d => d.RowOrder)
            .ToList();

        if (!region.IndicatorCatalogId.HasValue || !indicatorsByCatalog.TryGetValue(region.IndicatorCatalogId.Value, out var catalogIndicators) || catalogIndicators.Count == 0)
        {
            // Vùng không gắn catalog hoặc catalog rỗng: giữ hàng từ ReportDynamicIndicator
            return existing.Select(d => new WorkbookDynamicIndicatorRowDto
            {
                IndicatorName = d.IndicatorName,
                IndicatorValue = d.IndicatorValue
            }).ToList();
        }

        // Depth: 1 = chỉ gốc, 2 = gốc+con, 3 = gốc+con+cháu, 0 = không giới hạn
        var maxDepth = region.IndicatorExpandDepth <= 0 ? int.MaxValue : region.IndicatorExpandDepth;
        var catalogOrdered = FlattenIndicatorTreeByDepth(catalogIndicators, maxDepth);

        if (existing.Count == 0)
        {
            // Pre-fill: toàn bộ dòng từ catalog, giá trị rỗng
            return catalogOrdered.Select(ind => new WorkbookDynamicIndicatorRowDto
            {
                IndicatorName = ind.Name,
                IndicatorValue = null
            }).ToList();
        }

        // Merge: thứ tự theo catalog; lấy dữ liệu đã lưu theo IndicatorId, hoặc theo RowOrder (khi số lượng trùng), hoặc theo IndicatorName
        var existingByIndicatorId = existing.Where(d => d.IndicatorId.HasValue).ToDictionary(d => d.IndicatorId!.Value);
        var existingByRowOrder = existing.OrderBy(d => d.RowOrder).ToList();
        var existingByName = existing
            .Where(d => !d.IndicatorId.HasValue && !string.IsNullOrWhiteSpace(d.IndicatorName))
            .GroupBy(d => d.IndicatorName.Trim(), StringComparer.OrdinalIgnoreCase)
            .ToDictionary(g => g.Key, g => g.First(), StringComparer.OrdinalIgnoreCase);
        var result = new List<WorkbookDynamicIndicatorRowDto>();
        for (var i = 0; i < catalogOrdered.Count; i++)
        {
            var ind = catalogOrdered[i];
            ReportDynamicIndicator? saved = null;
            if (existingByIndicatorId.TryGetValue(ind.Id, out saved)) { }
            else if (i < existingByRowOrder.Count && existingByRowOrder[i].RowOrder == i)
                saved = existingByRowOrder[i];
            else if (existingByName.TryGetValue(ind.Name.Trim(), out saved)) { }
            else if (!string.IsNullOrWhiteSpace(ind.Name) && existingByName.TryGetValue(ind.Name, out saved)) { }

            if (saved != null)
                result.Add(new WorkbookDynamicIndicatorRowDto { IndicatorName = saved.IndicatorName, IndicatorValue = saved.IndicatorValue });
            else
                result.Add(new WorkbookDynamicIndicatorRowDto { IndicatorName = ind.Name, IndicatorValue = null });
        }
        return result;
    }

    /// <summary>Flatten cây Indicator (ParentId, DisplayOrder) đến độ sâu tối đa. Depth 1 = level 0 (gốc), 2 = 0+1, 3 = 0+1+2.</summary>
    private static List<Indicator> FlattenIndicatorTreeByDepth(List<Indicator> catalogIndicators, int maxDepth)
    {
        const int rootKey = -1;
        var byParent = new Dictionary<int, List<Indicator>>();
        foreach (var g in catalogIndicators.GroupBy(i => i.ParentId ?? rootKey))
            byParent[g.Key] = g.OrderBy(i => i.DisplayOrder).ThenBy(i => i.Id).ToList();
        var result = new List<Indicator>();
        void Visit(int parentKey, int currentLevel)
        {
            if (currentLevel >= maxDepth) return;
            if (!byParent.TryGetValue(parentKey, out var children)) return;
            foreach (var ind in children)
            {
                result.Add(ind);
                Visit(ind.Id, currentLevel + 1);
            }
        }
        Visit(rootKey, 0);
        return result;
    }

    /// <summary>P8e: Resolve danh sách nhãn cột theo ColumnSourceType (ByReportingPeriod, ByDataSource, ByCatalog, Fixed). Perf-12: dùng columnDataSourceCache khi có để tránh gọi QueryWithFilterAsync nhiều lần cho cùng cặp (DataSourceId, FilterDefinitionId).</summary>
    private async Task<List<string>> ResolveColumnLabelsAsync(
        FormDynamicColumnRegion region,
        FormPlaceholderColumnOccurrence occurrence,
        ParameterContext context,
        ReportingPeriodEntity? reportingPeriod,
        Dictionary<int, List<Indicator>> indicatorsByCatalog,
        IReadOnlyDictionary<int, FilterDefinitionDto> filterById,
        IReadOnlyDictionary<(int DataSourceId, int? FilterDefinitionId), List<Dictionary<string, object?>>> columnDataSourceCache,
        CancellationToken cancellationToken)
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
                    if (labels.Count == 0)
                        labels.Add(reportingPeriod.PeriodName);
                }
                break;
            case "ByDataSource":
                if (int.TryParse(region.ColumnSourceRef, out var dataSourceId))
                {
                    List<Dictionary<string, object?>>? rows = null;
                    if (columnDataSourceCache.TryGetValue((dataSourceId, occurrence.FilterDefinitionId), out var cached))
                        rows = cached;
                    else
                    {
                        var queryResult = await _dataSourceQuery.QueryWithFilterAsync(dataSourceId, occurrence.FilterDefinitionId, context, occurrence.MaxColumns ?? 0, filterById, cancellationToken);
                        rows = queryResult.IsSuccess && queryResult.Data != null ? queryResult.Data : null;
                    }
                    if (rows != null)
                    {
                        var labelCol = region.LabelColumn ?? "Name";
                        var maxCols = occurrence.MaxColumns ?? 0;
                        foreach (var row in (maxCols > 0 ? rows.Take(maxCols) : rows))
                        {
                            if (row.TryGetValue(labelCol, out var v) && v != null)
                                labels.Add(v.ToString() ?? "");
                            else
                                labels.Add("");
                        }
                    }
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
                {
                    labels = region.ColumnSourceRef.Split(',', StringSplitOptions.RemoveEmptyEntries).Select(s => s.Trim()).ToList();
                }
                break;
        }
        return labels;
    }

    private static object? ToJsonFriendly(object? value)
    {
        if (value == null) return null;
        if (value is DateTime dt) return dt.ToString("O");
        return value;
    }

    /// <summary>Số hàng header (1 = chỉ tên cột; 2+ = các tầng nhóm + hàng tên cột). 0-based: header row count = rows before data.</summary>
    private static int GetHeaderRowCountFromColumns(List<FormColumn> columns)
    {
        var levelCount = 0;
        if (columns.Any(c => !string.IsNullOrWhiteSpace(c.ColumnGroupName))) levelCount = 1;
        if (columns.Any(c => !string.IsNullOrWhiteSpace(c.ColumnGroupLevel2))) levelCount = 2;
        if (columns.Any(c => !string.IsNullOrWhiteSpace(c.ColumnGroupLevel3))) levelCount = 3;
        if (columns.Any(c => !string.IsNullOrWhiteSpace(c.ColumnGroupLevel4))) levelCount = 4;
        return levelCount + 1; // +1 hàng tên cột; result is 1-based count of header rows
    }
}
