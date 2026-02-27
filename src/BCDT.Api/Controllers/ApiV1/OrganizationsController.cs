using BCDT.Api.Common;
using BCDT.Application.DTOs.Organization;
using BCDT.Application.Services;
using BCDT.Application.Services.Organization;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/organizations")]
[Authorize(Policy = "AdminManageOrg")]
[Produces("application/json")]
public class OrganizationsController : ControllerBase
{
    private readonly IOrganizationService _organizationService;
    private readonly ICurrentUserService _currentUserService;

    public OrganizationsController(IOrganizationService organizationService, ICurrentUserService currentUserService)
    {
        _organizationService = organizationService;
        _currentUserService = currentUserService;
    }

    /// <summary>Lấy danh sách đơn vị (cây 5 cấp). Filter: parentId (null = gốc), organizationTypeId, includeInactive. all=true: trả về toàn bộ (flat).</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<OrganizationDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(
        [FromQuery] int? parentId,
        [FromQuery] int? organizationTypeId,
        [FromQuery] bool includeInactive = false,
        [FromQuery] bool all = false,
        CancellationToken cancellationToken = default)
    {
        var result = await _organizationService.GetListAsync(parentId, organizationTypeId, includeInactive, all, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<OrganizationDto>>(result.Data!));
    }

    /// <summary>Lấy đơn vị theo Id.</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<OrganizationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int id, CancellationToken cancellationToken = default)
    {
        var result = await _organizationService.GetByIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == ApiErrorCodes.NotFound)
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Đơn vị không tồn tại."));
        return Ok(new ApiSuccessResponse<OrganizationDto>(result.Data));
    }

    /// <summary>Tạo đơn vị mới.</summary>
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<OrganizationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiErrorResponse), StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create([FromBody] CreateOrganizationRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _organizationService.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<OrganizationDto>(result.Data!));
    }

    /// <summary>Cập nhật đơn vị.</summary>
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<OrganizationDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateOrganizationRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _organizationService.UpdateAsync(id, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<OrganizationDto>(result.Data!));
    }

    /// <summary>Xóa đơn vị (soft delete).</summary>
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int id, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _organizationService.DeleteAsync(id, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
