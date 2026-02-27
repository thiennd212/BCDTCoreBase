using BCDT.Api.Common;
using BCDT.Application.DTOs.ReportingPeriod;
using BCDT.Application.Services.ReportingPeriod;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/reporting-frequencies")]
[Authorize]
[Produces("application/json")]
public class ReportingFrequenciesController : ControllerBase
{
    private readonly IReportingFrequencyService _service;

    public ReportingFrequenciesController(IReportingFrequencyService service) => _service = service;

    /// <summary>Danh sách chu kỳ báo cáo</summary>
    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<ReportingFrequencyDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList([FromQuery] bool includeInactive = false, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetListAsync(includeInactive, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<ReportingFrequencyDto>>(result.Data!));
    }

    /// <summary>Chi tiết chu kỳ báo cáo</summary>
    [HttpGet("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportingFrequencyDto>), StatusCodes.Status200OK)]
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
            return NotFound(new ApiErrorResponse(ApiErrorCodes.NotFound, "Chu kỳ báo cáo không tồn tại."));
        return Ok(new ApiSuccessResponse<ReportingFrequencyDto>(result.Data));
    }

    /// <summary>Tạo chu kỳ báo cáo</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportingFrequencyDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create([FromBody] CreateReportingFrequencyRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.CreateAsync(request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { id = result.Data!.Id }, new ApiSuccessResponse<ReportingFrequencyDto>(result.Data!));
    }

    /// <summary>Cập nhật chu kỳ báo cáo</summary>
    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{id:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<ReportingFrequencyDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int id, [FromBody] UpdateReportingFrequencyRequest request, CancellationToken cancellationToken = default)
    {
        var result = await _service.UpdateAsync(id, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<ReportingFrequencyDto>(result.Data!));
    }

    /// <summary>Xóa chu kỳ báo cáo</summary>
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
