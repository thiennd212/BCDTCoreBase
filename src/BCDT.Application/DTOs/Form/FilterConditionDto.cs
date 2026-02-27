namespace BCDT.Application.DTOs.Form;

public class FilterConditionDto
{
    public int Id { get; set; }
    public int FilterDefinitionId { get; set; }
    public int ConditionOrder { get; set; }
    public string Field { get; set; } = string.Empty;
    public string Operator { get; set; } = string.Empty;
    public string ValueType { get; set; } = string.Empty;
    public string? Value { get; set; }
    public string? Value2 { get; set; }
    public string? DataType { get; set; }
}
