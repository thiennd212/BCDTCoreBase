using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/indicator-catalogs")]
[Authorize]
[Produces("application/json")]
public class IndicatorCatalogsController : ControllerBase
{
    private readonly IIndicatorCatalogService _service;

    public IndicatorCatalogsController(IIndicatorCatalogService service) => _service = service;

    /// <summary>Danh sách danh mục chỉ tiêu</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<IndicatorCatalogDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetAllAsync(includeInactive, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<IndicatorCatalogDto>>(result.Data!));
    }

    /// <summary>Chi tiết danh mục chỉ tiêu</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<IndicatorCatalogDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Danh mục chỉ tiêu không tồn tại."));
        return Ok(new ApiSuccessResponse<IndicatorCatalogDto>(result.Data));
    }

    /// <summary>Tạo danh mục chỉ tiêu</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<IndicatorCatalogDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create([FromBody] CreateIndicatorCatalogRequest request, CancellationToken cancellationToken = default)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { id = result.Data!.Id }, new ApiSuccessResponse<IndicatorCatalogDto>(result.Data!));
    }

    /// <summary>Cập nhật danh mục chỉ tiêu</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<IndicatorCatalogDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateIndicatorCatalogRequest request, CancellationToken cancellationToken = default)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var uid) ? uid : -1;
        var result = await _service.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<IndicatorCatalogDto>(result.Data!));
    }

    /// <summary>Xóa danh mục chỉ tiêu</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.DeleteAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
