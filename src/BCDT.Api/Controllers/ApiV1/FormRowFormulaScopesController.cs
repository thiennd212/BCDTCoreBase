using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/sheets/{sheetId:int}/rows/{rowId:int}/formula-scope")]
[Authorize]
[Produces("application/json")]
public class FormRowFormulaScopesController : ControllerBase
{
    private readonly IFormRowFormulaScopeService _service;

    public FormRowFormulaScopesController(IFormRowFormulaScopeService service) => _service = service;

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormRowFormulaScopeDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetList(int formId, int sheetId, int rowId, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByRowIdAsync(formId, sheetId, rowId, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code, result.Message)) : BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<FormRowFormulaScopeDto>>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormRowFormulaScopeDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Create(int formId, int sheetId, int rowId, [FromBody] CreateFormRowFormulaScopeRequest request, CancellationToken cancellationToken)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(formId, sheetId, rowId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return StatusCode(StatusCodes.Status201Created, new ApiSuccessResponse<FormRowFormulaScopeDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{id:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int formId, int sheetId, int rowId, int id, CancellationToken cancellationToken)
    {
        var result = await _service.DeleteAsync(formId, sheetId, rowId, id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
