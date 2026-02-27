namespace BCDT.Application.DTOs.Data;

public class BulkCreateSubmissionsResultDto
{
    public List<long> CreatedIds { get; set; } = new();
    public int SkippedCount { get; set; }
    public List<BulkCreateErrorItem> Errors { get; set; } = new();
}

public class BulkCreateErrorItem
{
    public int OrganizationId { get; set; }
    public string Code { get; set; } = "";
    public string Message { get; set; } = "";
}
