using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/sheets/{sheetId:int}/rows")]
[Authorize]
[Produces("application/json")]
public class FormRowsController : ControllerBase
{
    private readonly IFormRowService _service;

    public FormRowsController(IFormRowService service) => _service = service;

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormRowDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormRowTreeDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetList(int formId, int sheetId, [FromQuery] bool tree = false, CancellationToken cancellationToken = default)
    {
        if (tree)
        {
            var resultTree = await _service.GetBySheetIdAsTreeAsync(formId, sheetId, cancellationToken);
            if (!resultTree.IsSuccess)
                return resultTree.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(resultTree.Code, resultTree.Message)) : BadRequest(new ApiErrorResponse(resultTree.Code, resultTree.Message));
            return Ok(new ApiSuccessResponse<List<FormRowTreeDto>>(resultTree.Data!));
        }
        var result = await _service.GetBySheetIdAsync(formId, sheetId, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code, result.Message)) : BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<FormRowDto>>(result.Data!));
    }

    [HttpGet("{rowId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormRowDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int formId, int sheetId, int rowId, CancellationToken cancellationToken)
    {
        var result = await _service.GetByIdAsync(formId, sheetId, rowId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Hàng không tồn tại."));
        return Ok(new ApiSuccessResponse<FormRowDto>(result.Data));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormRowDto>), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Create(int formId, int sheetId, [FromBody] CreateFormRowRequest request, CancellationToken cancellationToken)
    {
        var userId = int.TryParse(User.FindFirst(ClaimTypes.NameIdentifier)?.Value, out var id) ? id : -1;
        var result = await _service.CreateAsync(formId, sheetId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return CreatedAtAction(nameof(Get), new { formId, sheetId, rowId = result.Data!.Id }, new ApiSuccessResponse<FormRowDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut("{rowId:int}")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormRowDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int formId, int sheetId, int rowId, [FromBody] UpdateFormRowRequest request, CancellationToken cancellationToken)
    {
        var result = await _service.UpdateAsync(formId, sheetId, rowId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormRowDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpDelete("{rowId:int}")]
    [ProducesResponseType(StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int formId, int sheetId, int rowId, CancellationToken cancellationToken)
    {
        var result = await _service.DeleteAsync(formId, sheetId, rowId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
