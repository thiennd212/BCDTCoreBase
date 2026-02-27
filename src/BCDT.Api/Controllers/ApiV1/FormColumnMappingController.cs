using BCDT.Api.Common;
using BCDT.Application.DTOs.Form;
using BCDT.Application.Services.Form;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/sheets/{sheetId:int}/columns/{columnId:int}/column-mapping")]
[Authorize]
[Produces("application/json")]
public class FormColumnMappingController : ControllerBase
{
    private readonly IFormColumnService _columnService;
    private readonly IFormColumnMappingService _mappingService;

    public FormColumnMappingController(IFormColumnService columnService, IFormColumnMappingService mappingService)
    {
        _columnService = columnService;
        _mappingService = mappingService;
    }

    [HttpGet]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormColumnMappingDto?>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int formId, int sheetId, int columnId, CancellationToken cancellationToken)
    {
        var col = await _columnService.GetByIdAsync(formId, sheetId, columnId, cancellationToken);
        if (!col.IsSuccess || col.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Cột không tồn tại."));
        var result = await _mappingService.GetByColumnIdAsync(columnId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<FormColumnMappingDto?>(result.Data));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPost]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormColumnMappingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status409Conflict)]
    public async Task<IActionResult> Create(int formId, int sheetId, int columnId, [FromBody] CreateFormColumnMappingRequest request, CancellationToken cancellationToken)
    {
        var col = await _columnService.GetByIdAsync(formId, sheetId, columnId, cancellationToken);
        if (!col.IsSuccess || col.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Cột không tồn tại."));
        var result = await _mappingService.CreateAsync(columnId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            if (result.Code == "CONFLICT") return Conflict(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormColumnMappingDto>(result.Data!));
    }

    [Authorize(Policy = "FormStructureAdmin")]
    [HttpPut]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormColumnMappingDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int formId, int sheetId, int columnId, [FromBody] UpdateFormColumnMappingRequest request, CancellationToken cancellationToken)
    {
        var col = await _columnService.GetByIdAsync(formId, sheetId, columnId, cancellationToken);
        if (!col.IsSuccess || col.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "Cột không tồn tại."));
        var result = await _mappingService.UpdateAsync(columnId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormColumnMappingDto>(result.Data!));
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
        var result = await _mappingService.DeleteAsync(columnId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
