using BCDT.Api.Common;
using BCDT.Application.DTOs.ReferenceEntity;
using BCDT.Application.Services.ReferenceEntity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/reference-entity-types")]
[Authorize]
[Produces("application/json")]
public class ReferenceEntityTypesController : ControllerBase
{
    private readonly IReferenceEntityTypeService _service;

    public ReferenceEntityTypesController(IReferenceEntityTypeService service) => _service = service;

    /// <summary>Danh sách loại thực thể tham chiếu (cho dropdown).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<ReferenceEntityTypeDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetListAsync(includeInactive, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<ReferenceEntityTypeDto>>(result.Data!));
    }

    /// <summary>Chi tiết loại thực thể theo Id.</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReferenceEntityTypeDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Loại thực thể không tồn tại."));
        return Ok(new ApiSuccessResponse<ReferenceEntityTypeDto>(result.Data));
    }

    /// <summary>Tạo loại thực thể.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReferenceEntityTypeDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateReferenceEntityTypeRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.CreateAsync(request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { id = result.Data!.Id }, new ApiSuccessResponse<ReferenceEntityTypeDto>(result.Data!));
    }

    /// <summary>Cập nhật loại thực thể.</summary>
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReferenceEntityTypeDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateReferenceEntityTypeRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.UpdateAsync(id, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<ReferenceEntityTypeDto>(result.Data!));
    }

    /// <summary>Xóa loại thực thể (chỉ khi chưa có bản ghi tham chiếu thuộc loại).</summary>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.DeleteAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
