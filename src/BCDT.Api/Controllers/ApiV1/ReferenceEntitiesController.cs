using BCDT.Api.Common;
using BCDT.Application.DTOs.ReferenceEntity;
using BCDT.Application.Services;
using BCDT.Application.Services.ReferenceEntity;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/reference-entities")]
[Authorize]
[Produces("application/json")]
public class ReferenceEntitiesController : ControllerBase
{
    private readonly IReferenceEntityService _service;
    private readonly ICurrentUserService _currentUserService;

    public ReferenceEntitiesController(IReferenceEntityService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    /// <summary>Danh sách thực thể tham chiếu (phân cấp). entityTypeId: lọc loại; parentId: gốc nếu null; all=true: trả toàn bộ (flat).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<ReferenceEntityDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(
        [FromQuery] int? entityTypeId,
        [FromQuery] long? parentId,
        [FromQuery] bool includeInactive = false,
        [FromQuery] bool all = false,
        CancellationToken cancellationToken = default)
    {
        var result = await _service.GetListAsync(entityTypeId, parentId, includeInactive, all, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<ReferenceEntityDto>>(result.Data!));
    }

    /// <summary>Chi tiết thực thể tham chiếu theo Id.</summary>
    [HttpGet("{id:long}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReferenceEntityDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(long id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Bản ghi không tồn tại."));
        return Ok(new ApiSuccessResponse<ReferenceEntityDto>(result.Data));
    }

    /// <summary>Tạo thực thể tham chiếu mới.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReferenceEntityDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create([FromBody] CreateReferenceEntityRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<ReferenceEntityDto>(result.Data!));
    }

    /// <summary>Cập nhật thực thể tham chiếu.</summary>
    [HttpPut("{id:long}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReferenceEntityDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(long id, [FromBody] UpdateReferenceEntityRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<ReferenceEntityDto>(result.Data!));
    }

    /// <summary>Xóa (soft) thực thể tham chiếu. 409 nếu có con.</summary>
    [HttpDelete("{id:long}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Delete(long id, CancellationToken cancellationToken = default)
    {
        var result = await _service.DeleteAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<object?>(null));
    }
}
