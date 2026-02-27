using BCDT.Api.Common;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services;
using BCDT.Application.Services.Workflow;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/workflow-definitions/{workflowDefinitionId:int}/steps")]
[Authorize]
public class WorkflowStepsController : ControllerBase
{
    private readonly IWorkflowStepService _service;
    private readonly ICurrentUserService _currentUserService;

    public WorkflowStepsController(IWorkflowStepService service, ICurrentUserService currentUserService)
    {
        _service = service;
        _currentUserService = currentUserService;
    }

    [HttpGet]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<WorkflowStepDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetList(int workflowDefinitionId, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByDefinitionIdAsync(workflowDefinitionId, cancellationToken);
        if (!result.IsSuccess)
            return result.Code == "NOT_FOUND" ? NotFound(new ApiErrorResponse(result.Code, result.Message)) : BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<List<WorkflowStepDto>>(result.Data!));
    }

    [HttpGet("{stepId:int}")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkflowStepDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Get(int workflowDefinitionId, int stepId, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetByIdAsync(workflowDefinitionId, stepId, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        if (result.Data == null)
            return NotFound(new ApiErrorResponse("NOT_FOUND", "WorkflowStep không tồn tại."));
        return Ok(new ApiSuccessResponse<WorkflowStepDto>(result.Data));
    }

    [HttpPost]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkflowStepDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Create(int workflowDefinitionId, [FromBody] CreateWorkflowStepRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.CreateAsync(workflowDefinitionId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<WorkflowStepDto>(result.Data!));
    }

    [HttpPut("{stepId:int}")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkflowStepDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Update(int workflowDefinitionId, int stepId, [FromBody] UpdateWorkflowStepRequest request, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.UpdateAsync(workflowDefinitionId, stepId, request, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<WorkflowStepDto>(result.Data!));
    }

    [HttpDelete("{stepId:int}")]
    [Produces("application/json")]
    [ProducesResponseType(typeof(ApiSuccessResponse<object>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> Delete(int workflowDefinitionId, int stepId, CancellationToken cancellationToken = default)
    {
        var userId = _currentUserService.GetUserId() ?? -1;
        var result = await _service.DeleteAsync(workflowDefinitionId, stepId, userId, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<object>(new { }));
    }
}
