using BCDT.Api.Common;
using BCDT.Application.DTOs.SystemConfig;
using BCDT.Application.Services;
using BCDT.Application.Services.SystemConfig;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

/// <summary>API cấu hình hệ thống</summary>
[ApiController]
[Route("api/v1/system-config")]
[Authorize]
[Produces("application/json")]
public class SystemConfigController : ControllerBase
{
    private readonly ISystemConfigService _service;
    private readonly ICurrentUserService _currentUserService;

    public SystemConfigController(ISystemConfigService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    /// <summary>Danh sách tất cả cấu hình</summary>
    [HttpGet]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<SystemConfigDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetAll(CancellationToken cancellationToken = default)
    {
        var result = await _service.GetAllAsync(cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<SystemConfigDto>>(result.Data!));
    }

    /// <summary>Lấy cấu hình theo key</summary>
    [HttpGet("{key}")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<SystemConfigDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetByKey(string key, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByKeyAsync(key, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse(ApiErrorCodes.NotFound, "Không tìm thấy cấu hình."));
        return Ok(new ApiSuccessResponse<SystemConfigDto>(result.Data));
    }

    /// <summary>Cập nhật giá trị cấu hình</summary>
    [HttpPut("{key}")]
    [Authorize(Policy = "FormStructureAdmin")]
    [ProducesResponseType(typeof(ApiSuccessResponse<SystemConfigDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(string key, [FromBody] UpdateSystemConfigRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.UpdateAsync(key, request, _currentUserService.GetUserId() ?? 0, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == ApiErrorCodes.NotFound)
                return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<SystemConfigDto>(result.Data!));
    }
}
