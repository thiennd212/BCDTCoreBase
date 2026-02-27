using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/sheets/{sheetId:int}/placeholder-column-occurrences")]
[Authorize]
[Produces("application/json")]
public class FormPlaceholderColumnOccurrencesController : ControllerBase
{
    private readonly IFormPlaceholderColumnOccurrenceService _service;

    public FormPlaceholderColumnOccurrencesController(IFormPlaceholderColumnOccurrenceService service) => _service = service;

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormPlaceholderColumnOccurrenceDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(int formId, int sheetId, CancellationToken cancellationToken)
    {
        var result = await _service.GetBySheetIdAsync(formId, sheetId, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code!, result.Message!)) : BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        return Ok(new ApiSuccessResponse<List<FormPlaceholderColumnOccurrenceDto>>(result.Data!));
    }

    [HttpGet("{occurrenceId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormPlaceholderColumnOccurrenceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(formId, sheetId, occurrenceId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Vị trí placeholder cột không tồn tại."));
        return Ok(new ApiSuccessResponse<FormPlaceholderColumnOccurrenceDto>(result.Data));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormPlaceholderColumnOccurrenceDto>), StatusCodes.Status201Created)]
    public async Task<IActionResult> Create(int formId, int sheetId, [FromBody] CreateFormPlaceholderColumnOccurrenceRequest request, CancellationToken cancellationToken)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(formId, sheetId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return CreatedAtAction(nameof(Get), new { formId, sheetId, occurrenceId = result.Data!.Id }, new ApiSuccessResponse<FormPlaceholderColumnOccurrenceDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{occurrenceId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormPlaceholderColumnOccurrenceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int formId, int sheetId, int occurrenceId, [FromBody] UpdateFormPlaceholderColumnOccurrenceRequest request, CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(formId, sheetId, occurrenceId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<FormPlaceholderColumnOccurrenceDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{occurrenceId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int formId, int sheetId, int occurrenceId, CancellationToken cancellationToken)
    {
        var result = await _service.DeleteAsync(formId, sheetId, occurrenceId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code!, result.Message!));
            return BadRequest(new ApiErrorResponse(result.Code!, result.Message!));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
