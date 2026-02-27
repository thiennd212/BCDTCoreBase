namespace BCDT.Application.DTOs.Workflow;

public class BulkApproveResultDto
{
    public List<int> SucceededIds { get; set; } = new();
    public List<BulkApproveFailureItem> Failed { get; set; } = new();
}

public class BulkApproveFailureItem
{
    public int WorkflowInstanceId { get; set; }
    public string Code { get; set; } = "";
    public string Message { get; set; } = "";
}
