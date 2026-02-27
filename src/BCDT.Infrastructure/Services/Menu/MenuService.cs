using BCDT.Application.Common;
using BCDT.Application.DTOs.Menu;
using BCDT.Application.Services.Menu;
using BCDT.Infrastructure.Persistence;
using Microsoft.EntityFrameworkCore;

namespace BCDT.Infrastructure.Services.Menu;

/// <summary>Service quản lý menu</summary>
public class MenuService : IMenuService
{
    private readonly AppDbContext _db;

    public MenuService(AppDbContext db) => _db = db;

    public async Task<Result<List<MenuDto>>> GetAllAsync(bool asTree = false, int? roleId = null, CancellationToken cancellationToken = default)
    {
        IQueryable<Domain.Entities.Authorization.Menu> query = _db.Menus.AsNoTracking();
        // Menu gán với quyền (RequiredPermission), quyền gán cho vai trò (RolePermission) → chỉ hiển thị menu khi vai trò có quyền tương ứng
        if (roleId.HasValue)
        {
            var rolePermissionCodes = await _db.RolePermissions
                .AsNoTracking()
                .Where(rp => rp.RoleId == roleId.Value)
                .Join(_db.Permissions.AsNoTracking().Where(p => p.IsActive), rp => rp.PermissionId, p => p.Id, (_, p) => p.Code)
                .Distinct()
                .ToListAsync(cancellationToken);
            // Menu không yêu cầu quyền (null/empty) hoặc RequiredPermission nằm trong danh sách quyền của vai trò
            query = query.Where(m => string.IsNullOrEmpty(m.RequiredPermission) || rolePermissionCodes.Contains(m.RequiredPermission));
        }
        var menus = await query
            .OrderBy(m => m.ParentId)
            .ThenBy(m => m.DisplayOrder)
            .ThenBy(m => m.Name)
            .ToListAsync(cancellationToken);

        // Load parent names
        var menuDict = menus.ToDictionary(m => m.Id);
        var dtos = menus.Select(m => MapToDto(m, menuDict)).ToList();

        if (!asTree)
            return Result.Ok(dtos);

        // Build tree
        var dtoDict = dtos.ToDictionary(d => d.Id);
        var roots = new List<MenuDto>();

        foreach (var dto in dtos)
        {
            if (dto.ParentId == null)
            {
                roots.Add(dto);
            }
            else if (dtoDict.TryGetValue(dto.ParentId.Value, out var parent))
            {
                parent.Children ??= new List<MenuDto>();
                parent.Children.Add(dto);
            }
        }

        return Result.Ok(roots);
    }

    public async Task<Result<MenuDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        var menu = await _db.Menus
            .AsNoTracking()
            .FirstOrDefaultAsync(m => m.Id == id, cancellationToken);

        if (menu == null)
            return Result.Ok<MenuDto?>(null);

        // Load parent name if exists
        string? parentName = null;
        if (menu.ParentId != null)
        {
            var parent = await _db.Menus.AsNoTracking()
                .Where(m => m.Id == menu.ParentId)
                .Select(m => m.Name)
                .FirstOrDefaultAsync(cancellationToken);
            parentName = parent;
        }

