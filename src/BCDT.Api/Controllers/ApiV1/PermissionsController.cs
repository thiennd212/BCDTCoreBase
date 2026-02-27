using BCDT.Api.Common;
using BCDT.Application.DTOs.Permission;
using BCDT.Application.Services;
using BCDT.Application.Services.Permission;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

/// <summary>API quản lý quyền (Permission)</summary>
[ApiController]
[Route("api/v1")]
[Authorize]
[Produces("application/json")]
public class PermissionsController : ControllerBase
{
    private readonly IPermissionService _service;
    private readonly ICurrentUserService _currentUserService;

    public PermissionsController(IPermissionService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    /// <summary>Danh sách tất cả quyền, nhóm theo Module</summary>
    [HttpGet("permissions")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<PermissionGroupDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllPermissions(CancellationToken cancellationToken = default)
    {
        var result = await _service.GetAllPermissionsAsync(cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<PermissionGroupDto>>(result.Data!));
    }

    /// <summary>Danh sách quyền (flat, không nhóm)</summary>
    [HttpGet("permissions/flat")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<PermissionDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAllPermissionsFlat(CancellationToken cancellationToken = default)
    {
        var result = await _service.GetAllFlatAsync(cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<PermissionDto>>(result.Data!));
    }

    /// <summary>Chi tiết quyền theo Id</summary>
    [HttpGet("permissions/{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<PermissionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetPermissionById(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Quyền không tồn tại."));
        return Ok(new ApiSuccessResponse<PermissionDto>(result.Data));
    }

    /// <summary>Tạo quyền mới</summary>
    [HttpPost("permissions")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<PermissionDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> CreatePermission([FromBody] CreatePermissionRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.CreateAsync(request, _currentUserService.GetUserId() ?? 0, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT")
                return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(GetPermissionById), new { id = result.Data!.Id }, new ApiSuccessResponse<PermissionDto>(result.Data));
    }

    /// <summary>Cập nhật quyền</summary>
    [HttpPut("permissions/{id:int}")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<PermissionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> UpdatePermission(int id, [FromBody] UpdatePermissionRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.UpdateAsync(id, request, _currentUserService.GetUserId() ?? 0, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<PermissionDto>(result.Data!));
    }

    /// <summary>Xóa quyền</summary>
    [HttpDelete("permissions/{id:int}")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> DeletePermission(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.DeleteAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            if (result.Code == "CONFLICT")
                return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return NoContent();
    }

    /// <summary>Danh sách quyền đã gán cho vai trò</summary>
    /// <param name="id">Id vai trò</param>
    [HttpGet("roles/{id:int}/permissions")]
    [ProducesResponseType(typeof(ApiSuccessResponse<RolePermissionsDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetRolePermissions(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetPermissionsByRoleIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<RolePermissionsDto>(result.Data!));
    }

    /// <summary>Gán quyền cho vai trò</summary>
    /// <param name="id">Id vai trò</param>
    /// <param name="request">Danh sách Id quyền cần gán</param>
    [HttpPut("roles/{id:int}/permissions")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<RolePermissionsDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> SetRolePermissions(int id, [FromBody] SetRolePermissionsRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.SetRolePermissionsAsync(id, request.PermissionIds, _currentUserService.GetUserId() ?? 0, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            if (result.Code == "FORBIDDEN")
                return StatusCode(StatusCodes.Status403Forbidden, new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<RolePermissionsDto>(result.Data!));
    }
}
