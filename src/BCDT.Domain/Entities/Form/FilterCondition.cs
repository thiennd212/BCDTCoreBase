namespace BCDT.Domain.Entities.Form;

/// <summary>Điều kiện con của bộ lọc (BCDT_FilterCondition). P8a.</summary>
public class FilterCondition
{
    public int Id { get; set; }
    public int FilterDefinitionId { get; set; }
    public int ConditionOrder { get; set; }
    public string Field { get; set; } = string.Empty;
    public string Operator { get; set; } = string.Empty; // Eq, Ne, Lt, Le, Gt, Ge, In, NotIn, ...
    public string ValueType { get; set; } = string.Empty; // Literal | Parameter
    public string? Value { get; set; }
    public string? Value2 { get; set; }
    public string? DataType { get; set; } // Text | Number | Date | Boolean
    public DateTime CreatedAt { get; set; }
    public int CreatedBy { get; set; }
}
