namespace BCDT.Domain.Entities.Authorization;

/// <summary>Quyền (BCDT_Permission). Mỗi quyền thuộc một module, có mã duy nhất.</summary>
public class Permission
{
    public int Id { get; set; }
    /// <summary>Mã quyền (unique), vd: FORM_VIEW, FORM_CREATE, USER_MANAGE</summary>
    public string Code { get; set; } = string.Empty;
    /// <summary>Tên hiển thị</summary>
    public string Name { get; set; } = string.Empty;
    /// <summary>Module (nhóm quyền), vd: Form, User, Organization, Report</summary>
    public string Module { get; set; } = string.Empty;
    /// <summary>Action (hành động), vd: View, Create, Update, Delete</summary>
    public string Action { get; set; } = string.Empty;
    /// <summary>Mô tả chi tiết</summary>
    public string? Description { get; set; }
    /// <summary>Trạng thái hoạt động</summary>
    public bool IsActive { get; set; } = true;
}
