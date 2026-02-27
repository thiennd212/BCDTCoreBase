using BCDT.Application.Common;
using BCDT.Application.DTOs.Role;

namespace BCDT.Application.Services.Role;

/// <summary>Service quản lý vai trò (Role)</summary>
public interface IRoleService
{
    /// <summary>Lấy danh sách vai trò</summary>
    Task<Result<List<RoleDto>>> GetAllAsync(bool includeInactive = false, CancellationToken cancellationToken = default);
    
    /// <summary>Lấy vai trò theo Id</summary>
    Task<Result<RoleDto?>> GetByIdAsync(int id, CancellationToken cancellationToken = default);
    
    /// <summary>Tạo vai trò mới</summary>
    Task<Result<RoleDto>> CreateAsync(CreateRoleRequest request, int createdBy, CancellationToken cancellationToken = default);
    
    /// <summary>Cập nhật vai trò</summary>
    Task<Result<RoleDto>> UpdateAsync(int id, UpdateRoleRequest request, int updatedBy, CancellationToken cancellationToken = default);
    
    /// <summary>Xóa vai trò</summary>
    Task<Result<object>> DeleteAsync(int id, int deletedBy, CancellationToken cancellationToken = default);
}
