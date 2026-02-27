using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/sheets")]
[Authorize]
[Produces("application/json")]
public class FormSheetsController : ControllerBase
{
    private readonly IFormSheetService _service;

    public FormSheetsController(IFormSheetService service) => _service = service;

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormSheetDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(int formId, CancellationToken cancellationToken)
    {
        var result = await _service.GetByFormIdAsync(formId, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code, result.Message)) : BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<FormSheetDto>>(result.Data!));
    }

    [HttpGet("{sheetId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormSheetDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int formId, int sheetId, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(formId, sheetId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Sheet không tồn tại."));
        return Ok(new ApiSuccessResponse<FormSheetDto>(result.Data));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormSheetDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create(int formId, [FromBody] CreateFormSheetRequest request, CancellationToken cancellationToken)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(formId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormSheetDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{sheetId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormSheetDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Update(int formId, int sheetId, [FromBody] UpdateFormSheetRequest request, CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(formId, sheetId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormSheetDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{sheetId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int formId, int sheetId, CancellationToken cancellationToken)
    {
        var result = await _service.DeleteAsync(formId, sheetId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
