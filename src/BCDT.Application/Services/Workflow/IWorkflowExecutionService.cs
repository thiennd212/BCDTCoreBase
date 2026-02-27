using BCDT.Application.Common;
using BCDT.Application.DTOs.Workflow;

namespace BCDT.Application.Services.Workflow;

/// <summary>Submit submission (start workflow), Approve, Reject, RequestRevision.</summary>
public interface IWorkflowExecutionService
{
    Task<Result<WorkflowInstanceDto>> SubmitSubmissionAsync(long submissionId, int submittedBy, CancellationToken cancellationToken = default);
    Task<Result<WorkflowInstanceDto>> ApproveAsync(int workflowInstanceId, int approverId, WorkflowActionRequest? request, CancellationToken cancellationToken = default);
    Task<Result<BulkApproveResultDto>> BulkApproveAsync(IReadOnlyList<int> workflowInstanceIds, int approverId, WorkflowActionRequest? request, CancellationToken cancellationToken = default);
    Task<Result<WorkflowInstanceDto>> RejectAsync(int workflowInstanceId, int approverId, WorkflowActionRequest? request, CancellationToken cancellationToken = default);
    Task<Result<WorkflowInstanceDto>> RequestRevisionAsync(int workflowInstanceId, int approverId, WorkflowActionRequest? request, CancellationToken cancellationToken = default);
    Task<Result<WorkflowInstanceDto?>> GetInstanceBySubmissionIdAsync(long submissionId, CancellationToken cancellationToken = default);
    /// <summary>Lấy lịch sử phê duyệt theo workflow instance (để FE hiển thị timeline).</summary>
    Task<Result<List<WorkflowApprovalDto>>> GetApprovalsByInstanceIdAsync(int workflowInstanceId, CancellationToken cancellationToken = default);
}
