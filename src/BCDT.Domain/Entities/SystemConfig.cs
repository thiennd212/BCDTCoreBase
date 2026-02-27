namespace BCDT.Domain.Entities;

/// <summary>Cấu hình hệ thống (BCDT_SystemConfig)</summary>
public class SystemConfig
{
    public int Id { get; set; }
    public string ConfigKey { get; set; } = string.Empty;
    public string ConfigValue { get; set; } = string.Empty;
    public string DataType { get; set; } = "String";
    public string? Description { get; set; }
    public bool IsEncrypted { get; set; }
    public DateTime UpdatedAt { get; set; }
    public int? UpdatedBy { get; set; }
}
