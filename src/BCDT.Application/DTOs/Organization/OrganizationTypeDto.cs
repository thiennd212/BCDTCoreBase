namespace BCDT.Application.DTOs.Organization;

public class OrganizationTypeDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int Level { get; set; }
    public int? ParentTypeId { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; }
    public int OrganizationCount { get; set; }
}

public class CreateOrganizationTypeRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int Level { get; set; }
    public int? ParentTypeId { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
}

public class UpdateOrganizationTypeRequest
{
    public string Name { get; set; } = string.Empty;
    public int Level { get; set; }
    public int? ParentTypeId { get; set; }
    public string? Description { get; set; }
    public bool IsActive { get; set; } = true;
}
