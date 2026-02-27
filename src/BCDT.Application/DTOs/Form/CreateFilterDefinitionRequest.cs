namespace BCDT.Application.DTOs.Form;

public class CreateFilterDefinitionRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public string LogicalOperator { get; set; } = "AND";
    public int? DataSourceId { get; set; }
    public List<CreateFilterConditionItem> Conditions { get; set; } = new();
}

public class CreateFilterConditionItem
{
    public int ConditionOrder { get; set; }
    public string Field { get; set; } = string.Empty;
    public string Operator { get; set; } = string.Empty;
    public string ValueType { get; set; } = "Literal";
    public string? Value { get; set; }
    public string? Value2 { get; set; }
    public string? DataType { get; set; }
}
