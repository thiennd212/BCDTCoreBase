using BCDT.Api.Common;
using BCDT.Application.DTOs.Organization;
using BCDT.Application.Services.Organization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/organization-types")]
[Authorize(Policy = "AdminManageOrg")]
[Produces("application/json")]
public class OrganizationTypesController : ControllerBase
{
    private readonly IOrganizationTypeService _service;

    public OrganizationTypesController(IOrganizationTypeService service) => _service = service;

    /// <summary>Danh sách loại đơn vị</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<OrganizationTypeDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetAllAsync(includeInactive, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<OrganizationTypeDto>>(result.Data!));
    }

    /// <summary>Chi tiết loại đơn vị</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<OrganizationTypeDto>), StatusCodes.Status200OK)]
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
            return NotFound(new ApiErrorResponse(ApiErrorCodes.NotFound, "Loại đơn vị không tồn tại."));
        return Ok(new ApiSuccessResponse<OrganizationTypeDto>(result.Data));
    }

    /// <summary>Tạo loại đơn vị</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<OrganizationTypeDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create([FromBody] CreateOrganizationTypeRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.CreateAsync(request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { id = result.Data!.Id }, new ApiSuccessResponse<OrganizationTypeDto>(result.Data!));
    }

    /// <summary>Cập nhật loại đơn vị</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<OrganizationTypeDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateOrganizationTypeRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.UpdateAsync(id, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<OrganizationTypeDto>(result.Data!));
    }

    /// <summary>Xóa loại đơn vị</summary>
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
