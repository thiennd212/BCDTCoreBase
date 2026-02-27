namespace BCDT.Domain.Entities.Data;

/// <summary>Submission metadata (BCDT_ReportSubmission). Status: Draft, Submitted, Approved, Rejected, Revision.</summary>
public class ReportSubmission
{
    public long Id { get; set; }
    public int FormDefinitionId { get; set; }
    public int FormVersionId { get; set; }
    public int OrganizationId { get; set; }
    public int ReportingPeriodId { get; set; }

    public string Status { get; set; } = "Draft";
    public DateTime? SubmittedAt { get; set; }
    public int? SubmittedBy { get; set; }
    public DateTime? ApprovedAt { get; set; }
    public int? ApprovedBy { get; set; }

    public int? WorkflowInstanceId { get; set; }
    public int? CurrentWorkflowStep { get; set; }

    public bool IsLocked { get; set; }
    public int? LockedBy { get; set; }
    public DateTime? LockedAt { get; set; }
    public DateTime? LockExpiresAt { get; set; }

    public int Version { get; set; } = 1;
    public int RevisionNumber { get; set; }

    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsDeleted { get; set; }
}
