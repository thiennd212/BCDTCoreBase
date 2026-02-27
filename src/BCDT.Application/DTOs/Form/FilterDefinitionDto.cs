namespace BCDT.Application.DTOs.Form;

public class FilterDefinitionDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string LogicalOperator { get; set; } = "AND";
    public int? DataSourceId { get; set; }
    public List<FilterConditionDto> Conditions { get; set; } = new();
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
