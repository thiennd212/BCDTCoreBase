namespace BCDT.Domain.Entities.Form;

/// <summary>Định nghĩa bộ lọc (BCDT_FilterDefinition). P8a.</summary>
public class FilterDefinition
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string LogicalOperator { get; set; } = "AND"; // AND | OR
    public int? DataSourceId { get; set; }
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
    public DateTime? UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
