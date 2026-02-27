using BCDT.Application.Common;
using BCDT.Application.DTOs.Menu;

namespace BCDT.Application.Services.Menu;

/// <summary>Service quản lý menu</summary>
public interface IMenuService
{
    /// <summary>Lấy danh sách menu (flat hoặc tree). roleId != null: chỉ menu mà vai trò có quyền (Menu.RequiredPermission thuộc quyền của vai trò qua RolePermission).</summary>
    Task<Result<List<MenuDto>>> GetAllAsync(bool asTree = false, int? roleId = null, CancellationToken cancellationToken = default);
    
    /// <summary>Lấy chi tiết menu theo Id</summary>
    Task<Result<MenuDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    
    /// <summary>Tạo menu mới</summary>
    Task<Result<MenuDto>> CreateAsync(CreateMenuRequest request, CancellationToken cancellationToken = default);
    
    /// <summary>Cập nhật menu</summary>
    Task<Result<MenuDto>> UpdateAsync(int id, UpdateMenuRequest request, CancellationToken cancellationToken = default);
    
    /// <summary>Xóa menu</summary>
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
}
