using BCDT.Application.Common;
using BCDT.Application.DTOs.Permission;

namespace BCDT.Application.Services.Permission;

/// <summary>Service quản lý quyền (Permission)</summary>
public interface IPermissionService
{
    /// <summary>Lấy danh sách tất cả quyền, nhóm theo Module</summary>
    Task<Result<List<PermissionGroupDto>>> GetAllPermissionsAsync(CancellationToken cancellationToken = default);
    
    /// <summary>Lấy danh sách quyền (flat, không nhóm)</summary>
    Task<Result<List<PermissionDto>>> GetAllFlatAsync(CancellationToken cancellationToken = default);
    
    /// <summary>Lấy chi tiết quyền theo Id</summary>
    Task<Result<PermissionDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    
    /// <summary>Tạo quyền mới</summary>
    Task<Result<PermissionDto>> CreateAsync(CreatePermissionRequest request, int createdBy, CancellationToken cancellationToken = default);
    
    /// <summary>Cập nhật quyền</summary>
    Task<Result<PermissionDto>> UpdateAsync(int id, UpdatePermissionRequest request, int updatedBy, CancellationToken cancellationToken = default);
    
    /// <summary>Xóa quyền</summary>
    Task<Result<object>> DeleteAsync(int id, CancellationToken cancellationToken = default);
    
    /// <summary>Lấy danh sách quyền đã gán cho vai trò</summary>
    Task<Result<RolePermissionsDto>> GetPermissionsByRoleIdAsync(int roleId, CancellationToken cancellationToken = default);
    
    /// <summary>Gán quyền cho vai trò (sync: xóa cũ, thêm mới)</summary>
    Task<Result<RolePermissionsDto>> SetRolePermissionsAsync(int roleId, List<int> permissionIds, int grantedBy, CancellationToken cancellationToken = default);
}
