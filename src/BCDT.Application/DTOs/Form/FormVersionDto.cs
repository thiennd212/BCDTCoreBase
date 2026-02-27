namespace BCDT.Application.DTOs.Form;

public class FormVersionDto
{
    public int Id { get; set; }
    public int FormDefinitionId { get; set; }
    public int VersionNumber { get; set; }
    public string? VersionName { get; set; }
    public string? ChangeDescription { get; set; }
    public bool IsActive { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
