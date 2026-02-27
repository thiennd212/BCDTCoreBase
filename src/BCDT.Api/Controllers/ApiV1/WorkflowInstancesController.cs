using System.Security.Claims;
using BCDT.Api.Common;
using BCDT.Application.DTOs.Workflow;
using BCDT.Application.Services.Workflow;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace BCDT.Api.Controllers.ApiV1;

[ApiController]
[Route("api/v1/workflow-instances")]
[Authorize]
[Produces("application/json")]
public class WorkflowInstancesController : ControllerBase
{
    private readonly IWorkflowExecutionService _service;

    public WorkflowInstancesController(IWorkflowExecutionService service) => _service = service;

    private static int GetApproverId(ClaimsPrincipal user)
    {
        var v = user.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        return int.TryParse(v, out var id) ? id : -1;
    }

    /// <summary>Lấy lịch sử phê duyệt (timeline) của workflow instance.</summary>
    [HttpGet("{id:int}/approvals")]
    [ProducesResponseType(typeof(ApiSuccessResponse<List<WorkflowApprovalDto>>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    public async Task<IActionResult> GetApprovals(int id, CancellationToken cancellationToken = default)
    {
        var result = await _service.GetApprovalsByInstanceIdAsync(id, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<List<WorkflowApprovalDto>>(result.Data!));
    }

    [HttpPost("{id:int}/approve")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkflowInstanceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Approve(int id, [FromBody] WorkflowActionRequest? request, CancellationToken cancellationToken = default)
    {
        var approverId = GetApproverId(User);
        var result = await _service.ApproveAsync(id, approverId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<WorkflowInstanceDto>(result.Data!));
    }

    /// <summary>Duyệt hàng loạt workflow instance.</summary>
    [HttpPost("bulk-approve")]
    [ProducesResponseType(typeof(ApiSuccessResponse<BulkApproveResultDto>), StatusCodes.Status200OK)]
    public async Task<IActionResult> BulkApprove([FromBody] BulkApproveRequest request, CancellationToken cancellationToken = default)
    {
        var approverId = GetApproverId(User);
        var actionRequest = request?.Comments != null ? new WorkflowActionRequest { Comments = request.Comments } : null;
        var result = await _service.BulkApproveAsync(request?.WorkflowInstanceIds ?? new List<int>(), approverId, actionRequest, cancellationToken);
        if (!result.IsSuccess)
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        return Ok(new ApiSuccessResponse<BulkApproveResultDto>(result.Data!));
    }

    [HttpPost("{id:int}/reject")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkflowInstanceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> Reject(int id, [FromBody] WorkflowActionRequest? request, CancellationToken cancellationToken = default)
    {
        var approverId = GetApproverId(User);
        var result = await _service.RejectAsync(id, approverId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<WorkflowInstanceDto>(result.Data!));
    }

    [HttpPost("{id:int}/request-revision")]
    [ProducesResponseType(typeof(ApiSuccessResponse<WorkflowInstanceDto>), StatusCodes.Status200OK)]
    [ProducesResponseType(StatusCodes.Status404NotFound)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> RequestRevision(int id, [FromBody] WorkflowActionRequest? request, CancellationToken cancellationToken = default)
    {
        var approverId = GetApproverId(User);
        var result = await _service.RequestRevisionAsync(id, approverId, request, cancellationToken);
        if (!result.IsSuccess)
        {
            if (result.Code == "NOT_FOUND") return NotFound(new ApiErrorResponse(result.Code, result.Message));
            return BadRequest(new ApiErrorResponse(result.Code, result.Message));
        }
        return Ok(new ApiSuccessResponse<WorkflowInstanceDto>(result.Data!));
    }
}
