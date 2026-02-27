namespace BCDT.Application.DTOs.Form;

public class FormDefinitionDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string FormType { get; set; } = "Input";
    public int CurrentVersion { get; set; }
    public int? ReportingFrequencyId { get; set; }
    public string? ReportingFrequencyCode { get; set; }
    public int DeadlineOffsetDays { get; set; }
    public bool AllowLateSubmission { get; set; }
    public bool RequireApproval { get; set; }
    public bool AutoCreateReport { get; set; }
    public string? TemplateFileName { get; set; }
    /// <summary>True nếu đã upload template và có TemplateDisplayJson (dùng làm base hiển thị nhập liệu).</summary>
    public bool HasTemplateDisplay { get; set; }
    public string Status { get; set; } = "Draft";
    public DateTime? PublishedAt { get; set; }
    public int? PublishedBy { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
