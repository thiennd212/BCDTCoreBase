using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

/// <summary>Chỉ tiêu tra cứu toàn cục (theo Code). Dùng cho Phase 2b: lấy id chỉ tiêu _SPECIAL_GENERIC.</summary>
[ApiController]
[Route("api/v1/indicators")]
[Authorize]
[Produces("application/json")]
public class IndicatorsByCodeController : ControllerBase
{
    private readonly IIndicatorService _service;

    public IndicatorsByCodeController(IIndicatorService service) => _service = service;

    /// <summary>Lấy chỉ tiêu theo Code (toàn cục). Ví dụ: by-code/_SPECIAL_GENERIC</summary>
    [HttpGet("by-code/{code}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<IndicatorDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetByCode(string code, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByCodeAsync(code, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Chỉ tiêu không tồn tại."));
        return Ok(new ApiSuccessResponse<IndicatorDto>(result.Data));
    }
}