        return Result.Ok<MenuDto?>(MapToDto(menu, parentName));
    }

    public async Task<Result<MenuDto>> CreateAsync(CreateMenuRequest request, CancellationToken cancellationToken = default)
    {
        // Check code unique
        if (await _db.Menus.AnyAsync(m => m.Code == request.Code, cancellationToken))
            return Result.Fail<MenuDto>("CONFLICT", "Mã menu đã tồn tại.");

        // Check parent exists
        if (request.ParentId != null)
        {
            if (!await _db.Menus.AnyAsync(m => m.Id == request.ParentId, cancellationToken))
                return Result.Fail<MenuDto>("VALIDATION_FAILED", "Menu cha không tồn tại.");
        }

        var menu = new Domain.Entities.Authorization.Menu
        {
            Code = request.Code,
            Name = request.Name,
            ParentId = request.ParentId,
            Url = request.Url,
            Icon = request.Icon,
            DisplayOrder = request.DisplayOrder,
            IsVisible = request.IsVisible,
            RequiredPermission = request.RequiredPermission,
            CreatedAt = DateTime.UtcNow
        };

        _db.Menus.Add(menu);
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok(MapToDto(menu, (string?)null));
    }

    public async Task<Result<MenuDto>> UpdateAsync(int id, UpdateMenuRequest request, CancellationToken cancellationToken = default)
    {
        var menu = await _db.Menus.FirstOrDefaultAsync(m => m.Id == id, cancellationToken);
        if (menu == null)
            return Result.Fail<MenuDto>("NOT_FOUND", "Menu không tồn tại.");

        // Check parent exists and prevent circular reference
        if (request.ParentId != null)
        {
            if (request.ParentId == id)
                return Result.Fail<MenuDto>("VALIDATION_FAILED", "Menu không thể là cha của chính nó.");

            if (!await _db.Menus.AnyAsync(m => m.Id == request.ParentId, cancellationToken))
                return Result.Fail<MenuDto>("VALIDATION_FAILED", "Menu cha không tồn tại.");

            // Check circular reference (parent is not a descendant)
            if (await IsDescendantAsync(request.ParentId.Value, id, cancellationToken))
                return Result.Fail<MenuDto>("VALIDATION_FAILED", "Không thể chọn menu con làm menu cha (tham chiếu vòng).");
        }

        menu.Name = request.Name;
        menu.ParentId = request.ParentId;
        menu.Url = request.Url;
        menu.Icon = request.Icon;
        menu.DisplayOrder = request.DisplayOrder;
        menu.IsVisible = request.IsVisible;
        menu.RequiredPermission = request.RequiredPermission;

        await _db.SaveChangesAsync(cancellationToken);

        string? parentName = null;
        if (menu.ParentId != null)
        {
            parentName = await _db.Menus.AsNoTracking()
                .Where(m => m.Id == menu.ParentId)
                .Select(m => m.Name)
                .FirstOrDefaultAsync(cancellationToken);
        }

        return Result.Ok(MapToDto(menu, parentName));
    }

    public async Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default)
    {
        var menu = await _db.Menus.FirstOrDefaultAsync(m => m.Id == id, cancellationToken);
        if (menu == null)
            return Result.Fail<object>("NOT_FOUND", "Menu không tồn tại.");

        // Check if has children
        if (await _db.Menus.AnyAsync(m => m.ParentId == id, cancellationToken))
            return Result.Fail<object>("CONFLICT", "Menu có menu con, không thể xóa.");

        // Check if assigned to any role
        if (await _db.RoleMenus.AnyAsync(rm => rm.MenuId == id, cancellationToken))
            return Result.Fail<object>("CONFLICT", "Menu đang được gán cho vai trò, không thể xóa.");

        _db.Menus.Remove(menu);
        await _db.SaveChangesAsync(cancellationToken);

        return Result.Ok<object>(null!);
    }

    /// <summary>Check if ancestorId is a descendant of menuId</summary>
    private async Task<bool> IsDescendantAsync(int ancestorId, int menuId, CancellationToken cancellationToken)
    {
        var current = ancestorId;
        var visited = new HashSet<int>();
        
        while (true)
        {
            if (visited.Contains(current))
                return false; // Circular reference already exists
            visited.Add(current);

            var parentId = await _db.Menus
                .Where(m => m.Id == current)
                .Select(m => m.ParentId)
                .FirstOrDefaultAsync(cancellationToken);

            if (parentId == null)
                return false;
            if (parentId == menuId)
                return true;
            current = parentId.Value;
        }
    }

    private static MenuDto MapToDto(Domain.Entities.Authorization.Menu m, Dictionary<int, Domain.Entities.Authorization.Menu> dict)
    {
        string? parentName = null;
        if (m.ParentId != null && dict.TryGetValue(m.ParentId.Value, out var parent))
            parentName = parent.Name;

        return MapToDto(m, parentName);
    }

    private static MenuDto MapToDto(Domain.Entities.Authorization.Menu m, string? parentName) => new()
    {
        Id = m.Id,
        Code = m.Code,
        Name = m.Name,
        ParentId = m.ParentId,
        ParentName = parentName,
        Url = m.Url,
        Icon = m.Icon,
        DisplayOrder = m.DisplayOrder,
        IsVisible = m.IsVisible,
        RequiredPermission = m.RequiredPermission,
        CreatedAt = m.CreatedAt
    };
}
