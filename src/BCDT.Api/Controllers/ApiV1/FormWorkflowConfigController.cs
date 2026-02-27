using BCDT.Api.Common;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services;
using BCDT.Application.Services.Workflow;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/forms/{formId:int}/workflow-config")]
[Authorize]
public class FormWorkflowConfigController : ControllerBase
{
    private readonly IFormWorkflowConfigService _service;
    private readonly ICurrentUserService _currentUserService;

    public FormWorkflowConfigController(IFormWorkflowConfigService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    [HttpGet]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<FormWorkflowConfigDto>>), StatusCodes.Status200OK)]
    public async Task<IActionResult> GetList(int formId, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByFormIdAsync(formId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<FormWorkflowConfigDto>>(result.Data!));
    }

    [HttpPost]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<FormWorkflowConfigDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Create(int formId, [FromBody] CreateFormWorkflowConfigRequest request, CancellationToken cancellationToken = default)
    {
        if (request.FormDefinitionId != formId)
            return BadRequest(new ApiErrorResponse("VALIDATION_FAILED", "FormDefinitionId trong body phải trùng formId trong URL."));
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.CreateAsync(request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<FormWorkflowConfigDto>(result.Data!));
    }

    [HttpDelete("{configId:int}")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int formId, int configId, CancellationToken cancellationToken = default)
    {
        var getResult = await _service.GetByIdAsync(configId, cancellationToken);
        if (!getResult.IsSuccess || getResult.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "FormWorkflowConfig không tồn tại."));
        if (getResult.Data.FormDefinitionId != formId)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "FormWorkflowConfig không thuộc form này."));
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.DeleteAsync(configId, userId, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code, result.Message)) : BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
