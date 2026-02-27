using BCDT.Api.Common;
using BCDT.Application.DTOs.Menu;
using BCDT.Application.Services.Menu;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

/// <summary>API quản lý menu hệ thống</summary>
[ApiController]
[Route("api/v1/menus")]
[Authorize]
public class MenusController : ControllerBase
{
    private readonly IMenuService _service;

    public MenusController(IMenuService service) => _service = service;

    /// <summary>Danh sách menu (tree). roleId: chỉ menu mà vai trò có quyền (Menu.RequiredPermission nằm trong quyền của vai trò).</summary>
    /// <param name="all">true = flat list, không dùng = tree</param>
    /// <param name="roleId">Lọc theo vai trò: menu hiển thị khi RequiredPermission null hoặc vai trò có quyền tương ứng (RolePermission)</param>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<MenuDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll([FromQuery] bool? all, [FromQuery] int? roleId, CancellationToken cancellationToken = default)
    {
        var asTree = all != true;
        var result = await _service.GetAllAsync(asTree: asTree, roleId: roleId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<MenuDto>>(result.Data!));
    }

    /// <summary>Chi tiết menu theo Id</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<MenuDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetById(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == ApiErrorCodes.NotFound)
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        if (result.Data == null)
            return NotFound(new ApiErrorResponse(ApiErrorCodes.NotFound, "Menu không tồn tại."));
        return Ok(new ApiSuccessResponse<MenuDto>(result.Data));
    }

    /// <summary>Tạo menu mới</summary>
    [HttpPost]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<MenuDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateMenuRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.CreateAsync(request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT")
                return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(GetById), new { id = result.Data!.Id }, new ApiSuccessResponse<MenuDto>(result.Data));
    }

    /// <summary>Cập nhật menu</summary>
    [HttpPut("{id:int}")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<MenuDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateMenuRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.UpdateAsync(id, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND")
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<MenuDto>(result.Data!));
    }

    /// <summary>Xóa menu</summary>
    [HttpDelete("{id:int}")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(StatusCodes.Status204NoContent)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
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
}
