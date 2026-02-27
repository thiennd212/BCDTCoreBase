using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/indicator-catalogs/{catalogId:int}/indicators")]
[Authorize]
[Produces("application/json")]
public class IndicatorsController : ControllerBase
{
    private readonly IIndicatorService _service;

    public IndicatorsController(IIndicatorService service) => _service = service;

    /// <summary>Danh sách chỉ tiêu trong danh mục (hỗ trợ tree)</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<IndicatorDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(int catalogId, [FromQuery] bool tree = false, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByCatalogAsync(catalogId, tree, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<List<IndicatorDto>>(result.Data!));
    }

    /// <summary>Chi tiết chỉ tiêu</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<IndicatorDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int catalogId, int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Chỉ tiêu không tồn tại."));
        return Ok(new ApiSuccessResponse<IndicatorDto>(result.Data));
    }

    /// <summary>Tạo chỉ tiêu trong danh mục</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<IndicatorDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(int catalogId, [FromBody] CreateIndicatorRequest request, CancellationToken cancellationToken = default)
    {
        request.IndicatorCatalogId = catalogId;
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { catalogId, id = result.Data!.Id }, new ApiSuccessResponse<IndicatorDto>(result.Data!));
    }

    /// <summary>Cập nhật chỉ tiêu</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<IndicatorDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> Update(int catalogId, int id, [FromBody] UpdateIndicatorRequest request, CancellationToken cancellationToken = default)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var uid) ? uid : -1;
        var result = await _service.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<IndicatorDto>(result.Data!));
    }

    /// <summary>Xóa chỉ tiêu</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    public async Task<IActionResult> Delete(int catalogId, int id, CancellationToken cancellationToken = default)
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
