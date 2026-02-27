using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/sheets/{sheetId:int}/dynamic-column-regions")]
[Authorize]
[Produces("application/json")]
public class FormDynamicColumnRegionsController : ControllerBase
{
    private readonly IFormDynamicColumnRegionService _service;

    public FormDynamicColumnRegionsController(IFormDynamicColumnRegionService service) => _service = service;

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormDynamicColumnRegionDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(int formId, int sheetId, CancellationToken cancellationToken)
    {
        var result = await _service.GetBySheetIdAsync(formId, sheetId, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code!, result.Message!)) : BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<FormDynamicColumnRegionDto>>(result.Data!));
    }

    [HttpGet("{regionId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDynamicColumnRegionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int formId, int sheetId, int regionId, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(formId, sheetId, regionId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Vùng cột động không tồn tại."));
        return Ok(new ApiSuccessResponse<FormDynamicColumnRegionDto>(result.Data));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDynamicColumnRegionDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Create(int formId, int sheetId, [FromBody] CreateFormDynamicColumnRegionRequest request, CancellationToken cancellationToken)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(formId, sheetId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { formId, sheetId, regionId = result.Data!.Id }, new ApiSuccessResponse<FormDynamicColumnRegionDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{regionId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDynamicColumnRegionDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int formId, int sheetId, int regionId, [FromBody] UpdateFormDynamicColumnRegionRequest request, CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(formId, sheetId, regionId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<FormDynamicColumnRegionDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{regionId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int formId, int sheetId, int regionId, CancellationToken cancellationToken)
    {
        var result = await _service.DeleteAsync(formId, sheetId, regionId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
