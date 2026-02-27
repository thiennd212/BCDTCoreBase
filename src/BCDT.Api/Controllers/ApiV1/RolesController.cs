using BCDT.Api.Common;
using BCDT.Application.DTOs.Role;
using BCDT.Application.Services;
using BCDT.Application.Services.Role;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

/// <summary>API quản lý vai trò (Role)</summary>
[ApiController]
[Route("api/v1/roles")]
[Authorize(Policy = "AdminManageRoles")]
[Produces("application/json")]
public class RolesController : ControllerBase
{
    private readonly IRoleService _service;
    private readonly ICurrentUserService _currentUserService;

    public RolesController(IRoleService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    /// <summary>Danh sách vai trò</summary>
    /// <param name="includeInactive">Bao gồm vai trò không hoạt động</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<RoleDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetAllAsync(includeInactive, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<RoleDto>>(result.Data!));
    }

    /// <summary>Chi tiết vai trò</summary>
    /// <param name="id">Id vai trò</param>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<RoleDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == ApiErrorCodes.NotFound)
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        if (result.Data == null)
            return NotFound(new ApiErrorResponse(ApiErrorCodes.NotFound, "Vai trò không tồn tại."));
        return Ok(new ApiSuccessResponse<RoleDto>(result.Data));
    }

    /// <summary>Tạo vai trò mới</summary>
    [HttpPost]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<RoleDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateRoleRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.CreateAsync(request, _currentUserService.GetUserId() ?? 0, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT")
                return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { id = result.Data!.Id }, new ApiSuccessResponse<RoleDto>(result.Data!));
    }

    /// <summary>Cập nhật vai trò</summary>
    /// <param name="id">Id vai trò</param>
    [HttpPut("{id:int}")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<RoleDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateRoleRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.UpdateAsync(id, request, _currentUserService.GetUserId() ?? 0, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            if (result.Code == "FORBIDDEN")
                return StatusCode(StatusCodes.Status403Forbidden, new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<RoleDto>(result.Data!));
    }

    /// <summary>Xóa vai trò</summary>
    /// <param name="id">Id vai trò</param>
    [HttpDelete("{id:int}")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status403Forbidden)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.DeleteAsync(id, _currentUserService.GetUserId() ?? 0, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            if (result.Code == "FORBIDDEN")
                return StatusCode(StatusCodes.Status403Forbidden, new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
