namespace BCDT.Application.DTOs.Form;

public class CreateIndicatorCatalogRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string? Description { get; set; }
    public string Scope { get; set; } = "Global";
    public int DisplayOrder { get; set; }
    public bool IsActive { get; set; } = true;
}
