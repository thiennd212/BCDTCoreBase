namespace BCDT.Domain.Entities.Authorization;

/// <summary>Menu hệ thống (BCDT_Menu). Hỗ trợ cây phân cấp qua ParentId.</summary>
public class Menu
{
    public int Id { get; set; }
    /// <summary>Mã menu (unique)</summary>
    public string Code { get; set; } = string.Empty;
    /// <summary>Tên hiển thị</summary>
    public string Name { get; set; } = string.Empty;
    /// <summary>Id menu cha (null nếu root)</summary>
    public int? ParentId { get; set; }
    /// <summary>URL điều hướng</summary>
    public string? Url { get; set; }
    /// <summary>Icon (Ant Design icon name)</summary>
    public string? Icon { get; set; }
    /// <summary>Thứ tự hiển thị</summary>
    public int DisplayOrder { get; set; }
    /// <summary>Hiển thị trong menu</summary>
    public bool IsVisible { get; set; } = true;
    /// <summary>Mã quyền cần thiết để xem menu</summary>
    public string? RequiredPermission { get; set; }
    /// <summary>Ngày tạo</summary>
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    // Navigation
    public Menu? Parent { get; set; }
    public ICollection<Menu> Children { get; set; } = new List<Menu>();
}
