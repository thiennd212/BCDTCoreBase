using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/sheets/{sheetId:int}/columns")]
[Authorize]
[Produces("application/json")]
public class FormColumnsController : ControllerBase
{
    private readonly IFormColumnService _service;

    public FormColumnsController(IFormColumnService service) => _service = service;

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormColumnDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormColumnTreeDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetList(int formId, int sheetId, [FromQuery] bool tree = false, CancellationToken cancellationToken = default)
    {
        if (tree)
        {
            var resultTree = await _service.GetBySheetIdAsTreeAsync(formId, sheetId, cancellationToken);
            if (!resultTree.IsSuccess)
                return resultTree.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(resultTree.Code, resultTree.Message)) : BadRequest(new ApiErrorResponse(resultTree.Code, resultTree.Message));
            return Ok(new ApiSuccessResponse<List<FormColumnTreeDto>>(resultTree.Data!));
        }
        var result = await _service.GetBySheetIdAsync(formId, sheetId, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code, result.Message)) : BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<FormColumnDto>>(result.Data!));
    }

    [HttpGet("{columnId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormColumnDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int formId, int sheetId, int columnId, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(formId, sheetId, columnId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Cột không tồn tại."));
        return Ok(new ApiSuccessResponse<FormColumnDto>(result.Data));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormColumnDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create(int formId, int sheetId, [FromBody] CreateFormColumnRequest request, CancellationToken cancellationToken)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(formId, sheetId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormColumnDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{columnId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormColumnDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Update(int formId, int sheetId, int columnId, [FromBody] UpdateFormColumnRequest request, CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(formId, sheetId, columnId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormColumnDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{columnId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int formId, int sheetId, int columnId, CancellationToken cancellationToken)
    {
        var result = await _service.DeleteAsync(formId, sheetId, columnId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
