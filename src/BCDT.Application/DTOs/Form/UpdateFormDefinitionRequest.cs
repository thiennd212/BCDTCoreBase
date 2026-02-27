namespace BCDT.Application.DTOs.Form;

public class UpdateFormDefinitionRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string FormType { get; set; } = "Input";
    public int? ReportingFrequencyId { get; set; }
    public int DeadlineOffsetDays { get; set; } = 5;
    public bool AllowLateSubmission { get; set; } = true;
    public bool RequireApproval { get; set; } = true;
    public bool AutoCreateReport { get; set; }
    public string Status { get; set; } = "Draft";
    public bool IsActive { get; set; } = true;
}
