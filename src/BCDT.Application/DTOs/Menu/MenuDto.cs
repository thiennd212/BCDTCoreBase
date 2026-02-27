namespace BCDT.Application.DTOs.Menu;

/// <summary>DTO menu</summary>
public class MenuDto
{
    public int Id { get; set; }
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int? ParentId { get; set; }
    public string? ParentName { get; set; }
    public string? Url { get; set; }
    public string? Icon { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsVisible { get; set; }
    public string? RequiredPermission { get; set; }
    public DateTime CreatedAt { get; set; }
    /// <summary>Menu con (dùng cho tree)</summary>
    public List<MenuDto>? Children { get; set; }
}

/// <summary>Request tạo menu</summary>
public class CreateMenuRequest
{
    public string Code { get; set; } = string.Empty;
    public string Name { get; set; } = string.Empty;
    public int? ParentId { get; set; }
    public string? Url { get; set; }
    public string? Icon { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsVisible { get; set; } = true;
    public string? RequiredPermission { get; set; }
}

/// <summary>Request cập nhật menu</summary>
public class UpdateMenuRequest
{
    public string Name { get; set; } = string.Empty;
    public int? ParentId { get; set; }
    public string? Url { get; set; }
    public string? Icon { get; set; }
    public int DisplayOrder { get; set; }
    public bool IsVisible { get; set; } = true;
    public string? RequiredPermission { get; set; }
}
