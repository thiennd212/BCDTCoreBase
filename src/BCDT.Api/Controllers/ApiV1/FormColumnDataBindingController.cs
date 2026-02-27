using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/sheets/{sheetId:int}/columns/{columnId:int}/data-binding")]
[Authorize]
[Produces("application/json")]
public class FormColumnDataBindingController : ControllerBase
{
    private readonly IFormColumnService _columnService;
    private readonly IFormDataBindingService _bindingService;

    public FormColumnDataBindingController(IFormColumnService columnService, IFormDataBindingService bindingService)
    {
        _columnService = columnService;
        _bindingService = bindingService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDataBindingDto?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int formId, int sheetId, int columnId, CancellationToken cancellationToken)
    {
        var col = await _columnService.GetByIdAsync(formId, sheetId, columnId, cancellationToken);
        if (!col.IsSuccess || col.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Cột không tồn tại."));
        var result = await _bindingService.GetByColumnIdAsync(columnId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<FormDataBindingDto?>(result.Data));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDataBindingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create(int formId, int sheetId, int columnId, [FromBody] CreateFormDataBindingRequest request, CancellationToken cancellationToken)
    {
        var col = await _columnService.GetByIdAsync(formId, sheetId, columnId, cancellationToken);
        if (!col.IsSuccess || col.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Cột không tồn tại."));
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _bindingService.CreateAsync(columnId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormDataBindingDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormDataBindingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int formId, int sheetId, int columnId, [FromBody] UpdateFormDataBindingRequest request, CancellationToken cancellationToken)
    {
        var col = await _columnService.GetByIdAsync(formId, sheetId, columnId, cancellationToken);
        if (!col.IsSuccess || col.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Cột không tồn tại."));
        var result = await _bindingService.UpdateAsync(columnId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormDataBindingDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int formId, int sheetId, int columnId, CancellationToken cancellationToken)
    {
        var col = await _columnService.GetByIdAsync(formId, sheetId, columnId, cancellationToken);
        if (!col.IsSuccess || col.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Cột không tồn tại."));
        var result = await _bindingService.DeleteAsync(columnId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
