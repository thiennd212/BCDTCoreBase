namespace BCDT.Domain.Entities.Form;

/// <summary>Phiên bản biểu mẫu (BCDT_FormVersion). Dùng cho list versions theo form.</summary>
public class FormVersion
{
    public int Id { get; set; }
    public int FormDefinitionId { get; set; }
    public int VersionNumber { get; set; }
    public string? VersionName { get; set; }
    public string? ChangeDescription { get; set; }
    public byte[]? TemplateFile { get; set; }
    public string? TemplateFileName { get; set; }
    public string? StructureJson { get; set; }
    public bool IsActive { get; set; } = true;
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
