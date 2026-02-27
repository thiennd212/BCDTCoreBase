namespace BCDT.Domain.Entities.Form;

/// <summary>Biểu mẫu (BCDT_FormDefinition). FormType: Input, Aggregate. Status: Draft, Published, Archived.</summary>
public class FormDefinition
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string FormType { get; set; } = "Input";
    public int CurrentVersion { get; set; } = 1;
    public int? ReportingFrequencyId { get; set; }
    public int DeadlineOffsetDays { get; set; } = 5;
    public bool AllowLateSubmission { get; set; } = true;
    public bool RequireApproval { get; set; } = true;
    public bool AutoCreateReport { get; set; }
    public byte[]? TemplateFile { get; set; }
    public string? TemplateFileName { get; set; }
    /// <summary>JSON template đã parse (Fortune-sheet format) dùng làm base hiển thị nhập liệu.</summary>
    public string? TemplateDisplayJson { get; set; }
    public string Status { get; set; } = "Draft";
    public DateTime? PublishedAt { get; set; }
    public int? PublishedBy { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
    public bool IsDeleted { get; set; }
}
