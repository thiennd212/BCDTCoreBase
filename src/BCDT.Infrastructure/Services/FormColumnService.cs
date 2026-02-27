using BCDT.Application.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using BCDT.Domain.Entities.Form;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services;

public class FormColumnService : IFormColumnService
{
    private readonly AppDbContext _db;

    public FormColumnService(AppDbContext db)
    {
        _db = db;
    }

    private static readonly HashSet<string> ValidDataTypes = new(StringComparer.OrdinalIgnoreCase)
        { "Text", "Number", "Date", "Formula", "Reference", "Boolean" };

    public async Task<Result<List<FormColumnDto>>> GetBySheetIdAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (sheet == null)
            return Result.Fail<List<FormColumnDto>>("NOT_FOUND", "Sheet không tồn tại.");

        var list = await _db.FormColumns
            .AsNoTracking()
            .Where(c => c.FormSheetId == sheetId)
            .OrderBy(c => c.DisplayOrder).ThenBy(c => c.Id)
            .ToListAsync(cancellationToken);
        return Result.Ok(list.Select(MapToDto).ToList());
    }

    public async Task<Result<List<FormColumnTreeDto>>> GetBySheetIdAsTreeAsync(int formDefinitionId, int sheetId, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets
            .AsNoTracking()
            .FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (sheet == null)
            return Result.Fail<List<FormColumnTreeDto>>("NOT_FOUND", "Sheet không tồn tại.");

        var list = await _db.FormColumns
            .AsNoTracking()
            .Where(c => c.FormSheetId == sheetId)
            .OrderBy(c => c.DisplayOrder).ThenBy(c => c.Id)
            .ToListAsync(cancellationToken);
        var dtos = list.Select(MapToDto).ToList();
        var tree = BuildColumnTree(dtos, null);
        return Result.Ok(tree);
    }

    public async Task<Result<FormColumnDto?>> GetByIdAsync(int formDefinitionId, int sheetId, int columnId, CancellationToken cancellationToken = default)
    {
        var column = await _db.FormColumns
            .AsNoTracking()
            .Where(c => c.Id == columnId && c.FormSheetId == sheetId)
            .Join(_db.FormSheets.Where(s => s.FormDefinitionId == formDefinitionId), c => c.FormSheetId, s => s.Id, (c, _) => c)
            .FirstOrDefaultAsync(cancellationToken);
        if (column == null)
            return Result.Ok<FormColumnDto?>(null);
        return Result.Ok<FormColumnDto?>(MapToDto(column));
    }

    public async Task<Result<FormColumnDto>> CreateAsync(int formDefinitionId, int sheetId, CreateFormColumnRequest request, int createdBy, CancellationToken cancellationToken = default)
    {
        var sheet = await _db.FormSheets.FirstOrDefaultAsync(s => s.Id == sheetId && s.FormDefinitionId == formDefinitionId, cancellationToken);
        if (sheet == null)
            return Result.Fail<FormColumnDto>("NOT_FOUND", "Sheet không tồn tại.");

        string columnCode = request.ColumnCode;
        string columnName = request.ColumnName;
        string dataType = request.DataType;
        string? defaultValue = request.DefaultValue;
        string? formula = request.Formula;
        string? validationRule = request.ValidationRule;
        string? validationMessage = request.ValidationMessage;
        string? format = request.Format;

        if (request.IndicatorId <= 0)
            return Result.Fail<FormColumnDto>("VALIDATION_FAILED", "Cột bắt buộc chọn chỉ tiêu từ danh mục (IndicatorId).");
        var indicator = await _db.Indicators.AsNoTracking().FirstOrDefaultAsync(i => i.Id == request.IndicatorId, cancellationToken);
        if (indicator == null)
            return Result.Fail<FormColumnDto>("NOT_FOUND", "Chỉ tiêu không tồn tại.");
        columnCode = string.IsNullOrWhiteSpace(request.ColumnCode) ? indicator.Code : request.ColumnCode;
        columnName = string.IsNullOrWhiteSpace(request.ColumnName) ? indicator.Name : request.ColumnName;
        dataType = ValidDataTypes.Contains(request.DataType) ? request.DataType : indicator.DataType;
        if (string.IsNullOrWhiteSpace(request.DefaultValue)) defaultValue = indicator.DefaultValue;
        if (string.IsNullOrWhiteSpace(request.Formula)) formula = indicator.FormulaTemplate;
        if (string.IsNullOrWhiteSpace(request.ValidationRule)) validationRule = indicator.ValidationRule;
        if (string.IsNullOrWhiteSpace(request.Format) && !string.IsNullOrWhiteSpace(indicator.Unit)) format = indicator.Unit;

        if (!ValidDataTypes.Contains(dataType))
            return Result.Fail<FormColumnDto>("VALIDATION_FAILED", "DataType phải thuộc: Text, Number, Date, Formula, Reference, Boolean.");
        var conflict = await _db.FormColumns.AnyAsync(c => c.FormSheetId == sheetId && c.ColumnCode == columnCode, cancellationToken);
        if (conflict)
            return Result.Fail<FormColumnDto>("CONFLICT", "ColumnCode đã tồn tại trong sheet này.");
        if (request.ParentId.HasValue)
        {
            var parentExists = await _db.FormColumns.AnyAsync(c => c.Id == request.ParentId.Value && c.FormSheetId == sheetId, cancellationToken);
            if (!parentExists)
                return Result.Fail<FormColumnDto>("VALIDATION_FAILED", "ParentId không thuộc sheet này.");
        }

        var entity = new FormColumn
        {
            FormSheetId = sheetId,
            ParentId = request.ParentId,
            IndicatorId = request.IndicatorId, // Phase 2b: always required
            ColumnCode = columnCode,
            ColumnName = columnName,
            ExcelColumn = string.IsNullOrWhiteSpace(request.ExcelColumn) ? null : request.ExcelColumn,
            LayoutOrder = request.LayoutOrder,
            DataType = dataType,
            IsRequired = request.IsRequired,
            IsEditable = request.IsEditable,
            IsHidden = request.IsHidden,
            DefaultValue = defaultValue,
            Formula = formula,
            ValidationRule = validationRule,
            ValidationMessage = validationMessage,
            DisplayOrder = request.DisplayOrder,
            Width = request.Width,
            Format = format,
            ColumnGroupName = request.ColumnGroupName,
            ColumnGroupLevel2 = request.ColumnGroupLevel2,
            ColumnGroupLevel3 = request.ColumnGroupLevel3,
            ColumnGroupLevel4 = request.ColumnGroupLevel4,
            CreatedAt = DateTime.UtcNow,
            CreatedBy = createdBy
        };
        _db.FormColumns.Add(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<FormColumnDto>> UpdateAsync(int formDefinitionId, int sheetId, int columnId, UpdateFormColumnRequest request, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormColumns
            .Where(c => c.Id == columnId && c.FormSheetId == sheetId)
            .Join(_db.FormSheets.Where(s => s.FormDefinitionId == formDefinitionId), c => c.FormSheetId, s => s.Id, (c, _) => c)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Fail<FormColumnDto>("NOT_FOUND", "Cột không tồn tại.");
        if (!ValidDataTypes.Contains(request.DataType))
            return Result.Fail<FormColumnDto>("VALIDATION_FAILED", "DataType phải thuộc: Text, Number, Date, Formula, Reference, Boolean.");
        if (request.IndicatorId <= 0)
            return Result.Fail<FormColumnDto>("VALIDATION_FAILED", "Cột bắt buộc chọn chỉ tiêu từ danh mục (IndicatorId).");
        var indicatorExists = await _db.Indicators.AnyAsync(i => i.Id == request.IndicatorId, cancellationToken);
        if (!indicatorExists)
            return Result.Fail<FormColumnDto>("NOT_FOUND", "Chỉ tiêu không tồn tại.");
        var conflict = await _db.FormColumns.AnyAsync(c => c.FormSheetId == sheetId && c.ColumnCode == request.ColumnCode && c.Id != columnId, cancellationToken);
        if (conflict)
            return Result.Fail<FormColumnDto>("CONFLICT", "ColumnCode đã tồn tại trong sheet này.");
        if (request.ParentId.HasValue)
        {
            if (request.ParentId.Value == columnId)
                return Result.Fail<FormColumnDto>("VALIDATION_FAILED", "ParentId không được trỏ về chính cột này.");
            var parentExists = await _db.FormColumns.AnyAsync(c => c.Id == request.ParentId.Value && c.FormSheetId == sheetId, cancellationToken);
            if (!parentExists)
                return Result.Fail<FormColumnDto>("VALIDATION_FAILED", "ParentId không thuộc sheet này.");
        }

        entity.ParentId = request.ParentId;
        entity.IndicatorId = request.IndicatorId; // Phase 2b: always required
        entity.ColumnCode = request.ColumnCode;
        entity.ColumnName = request.ColumnName;
        entity.ColumnGroupName = request.ColumnGroupName;
        entity.ColumnGroupLevel2 = request.ColumnGroupLevel2;
        entity.ColumnGroupLevel3 = request.ColumnGroupLevel3;
        entity.ColumnGroupLevel4 = request.ColumnGroupLevel4;
        entity.ExcelColumn = string.IsNullOrWhiteSpace(request.ExcelColumn) ? null : request.ExcelColumn;
        entity.LayoutOrder = request.LayoutOrder;
        entity.DataType = request.DataType;
        entity.IsRequired = request.IsRequired;
        entity.IsEditable = request.IsEditable;
        entity.IsHidden = request.IsHidden;
        entity.DefaultValue = request.DefaultValue;
        entity.Formula = request.Formula;
        entity.ValidationRule = request.ValidationRule;
        entity.ValidationMessage = request.ValidationMessage;
        entity.DisplayOrder = request.DisplayOrder;
        entity.Width = request.Width;
        entity.Format = request.Format;
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok(MapToDto(entity));
    }

    public async Task<Result<object>> DeleteAsync(int formDefinitionId, int sheetId, int columnId, CancellationToken cancellationToken = default)
    {
        var entity = await _db.FormColumns
            .Where(c => c.Id == columnId && c.FormSheetId == sheetId)
            .Join(_db.FormSheets.Where(s => s.FormDefinitionId == formDefinitionId), c => c.FormSheetId, s => s.Id, (c, _) => c)
            .FirstOrDefaultAsync(cancellationToken);
        if (entity == null)
            return Result.Fail<object>("NOT_FOUND", "Cột không tồn tại.");
        var hasChildren = await _db.FormColumns.AnyAsync(c => c.ParentId == columnId, cancellationToken);
        if (hasChildren)
            return Result.Fail<object>("VALIDATION_FAILED", "Không thể xóa cột còn cột con. Xóa cột con trước.");

        await _db.FormDataBindings.Where(b => b.FormColumnId == columnId).ExecuteDeleteAsync(cancellationToken);
        await _db.FormColumnMappings.Where(m => m.FormColumnId == columnId).ExecuteDeleteAsync(cancellationToken);
        _db.FormColumns.Remove(entity);
        await _db.SaveChangesAsync(cancellationToken);
        return Result.Ok<object>(new { });
    }

    private static FormColumnDto MapToDto(FormColumn c) => new()
    {
        Id = c.Id,
        FormSheetId = c.FormSheetId,
        ParentId = c.ParentId,
        IndicatorId = c.IndicatorId,
        ColumnCode = c.ColumnCode,
        ColumnName = c.ColumnName,
        ColumnGroupName = c.ColumnGroupName,
        ColumnGroupLevel2 = c.ColumnGroupLevel2,
        ColumnGroupLevel3 = c.ColumnGroupLevel3,
        ColumnGroupLevel4 = c.ColumnGroupLevel4,
        ExcelColumn = c.ExcelColumn,
        LayoutOrder = c.LayoutOrder,
        DataType = c.DataType,
        IsRequired = c.IsRequired,
        IsEditable = c.IsEditable,
        IsHidden = c.IsHidden,
        DefaultValue = c.DefaultValue,
        Formula = c.Formula,
        ValidationRule = c.ValidationRule,
        ValidationMessage = c.ValidationMessage,
        DisplayOrder = c.DisplayOrder,
        Width = c.Width,
        Format = c.Format,
        CreatedAt = c.CreatedAt,
        CreatedBy = c.CreatedBy
    };

    private static List<FormColumnTreeDto> BuildColumnTree(List<FormColumnDto> flat, int? parentId)
    {
        return flat
            .Where(c => c.ParentId == parentId)
            .Select(c => new FormColumnTreeDto
            {
                Id = c.Id,
                FormSheetId = c.FormSheetId,
                ParentId = c.ParentId,
                IndicatorId = c.IndicatorId,
                ColumnCode = c.ColumnCode,
                ColumnName = c.ColumnName,
                ColumnGroupName = c.ColumnGroupName,
                ColumnGroupLevel2 = c.ColumnGroupLevel2,
                ColumnGroupLevel3 = c.ColumnGroupLevel3,
                ColumnGroupLevel4 = c.ColumnGroupLevel4,
                ExcelColumn = c.ExcelColumn,
                LayoutOrder = c.LayoutOrder,
                DataType = c.DataType,
                IsRequired = c.IsRequired,
                IsEditable = c.IsEditable,
                IsHidden = c.IsHidden,
                DefaultValue = c.DefaultValue,
                Formula = c.Formula,
                ValidationRule = c.ValidationRule,
                ValidationMessage = c.ValidationMessage,
                DisplayOrder = c.DisplayOrder,
                Width = c.Width,
                Format = c.Format,
                CreatedAt = c.CreatedAt,
                CreatedBy = c.CreatedBy,
                Children = BuildColumnTree(flat, c.Id)
            })
            .ToList();
    }
}
