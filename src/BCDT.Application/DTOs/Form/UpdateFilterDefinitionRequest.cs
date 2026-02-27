namespace BCDT.Application.DTOs.Form;

public class UpdateFilterDefinitionRequest
{
    public string Name { get; set; } = string.Empty;
    public string LogicalOperator { get; set; } = "AND";
    public int? DataSourceId { get; set; }
    public List<UpdateFilterConditionItem> Conditions { get; set; } = new();
}

public class UpdateFilterConditionItem
{
    public int Id { get; set; } // 0 = new
    public int ConditionOrder { get; set; }
    public string Field { get; set; } = string.Empty;
    public string Operator { get; set; } = string.Empty;
    public string ValueType { get; set; } = "Literal";
    public string? Value { get; set; }
    public string? Value2 { get; set; }
    public string? DataType { get; set; }
}
